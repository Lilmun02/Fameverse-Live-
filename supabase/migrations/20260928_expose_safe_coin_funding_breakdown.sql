create or replace function public.get_my_coin_funding_breakdown()
returns table(
  cash_backed_coins bigint,
  promo_coins bigint,
  total_balance bigint
)
language plpgsql
volatile
security definer
set search_path = 'public', 'pg_temp'
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  perform public._ensure_fame_coin_wallet(v_user);

  return query
  select
    f.cash_backed_coins,
    f.promo_coins,
    w.balance
  from public.coin_funding_balances f
  join public.beta_coin_wallets w on w.user_id = f.user_id
  where f.user_id = v_user;
end;
$$;

revoke all on function public.get_my_coin_funding_breakdown() from public, anon;
grant execute on function public.get_my_coin_funding_breakdown() to authenticated;
