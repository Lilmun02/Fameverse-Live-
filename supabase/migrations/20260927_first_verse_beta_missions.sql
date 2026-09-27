begin;

create table if not exists public.beta_program_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'earned', 'revoked')),
  joined_at timestamptz not null default now(),
  badge_unlocked_at timestamptz,
  invited_by uuid references auth.users(id) on delete set null
);

create table if not exists public.beta_test_mission_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  mission_key text not null check (
    mission_key in (
      'complete_profile',
      'browse_home',
      'browse_discover',
      'open_public_profile',
      'follow_creator',
      'join_live',
      'send_comment',
      'view_story',
      'send_gift',
      'cohost_session'
    )
  ),
  completed_at timestamptz not null default now(),
  primary key (user_id, mission_key)
);

alter table public.beta_program_members enable row level security;
alter table public.beta_test_mission_progress enable row level security;

revoke all on public.beta_program_members from anon, authenticated;
revoke all on public.beta_test_mission_progress from anon, authenticated;

create or replace function public.get_beta_program_status()
returns table (
  enrolled boolean,
  member_status text,
  completed_required integer,
  required_total integer,
  completed_optional integer,
  badge_unlocked boolean,
  badge_unlocked_at timestamptz,
  completed_missions text[]
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_status text;
  v_badge_at timestamptz;
  v_completed text[] := array[]::text[];
  v_required text[] := array[
    'complete_profile',
    'browse_home',
    'browse_discover',
    'open_public_profile',
    'follow_creator',
    'join_live',
    'send_comment',
    'view_story'
  ]::text[];
  v_optional text[] := array['send_gift', 'cohost_session']::text[];
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select m.status, m.badge_unlocked_at
    into v_status, v_badge_at
  from public.beta_program_members m
  where m.user_id = v_user;

  if not found or v_status = 'revoked' then
    return query
    select false, null::text, 0, cardinality(v_required), 0, false,
      null::timestamptz, array[]::text[];
    return;
  end if;

  select coalesce(array_agg(p.mission_key order by p.mission_key), array[]::text[])
    into v_completed
  from public.beta_test_mission_progress p
  where p.user_id = v_user;

  return query
  select
    true,
    v_status,
    (
      select count(*)::integer
      from unnest(v_required) required_key
      where required_key = any(v_completed)
    ),
    cardinality(v_required),
    (
      select count(*)::integer
      from unnest(v_optional) optional_key
      where optional_key = any(v_completed)
    ),
    v_status = 'earned' and v_badge_at is not null,
    v_badge_at,
    v_completed;
end;
$$;

create or replace function public.record_beta_test_mission(p_mission_key text)
returns table (
  accepted boolean,
  completed_required integer,
  required_total integer,
  badge_unlocked boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_status text;
  v_key text := lower(trim(coalesce(p_mission_key, '')));
  v_required text[] := array[
    'complete_profile',
    'browse_home',
    'browse_discover',
    'open_public_profile',
    'follow_creator',
    'join_live',
    'send_comment',
    'view_story'
  ]::text[];
  v_allowed text[] := v_required || array['send_gift', 'cohost_session']::text[];
  v_count integer := 0;
  v_unlocked boolean := false;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not (v_key = any(v_allowed)) then
    raise exception 'unknown beta mission' using errcode = '22023';
  end if;

  select m.status into v_status
  from public.beta_program_members m
  where m.user_id = v_user
  for update;

  -- Calling this RPC from ordinary production UI is harmless. Only enrolled
  -- external testers may accumulate First Verse progress.
  if not found or v_status = 'revoked' then
    return query select false, 0, cardinality(v_required), false;
    return;
  end if;

  insert into public.beta_test_mission_progress (user_id, mission_key)
  values (v_user, v_key)
  on conflict (user_id, mission_key) do nothing;

  select count(*)::integer into v_count
  from public.beta_test_mission_progress p
  where p.user_id = v_user
    and p.mission_key = any(v_required);

  if v_count >= cardinality(v_required) then
    update public.beta_program_members
    set status = 'earned',
        badge_unlocked_at = coalesce(badge_unlocked_at, now())
    where user_id = v_user
      and status <> 'revoked';
    v_unlocked := true;
  else
    v_unlocked := v_status = 'earned';
  end if;

  return query select true, v_count, cardinality(v_required), v_unlocked;
end;
$$;

create or replace function public.enroll_beta_tester(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_role text;
begin
  if v_actor is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select r.role into v_role
  from public.account_roles r
  where r.user_id = v_actor;

  if coalesce(v_role, '') not in ('owner', 'admin') then
    raise exception 'owner or admin required' using errcode = '42501';
  end if;

  if p_user_id is null then
    raise exception 'tester user id required' using errcode = '22023';
  end if;

  insert into public.beta_program_members (user_id, status, invited_by)
  values (p_user_id, 'active', v_actor)
  on conflict (user_id) do update
    set status = case
      when public.beta_program_members.status = 'earned' then 'earned'
      else 'active'
    end,
    invited_by = excluded.invited_by;

  return true;
end;
$$;

revoke all on function public.get_beta_program_status() from public;
revoke all on function public.record_beta_test_mission(text) from public;
revoke all on function public.enroll_beta_tester(uuid) from public;

grant execute on function public.get_beta_program_status() to authenticated;
grant execute on function public.record_beta_test_mission(text) to authenticated;
grant execute on function public.enroll_beta_tester(uuid) to authenticated;

comment on table public.beta_program_members is
  'External Fameverse beta-test enrollment and permanent First Verse unlock state.';
comment on table public.beta_test_mission_progress is
  'Idempotent external-beta mission completion; payout/owner-money QA is intentionally excluded.';

commit;
