begin;

-- Cover foreign keys the database linter identified. These are additive only;
-- no existing index is removed during the beta performance pass.
create index if not exists beta_coin_ledger_gift_event_idx
  on public.beta_coin_ledger(gift_event_id)
  where gift_event_id is not null;
create index if not exists cash_reward_reserve_updated_by_idx
  on public.cash_reward_reserve(updated_by)
  where updated_by is not null;
create index if not exists cash_reward_reserve_ledger_actor_idx
  on public.cash_reward_reserve_ledger(actor_user_id)
  where actor_user_id is not null;
create index if not exists cash_reward_reserve_ledger_gift_idx
  on public.cash_reward_reserve_ledger(gift_event_id)
  where gift_event_id is not null;
create index if not exists coin_recharge_orders_pack_idx
  on public.coin_recharge_orders(pack_id);
create index if not exists creator_payout_requests_reviewed_by_idx
  on public.creator_payout_requests(reviewed_by)
  where reviewed_by is not null;
create index if not exists creator_verification_reviewed_by_idx
  on public.creator_verification_requests(reviewed_by)
  where reviewed_by is not null;
create index if not exists fameverse_economy_config_updated_by_idx
  on public.fameverse_economy_config(updated_by)
  where updated_by is not null;
create index if not exists staff_cash_reward_permissions_updated_by_idx
  on public.staff_cash_reward_permissions(updated_by)
  where updated_by is not null;
create index if not exists follows_following_follower_idx
  on public.follows(following_id, follower_id);

-- High-frequency RLS policies use a scalar initplan for auth.uid() so Postgres
-- does not recompute it once per row while users browse Home/Discover/Live.
drop policy if exists "authenticated users can read follows" on public.follows;
create policy "authenticated users can read follows"
on public.follows for select to authenticated
using ((select auth.uid()) is not null);

drop policy if exists "users can follow as themselves" on public.follows;
create policy "users can follow as themselves"
on public.follows for insert to authenticated
with check (
  (select auth.uid()) = follower_id
  and follower_id <> following_id
);

drop policy if exists "users can unfollow as themselves" on public.follows;
create policy "users can unfollow as themselves"
on public.follows for delete to authenticated
using ((select auth.uid()) = follower_id);

drop policy if exists "users can read own beta wallet" on public.beta_coin_wallets;
create policy "users can read own beta wallet"
on public.beta_coin_wallets for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "users can read own beta coin ledger" on public.beta_coin_ledger;
create policy "users can read own beta coin ledger"
on public.beta_coin_ledger for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "users can read related beta gift events" on public.gift_events;
create policy "users can read related beta gift events"
on public.gift_events for select to authenticated
using (
  (select auth.uid()) = sender_user_id
  or (select auth.uid()) = recipient_user_id
);

drop policy if exists "creators can read own earnings" on public.creator_earnings_ledger;
create policy "creators can read own earnings"
on public.creator_earnings_ledger for select to authenticated
using (
  (select auth.uid()) = creator_user_id
  or exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = (select auth.uid())
      and role_row.role = 'owner'
  )
);

drop policy if exists "creators can read own payout requests" on public.creator_payout_requests;
create policy "creators can read own payout requests"
on public.creator_payout_requests for select to authenticated
using (
  (select auth.uid()) = creator_user_id
  or exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = (select auth.uid())
      and role_row.role = 'owner'
  )
);

drop policy if exists "creators can read own payout method" on public.creator_payout_methods;
create policy "creators can read own payout method"
on public.creator_payout_methods for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "creators can read own verification" on public.creator_verification_requests;
create policy "creators can read own verification"
on public.creator_verification_requests for select to authenticated
using (
  (select auth.uid()) = user_id
  or exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = (select auth.uid())
      and role_row.role = 'owner'
  )
);

drop policy if exists "creators can create own live draft" on public.creator_live_drafts;
create policy "creators can create own live draft"
on public.creator_live_drafts for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "creators can delete own live draft" on public.creator_live_drafts;
create policy "creators can delete own live draft"
on public.creator_live_drafts for delete to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "creators can read own live draft" on public.creator_live_drafts;
create policy "creators can read own live draft"
on public.creator_live_drafts for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "creators can update own live draft" on public.creator_live_drafts;
create policy "creators can update own live draft"
on public.creator_live_drafts for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- One round trip replaces downloading all follows + profile rows just to rank
-- twelve creator cards on device.
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
  select
    profile.id,
    profile.username,
    profile.display_name,
    profile.bio,
    profile.avatar_url,
    profile.created_at,
    count(follow_row.follower_id)::bigint as follower_count
  from public.profiles profile
  left join public.follows follow_row on follow_row.following_id = profile.id
  where profile.id <> p_exclude_user_id
  group by profile.id, profile.username, profile.display_name, profile.bio,
           profile.avatar_url, profile.created_at
  order by count(follow_row.follower_id) desc, profile.created_at desc
  limit least(greatest(coalesce(p_limit, 12), 1), 40);
$$;

-- One round trip replaces active rooms -> host profiles -> tap totals. The
-- heartbeat cutoff remains an explicit client input so the 45-second product
-- rule stays readable and testable.
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
  select
    room.id,
    room.host_user_id,
    room.title,
    room.goal,
    room.wishlist_gift_ids,
    room.heartbeat_at,
    room.started_at,
    coalesce(taps.raw_taps, 0)::bigint,
    profile.username,
    profile.display_name,
    profile.bio,
    profile.avatar_url,
    profile.created_at
  from public.live_rooms room
  left join public.profiles profile on profile.id = room.host_user_id
  left join public.live_tap_totals taps on taps.room_id = room.id
  where room.status = 'live'
    and room.ended_at is null
    and room.heartbeat_at >= p_heartbeat_cutoff
    and room.host_user_id <> p_exclude_user_id
  order by room.started_at desc
  limit least(greatest(coalesce(p_limit, 100), 1), 200);
$$;

revoke all on function public.get_recommended_creators_v2(uuid,integer) from public;
revoke all on function public.get_active_live_rooms_v2(uuid,timestamptz,integer) from public;
grant execute on function public.get_recommended_creators_v2(uuid,integer) to authenticated;
grant execute on function public.get_active_live_rooms_v2(uuid,timestamptz,integer) to authenticated;

commit;
