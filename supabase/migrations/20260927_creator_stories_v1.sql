begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'fameverse-stories',
  'fameverse-stories',
  true,
  52428800,
  array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can upload their own Fameverse stories" on storage.objects;
create policy "Users can upload their own Fameverse stories"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'fameverse-stories'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can update their own Fameverse stories" on storage.objects;
create policy "Users can update their own Fameverse stories"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'fameverse-stories'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'fameverse-stories'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Users can delete their own Fameverse stories" on storage.objects;
create policy "Users can delete their own Fameverse stories"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'fameverse-stories'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create table if not exists public.creator_stories (
  id uuid primary key default gen_random_uuid(),
  creator_user_id uuid not null references auth.users(id) on delete cascade,
  media_type text not null check (media_type in ('photo','video')),
  media_path text not null,
  caption text not null default '' check (char_length(caption) <= 160),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  deleted_at timestamptz,
  check (expires_at > created_at)
);

create index if not exists creator_stories_active_idx
  on public.creator_stories (creator_user_id, expires_at desc)
  where deleted_at is null;

create table if not exists public.creator_story_views (
  story_id uuid not null references public.creator_stories(id) on delete cascade,
  viewer_user_id uuid not null references auth.users(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_user_id)
);

create index if not exists creator_story_views_viewer_idx
  on public.creator_story_views (viewer_user_id, viewed_at desc);

alter table public.creator_stories enable row level security;
alter table public.creator_story_views enable row level security;
revoke all on public.creator_stories from anon, authenticated;
revoke all on public.creator_story_views from anon, authenticated;

create or replace function public.create_creator_story(
  p_media_type text,
  p_media_path text,
  p_caption text default ''
)
returns table (
  story_id uuid,
  media_type text,
  media_path text,
  caption text,
  created_at timestamptz,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_type text := lower(trim(coalesce(p_media_type, '')));
  v_path text := trim(coalesce(p_media_path, ''));
  v_caption text := trim(coalesce(p_caption, ''));
  v_story public.creator_stories%rowtype;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if v_type not in ('photo','video') then
    raise exception 'story media type must be photo or video' using errcode = '22023';
  end if;
  if v_path = '' or split_part(v_path, '/', 1) <> v_user::text then
    raise exception 'story media path must belong to creator' using errcode = '42501';
  end if;
  if char_length(v_caption) > 160 then
    raise exception 'story caption is too long' using errcode = '22023';
  end if;

  insert into public.creator_stories (
    creator_user_id, media_type, media_path, caption
  ) values (
    v_user, v_type, v_path, v_caption
  ) returning * into v_story;

  return query select v_story.id, v_story.media_type, v_story.media_path,
    v_story.caption, v_story.created_at, v_story.expires_at;
end;
$$;

create or replace function public.list_active_creator_stories()
returns table (
  story_id uuid,
  creator_user_id uuid,
  display_name text,
  username text,
  avatar_url text,
  media_type text,
  media_path text,
  caption text,
  created_at timestamptz,
  expires_at timestamptz,
  view_count bigint,
  viewed_by_me boolean,
  is_mine boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    story.id,
    story.creator_user_id,
    coalesce(nullif(profile.display_name, ''), profile.username, 'Fameverse Creator'),
    profile.username,
    profile.avatar_url,
    story.media_type,
    story.media_path,
    story.caption,
    story.created_at,
    story.expires_at,
    (select count(*)::bigint from public.creator_story_views view_row where view_row.story_id = story.id),
    exists (
      select 1 from public.creator_story_views view_row
      where view_row.story_id = story.id and view_row.viewer_user_id = auth.uid()
    ),
    story.creator_user_id = auth.uid()
  from public.creator_stories story
  left join public.profiles profile on profile.id = story.creator_user_id
  where story.deleted_at is null
    and story.expires_at > now()
  order by story.creator_user_id, story.created_at;
$$;

create or replace function public.record_creator_story_view(p_story_id uuid)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_creator uuid;
  v_count bigint;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select story.creator_user_id into v_creator
  from public.creator_stories story
  where story.id = p_story_id
    and story.deleted_at is null
    and story.expires_at > now();

  if v_creator is null then
    raise exception 'story unavailable' using errcode = 'P0002';
  end if;

  if v_creator <> v_user then
    insert into public.creator_story_views(story_id, viewer_user_id)
    values(p_story_id, v_user)
    on conflict (story_id, viewer_user_id) do update
      set viewed_at = least(public.creator_story_views.viewed_at, excluded.viewed_at);
  end if;

  select count(*)::bigint into v_count
  from public.creator_story_views view_row
  where view_row.story_id = p_story_id;

  return v_count;
end;
$$;

create or replace function public.delete_creator_story(p_story_id uuid)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_path text;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  update public.creator_stories
  set deleted_at = now()
  where id = p_story_id
    and creator_user_id = v_user
    and deleted_at is null
  returning media_path into v_path;

  if v_path is null then
    raise exception 'story unavailable or not owned by creator' using errcode = '42501';
  end if;

  return v_path;
end;
$$;

create or replace function public.get_my_active_story_summary()
returns table (
  active_story_count bigint,
  total_views bigint,
  newest_expires_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with active as (
    select story.id, story.expires_at
    from public.creator_stories story
    where story.creator_user_id = auth.uid()
      and story.deleted_at is null
      and story.expires_at > now()
  )
  select
    (select count(*)::bigint from active),
    (select count(*)::bigint from public.creator_story_views views where views.story_id in (select id from active)),
    (select max(expires_at) from active);
$$;

revoke all on function public.create_creator_story(text,text,text) from public;
revoke all on function public.list_active_creator_stories() from public;
revoke all on function public.record_creator_story_view(uuid) from public;
revoke all on function public.delete_creator_story(uuid) from public;
revoke all on function public.get_my_active_story_summary() from public;

grant execute on function public.create_creator_story(text,text,text) to authenticated;
grant execute on function public.list_active_creator_stories() to authenticated;
grant execute on function public.record_creator_story_view(uuid) to authenticated;
grant execute on function public.delete_creator_story(uuid) to authenticated;
grant execute on function public.get_my_active_story_summary() to authenticated;

comment on table public.creator_stories is
  'Fameverse Creator Stories V1. Active for 24 hours; UI must hide expired/deleted rows.';
comment on table public.creator_story_views is
  'Unique per-viewer Story views for creator view counts.';

commit;
