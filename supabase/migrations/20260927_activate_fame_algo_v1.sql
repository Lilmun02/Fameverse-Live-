begin;

-- Preserve the native client RPC contract while activating Fame Algo v1.
-- Existing builds calling the v2 RPC names now receive the new personalized
-- rankings without requiring another client-side migration.
create or replace function public.get_recommended_creators_v2(
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
  select *
  from public.get_recommended_creators_v3(p_exclude_user_id, p_limit);
$$;

create or replace function public.get_active_live_rooms_v2(
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
  select *
  from public.get_active_live_rooms_v3(
    p_exclude_user_id,
    p_heartbeat_cutoff,
    p_limit
  );
$$;

revoke all on function public.get_recommended_creators_v2(uuid,integer) from public;
revoke all on function public.get_active_live_rooms_v2(uuid,timestamptz,integer) from public;
grant execute on function public.get_recommended_creators_v2(uuid,integer) to authenticated;
grant execute on function public.get_active_live_rooms_v2(uuid,timestamptz,integer) to authenticated;

comment on function public.get_recommended_creators_v2(uuid,integer) is
  'Compatibility alias. Fame Algo v1 is authoritative through get_recommended_creators_v3.';
comment on function public.get_active_live_rooms_v2(uuid,timestamptz,integer) is
  'Compatibility alias. Fame Algo v1 is authoritative through get_active_live_rooms_v3.';

commit;
