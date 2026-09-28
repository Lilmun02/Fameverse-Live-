create or replace function public.get_owner_finance_control_summary()
returns table(
  reward_reserve_cents bigint,
  reward_reserve_lifetime_cents bigint,
  cash_backed_coins_outstanding bigint,
  cash_backed_value_outstanding_cents bigint,
  creator_earnings_unpaid_cents bigint,
  creator_payouts_in_review_cents bigint,
  cash_backed_gifts_gross_cents bigint,
  platform_share_earned_cents bigint,
  creator_share_earned_cents bigint,
  coins_per_usd integer,
  creator_share_bps integer,
  platform_share_bps integer
)
language plpgsql
stable
security definer
set search_path = 'public', 'pg_temp'
as $$
declare
  v_coins_per_usd integer;
  v_creator_share_bps integer;
  v_platform_share_bps integer;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = auth.uid() and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  select cfg.coins_per_usd, cfg.creator_share_bps, cfg.platform_share_bps
    into v_coins_per_usd, v_creator_share_bps, v_platform_share_bps
  from public.fameverse_economy_config cfg
  where cfg.id = true;

  return query
  with funding as (
    select coalesce(sum(f.cash_backed_coins), 0)::bigint as coins
    from public.coin_funding_balances f
  ),
  earnings as (
    select coalesce(sum(e.amount_cents) filter (
      where e.state not in ('paid', 'void', 'reversed', 'cancelled')
    ), 0)::bigint as unpaid
    from public.creator_earnings_ledger e
  ),
  payouts as (
    select coalesce(sum(p.amount_cents) filter (
      where p.status not in ('paid', 'rejected', 'cancelled', 'failed')
    ), 0)::bigint as in_review
    from public.creator_payout_requests p
  ),
  gifts as (
    select
      coalesce(sum(g.cash_backed_coins), 0)::bigint as cash_coins,
      coalesce(sum(g.creator_earning_micros), 0)::bigint as creator_micros
    from public.gift_funding_breakdowns g
  )
  select
    reserve.available_gross_cents,
    reserve.lifetime_allocated_gross_cents,
    funding.coins,
    case when v_coins_per_usd > 0
      then ((funding.coins * 100) + v_coins_per_usd - 1) / v_coins_per_usd
      else 0 end,
    earnings.unpaid,
    payouts.in_review,
    case when v_coins_per_usd > 0
      then (gifts.cash_coins * 100) / v_coins_per_usd
      else 0 end,
    case when v_coins_per_usd > 0
      then ((gifts.cash_coins * 100) / v_coins_per_usd) - (gifts.creator_micros / 10000)
      else 0 end,
    gifts.creator_micros / 10000,
    v_coins_per_usd,
    v_creator_share_bps,
    v_platform_share_bps
  from public.cash_reward_reserve reserve
  cross join funding
  cross join earnings
  cross join payouts
  cross join gifts
  where reserve.id = true;
end;
$$;

revoke all on function public.get_owner_finance_control_summary() from public, anon;
grant execute on function public.get_owner_finance_control_summary() to authenticated;
