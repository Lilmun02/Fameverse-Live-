-- Keep the beta custom-gift UI and authoritative backend on one bounded quantity contract.
-- 100,000 covers large combo/load tests like 15,000 while preventing unbounded inserts.
alter table public.gift_events
  drop constraint if exists gift_events_quantity_check;

alter table public.gift_events
  add constraint gift_events_quantity_check
  check (quantity between 1 and 100000);

create or replace function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
begin
  if v_sender is null then raise exception 'authentication required'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then raise exception 'invalid gift quantity'; end if;

  v_unit_cost := case p_gift_id
    when 'welcome-to-fameverse' then 100
    when 'rose' then 1
    when 'heart' then 1
    when 'fire' then 1
    when 'star' then 1
    when 'crown' then 1
    else null
  end;

  if v_unit_cost is null then raise exception 'unknown gift'; end if;

  select host_user_id into v_recipient
  from public.live_rooms
  where id = p_room_id and status = 'live' and ended_at is null;

  if v_recipient is null then raise exception 'live room is not active'; end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;

  insert into public.gift_events (room_id, sender_user_id, recipient_user_id, gift_id, quantity, coins_spent)
  values (p_room_id, v_sender, v_recipient, p_gift_id, p_quantity, v_total);

  insert into public.gifter_stats (user_id, total_coins_sent, gift_count, level, updated_at)
  values (v_sender, v_total, p_quantity, public.compute_gifter_level(v_total), now())
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(public.gifter_stats.total_coins_sent + excluded.total_coins_sent),
    updated_at = now();

  return query
  select s.total_coins_sent, s.gift_count, s.level
  from public.gifter_stats s
  where s.user_id = v_sender;
end;
$$;

revoke all on function public.record_beta_gift(uuid, text, integer) from public;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;
