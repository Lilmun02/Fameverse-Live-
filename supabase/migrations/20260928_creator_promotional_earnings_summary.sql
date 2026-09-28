create or replace function public.get_creator_promotional_earnings_summary()
returns table(
  promo_gross_coins bigint,
  promo_equivalent_cents bigint,
  creator_promo_equivalent_cents bigint
)
language plpgsql
stable
security definer
set search_path = 'public', 'pg_temp'
as $$
declare
  v_user uuid := auth.uid();
  v_creator_bps integer;
  v_promo_coins bigint;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select creator_share_bps into v_creator_bps
  from public.fameverse_economy_config
  where id = true;

  select coalesce(sum(b.promo_coins), 0)::bigint into v_promo_coins
  from public.gift_events g
  join public.gift_funding_breakdowns b on b.gift_event_id = g.id
  where g.recipient_user_id = v_user;

  return query
  select
    v_promo_coins,
    v_promo_coins,
    ((v_promo_coins * coalesce(v_creator_bps, 7000)) / 10000)::bigint;
end;
$$;

revoke all on function public.get_creator_promotional_earnings_summary() from public, anon;
grant execute on function public.get_creator_promotional_earnings_summary() to authenticated;

comment on function public.get_creator_promotional_earnings_summary() is
'Creator-visible QA/promo gift value. Promotional earnings are non-withdrawable and never enter creator_earnings_ledger.';
