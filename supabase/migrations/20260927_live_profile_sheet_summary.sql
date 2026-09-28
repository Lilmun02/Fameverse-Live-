begin;

create or replace function public.get_live_profile_sheet_summary(p_target_user_id uuid)
returns table (
  user_id uuid,
  username text,
  display_name text,
  bio text,
  avatar_url text,
  followers_count bigint,
  following_count bigint,
  friends_count bigint,
  fame_taps bigint,
  total_coins_sent bigint,
  gift_count bigint,
  gifter_level integer,
  viewer_follows boolean,
  target_follows_viewer boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_viewer uuid := auth.uid();
begin
  if v_viewer is null then
    raise exception 'Authentication required';
  end if;

  return query
  with target_profile as (
    select p.id, p.username, p.display_name, p.bio, p.avatar_url
    from public.profiles p
    where p.id = p_target_user_id
  ),
  social as (
    select
      (select count(*) from public.follows f where f.following_id = p_target_user_id)::bigint as followers_count,
      (select count(*) from public.follows f where f.follower_id = p_target_user_id)::bigint as following_count,
      (
        select count(*)
        from public.follows a
        where a.follower_id = p_target_user_id
          and exists (
            select 1
            from public.follows b
            where b.follower_id = a.following_id
              and b.following_id = p_target_user_id
          )
      )::bigint as friends_count,
      exists (
        select 1 from public.follows f
        where f.follower_id = v_viewer and f.following_id = p_target_user_id
      ) as viewer_follows,
      exists (
        select 1 from public.follows f
        where f.follower_id = p_target_user_id and f.following_id = v_viewer
      ) as target_follows_viewer
  ),
  tap_stats as (
    select coalesce(sum(b.eligible_tap_count), 0)::bigint as fame_taps
    from public.live_tap_batches b
    where b.actor_user_id = p_target_user_id
      and b.classification <> 'rejected'
  ),
  gift_stats as (
    select
      coalesce(gs.total_coins_sent, 0)::bigint as total_coins_sent,
      coalesce(gs.gift_count, 0)::bigint as gift_count,
      coalesce(gs.level, 1)::integer as gifter_level
    from (select 1) seed
    left join public.gifter_stats gs on gs.user_id = p_target_user_id
  )
  select
    tp.id,
    tp.username,
    coalesce(nullif(btrim(tp.display_name), ''), 'Fameverse User')::text,
    coalesce(tp.bio, '')::text,
    tp.avatar_url,
    s.followers_count,
    s.following_count,
    s.friends_count,
    t.fame_taps,
    g.total_coins_sent,
    g.gift_count,
    g.gifter_level,
    s.viewer_follows,
    s.target_follows_viewer
  from target_profile tp
  cross join social s
  cross join tap_stats t
  cross join gift_stats g;
end;
$$;

revoke all on function public.get_live_profile_sheet_summary(uuid) from public;
grant execute on function public.get_live_profile_sheet_summary(uuid) to authenticated;

comment on function public.get_live_profile_sheet_summary(uuid) is
  'Authenticated Live profile-card summary: public identity, social counts, eligible FameTaps, gift stats and viewer relationship. No private roles, email, payout or owner data.';

commit;
