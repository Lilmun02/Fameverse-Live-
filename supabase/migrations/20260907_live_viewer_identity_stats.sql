create or replace function public.get_live_viewer_identity_stats(
  p_room_id uuid default null,
  p_user_ids uuid[] default null
)
returns table (
  user_id uuid,
  username text,
  display_name text,
  avatar_url text,
  total_coins_sent bigint,
  gifter_level integer,
  room_gift_count bigint,
  room_fame_taps bigint,
  account_role text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_requester uuid := auth.uid();
  v_room_id uuid;
begin
  if v_requester is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_user_ids is null or cardinality(p_user_ids) = 0 then
    return;
  end if;

  if cardinality(p_user_ids) > 200 then
    raise exception 'viewer identity request too large' using errcode = '22023';
  end if;

  if p_room_id is null then
    select lr.id
      into v_room_id
    from public.live_rooms lr
    where lr.host_user_id = v_requester
      and lr.status = 'live'
      and lr.ended_at is null
    order by lr.heartbeat_at desc nulls last
    limit 1;
  else
    select lr.id
      into v_room_id
    from public.live_rooms lr
    where lr.id = p_room_id
      and lr.status = 'live'
      and lr.ended_at is null;
  end if;

  if v_room_id is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;

  return query
  with requested as (
    select distinct requested_id as user_id
    from unnest(p_user_ids) as requested_id
    where requested_id is not null
    limit 200
  ), gift_totals as (
    select ge.sender_user_id as user_id, coalesce(sum(ge.quantity), 0)::bigint as gift_count
    from public.gift_events ge
    where ge.room_id = v_room_id
      and ge.sender_user_id = any(p_user_ids)
    group by ge.sender_user_id
  ), tap_totals as (
    select b.actor_user_id as user_id, coalesce(sum(b.raw_tap_count), 0)::bigint as fame_taps
    from public.live_tap_batches b
    where b.room_id = v_room_id
      and b.actor_user_id = any(p_user_ids)
    group by b.actor_user_id
  )
  select
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    coalesce(gs.total_coins_sent, 0)::bigint,
    coalesce(gs.level, 1)::integer,
    coalesce(gt.gift_count, 0)::bigint,
    coalesce(tt.fame_taps, 0)::bigint,
    ar.role
  from requested r
  join public.profiles p on p.id = r.user_id
  left join public.gifter_stats gs on gs.user_id = p.id
  left join gift_totals gt on gt.user_id = p.id
  left join tap_totals tt on tt.user_id = p.id
  left join public.account_roles ar on ar.user_id = p.id
  order by coalesce(gt.gift_count, 0) desc, coalesce(tt.fame_taps, 0) desc, p.display_name asc nulls last;
end;
$$;

revoke all on function public.get_live_viewer_identity_stats(uuid, uuid[]) from public;
revoke all on function public.get_live_viewer_identity_stats(uuid, uuid[]) from anon;
grant execute on function public.get_live_viewer_identity_stats(uuid, uuid[]) to authenticated;
