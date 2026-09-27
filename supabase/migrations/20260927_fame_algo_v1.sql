begin;

-- Fame Algo v1: server-authoritative ranking for creator discovery and Live.
-- The ranking deliberately mixes relationship, verified engagement, freshness,
-- and exploration. Follower counts and gifts are capped signals so Fameverse
-- does not become a pure rich-get-richer or pay-to-rank feed.

create index if not exists gift_events_sender_created_idx
  on public.gift_events(sender_user_id, created_at desc);
create index if not exists gift_events_room_created_idx
  on public.gift_events(room_id, created_at desc);
create index if not exists live_tap_batches_actor_created_idx
  on public.live_tap_batches(actor_user_id, created_at desc);
create index if not exists live_tap_batches_room_created_idx
  on public.live_tap_batches(room_id, created_at desc);
create index if not exists live_rooms_host_started_idx
  on public.live_rooms(host_user_id, started_at desc);

create or replace function public.get_recommended_creators_v3(
  p_exclude_user_id uuid,
  p_limit integer default 12
)
returns table (
  id uuid,
  username text,
  display_name text,
  bio text,
  avatar_url text,
  created_at timestamptz,
  follower_count bigint
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with
  viewer_following as (
    select f.following_id
    from public.follows f
    where f.follower_id = auth.uid()
  ),
  follower_counts as (
    select f.following_id as creator_id, count(*)::bigint as follower_count
    from public.follows f
    group by f.following_id
  ),
  mutual_counts as (
    select f2.following_id as creator_id,
           count(distinct f1.following_id)::bigint as mutual_count
    from public.follows f1
    join public.follows f2 on f2.follower_id = f1.following_id
    where f1.follower_id = auth.uid()
      and f2.following_id <> auth.uid()
    group by f2.following_id
  ),
  viewer_gifts as (
    select g.recipient_user_id as creator_id,
           coalesce(sum(g.coins_spent), 0)::bigint as gift_coins
    from public.gift_events g
    where g.sender_user_id = auth.uid()
      and g.created_at >= now() - interval '30 days'
    group by g.recipient_user_id
  ),
  viewer_taps as (
    select room.host_user_id as creator_id,
           coalesce(sum(batch.eligible_tap_count), 0)::bigint as eligible_taps
    from public.live_tap_batches batch
    join public.live_rooms room on room.id = batch.room_id
    where batch.actor_user_id = auth.uid()
      and batch.created_at >= now() - interval '30 days'
    group by room.host_user_id
  ),
  active_story as (
    select distinct story.creator_user_id
    from public.creator_stories story
    where story.deleted_at is null
      and story.expires_at > now()
  ),
  active_live as (
    select distinct room.host_user_id
    from public.live_rooms room
    where room.status = 'live'
      and room.ended_at is null
      and room.heartbeat_at >= now() - interval '45 seconds'
  ),
  scored as (
    select
      profile.id,
      profile.username,
      profile.display_name,
      profile.bio,
      profile.avatar_url,
      profile.created_at,
      coalesce(fc.follower_count, 0)::bigint as follower_count,
      (
        case when vf.following_id is null then 18 else 0 end
        + least(coalesce(mc.mutual_count, 0), 5) * 8
        + least(ln(1 + coalesce(fc.follower_count, 0)::numeric) * 5, 30)
        + least(ln(1 + coalesce(vg.gift_coins, 0)::numeric) * 8, 45)
        + least(ln(1 + coalesce(vt.eligible_taps, 0)::numeric) * 5, 35)
        + case when al.host_user_id is not null then 30 else 0 end
        + case when ast.creator_user_id is not null then 12 else 0 end
        + case when profile.created_at >= now() - interval '30 days' then 10 else 0 end
        + case when profile.updated_at >= now() - interval '14 days' then 4 else 0 end
      )::numeric as fame_score
    from public.profiles profile
    left join viewer_following vf on vf.following_id = profile.id
    left join follower_counts fc on fc.creator_id = profile.id
    left join mutual_counts mc on mc.creator_id = profile.id
    left join viewer_gifts vg on vg.creator_id = profile.id
    left join viewer_taps vt on vt.creator_id = profile.id
    left join active_story ast on ast.creator_user_id = profile.id
    left join active_live al on al.host_user_id = profile.id
    where profile.id <> coalesce(auth.uid(), p_exclude_user_id)
  )
  select
    scored.id,
    scored.username,
    scored.display_name,
    scored.bio,
    scored.avatar_url,
    scored.created_at,
    scored.follower_count
  from scored
  order by scored.fame_score desc,
           scored.follower_count asc,
           scored.created_at desc
  limit least(greatest(coalesce(p_limit, 12), 1), 40);
$$;

create or replace function public.get_active_live_rooms_v3(
  p_exclude_user_id uuid,
  p_heartbeat_cutoff timestamptz,
  p_limit integer default 100
)
returns table (
  room_id uuid,
  host_user_id uuid,
  title text,
  goal text,
  wishlist_gift_ids text[],
  heartbeat_at timestamptz,
  started_at timestamptz,
  fame_taps bigint,
  host_username text,
  host_display_name text,
  host_bio text,
  host_avatar_url text,
  host_created_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with
  viewer_following as (
    select f.following_id
    from public.follows f
    where f.follower_id = auth.uid()
  ),
  viewer_host_taps as (
    select historical.host_user_id,
           coalesce(sum(batch.eligible_tap_count), 0)::bigint as eligible_taps
    from public.live_tap_batches batch
    join public.live_rooms historical on historical.id = batch.room_id
    where batch.actor_user_id = auth.uid()
      and batch.created_at >= now() - interval '30 days'
    group by historical.host_user_id
  ),
  viewer_host_gifts as (
    select gift.recipient_user_id as host_user_id,
           coalesce(sum(gift.coins_spent), 0)::bigint as gift_coins
    from public.gift_events gift
    where gift.sender_user_id = auth.uid()
      and gift.created_at >= now() - interval '30 days'
    group by gift.recipient_user_id
  ),
  recent_room_engagers as (
    select batch.room_id,
           count(distinct batch.actor_user_id)::bigint as engager_count
    from public.live_tap_batches batch
    where batch.created_at >= now() - interval '15 minutes'
      and batch.eligible_tap_count > 0
    group by batch.room_id
  ),
  recent_room_gifts as (
    select gift.room_id,
           coalesce(sum(gift.coins_spent), 0)::bigint as gift_coins
    from public.gift_events gift
    where gift.created_at >= now() - interval '15 minutes'
    group by gift.room_id
  ),
  ranked as (
    select
      room.id as room_id,
      room.host_user_id,
      room.title,
      room.goal,
      room.wishlist_gift_ids,
      room.heartbeat_at,
      room.started_at,
      coalesce(taps.eligible_taps, 0)::bigint as fame_taps,
      profile.username as host_username,
      profile.display_name as host_display_name,
      profile.bio as host_bio,
      profile.avatar_url as host_avatar_url,
      profile.created_at as host_created_at,
      (
        case when vf.following_id is not null then 90 else 8 end
        + least(ln(1 + coalesce(vht.eligible_taps, 0)::numeric) * 5, 40)
        + least(ln(1 + coalesce(vhg.gift_coins, 0)::numeric) * 8, 50)
        + least(coalesce(rre.engager_count, 0), 8) * 4
        + least(ln(1 + coalesce(taps.eligible_taps, 0)::numeric) * 5, 35)
        + least(ln(1 + coalesce(rrg.gift_coins, 0)::numeric) * 4, 25)
        + greatest(
            0,
            25 - floor(extract(epoch from (now() - room.started_at)) / 300)
          )
        + case when profile.created_at >= now() - interval '30 days' then 10 else 0 end
      )::numeric as fame_score
    from public.live_rooms room
    left join public.profiles profile on profile.id = room.host_user_id
    left join public.live_tap_totals taps on taps.room_id = room.id
    left join viewer_following vf on vf.following_id = room.host_user_id
    left join viewer_host_taps vht on vht.host_user_id = room.host_user_id
    left join viewer_host_gifts vhg on vhg.host_user_id = room.host_user_id
    left join recent_room_engagers rre on rre.room_id = room.id
    left join recent_room_gifts rrg on rrg.room_id = room.id
    where room.status = 'live'
      and room.ended_at is null
      and room.heartbeat_at >= p_heartbeat_cutoff
      and room.host_user_id <> coalesce(auth.uid(), p_exclude_user_id)
  )
  select
    ranked.room_id,
    ranked.host_user_id,
    ranked.title,
    ranked.goal,
    ranked.wishlist_gift_ids,
    ranked.heartbeat_at,
    ranked.started_at,
    ranked.fame_taps,
    ranked.host_username,
    ranked.host_display_name,
    ranked.host_bio,
    ranked.host_avatar_url,
    ranked.host_created_at
  from ranked
  order by ranked.fame_score desc, ranked.started_at desc
  limit least(greatest(coalesce(p_limit, 100), 1), 200);
$$;

revoke all on function public.get_recommended_creators_v3(uuid,integer) from public;
revoke all on function public.get_active_live_rooms_v3(uuid,timestamptz,integer) from public;
grant execute on function public.get_recommended_creators_v3(uuid,integer) to authenticated;
grant execute on function public.get_active_live_rooms_v3(uuid,timestamptz,integer) to authenticated;

comment on function public.get_recommended_creators_v3(uuid,integer) is
  'Fame Algo v1 creator discovery: relationship + trusted engagement + freshness + exploration, with capped popularity and gift signals.';
comment on function public.get_active_live_rooms_v3(uuid,timestamptz,integer) is
  'Fame Algo v1 Live ranking: followed creators, viewer affinity, eligible taps, active engagers, freshness and capped gift momentum.';

commit;
