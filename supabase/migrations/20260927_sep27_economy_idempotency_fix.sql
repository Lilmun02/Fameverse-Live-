begin;

-- Replays must return the existing visible balance before applying a delta.
-- This protects PayPal capture retries, referral retries and Coin Exchange
-- retries from ever minting the same coins twice.
create or replace function public._credit_fame_coins(
  p_user_id uuid,
  p_cash_delta bigint,
  p_promo_delta bigint,
  p_event_type text,
  p_event_key text default null
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_total_delta bigint := coalesce(p_cash_delta, 0) + coalesce(p_promo_delta, 0);
  v_balance bigint;
  v_cash bigint;
  v_promo bigint;
  v_key text := nullif(trim(coalesce(p_event_key, '')), '');
begin
  if p_user_id is null then
    raise exception 'user required' using errcode = '22023';
  end if;
  if v_total_delta = 0 then
    raise exception 'coin delta required' using errcode = '22023';
  end if;

  perform public._ensure_fame_coin_wallet(p_user_id);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || p_user_id::text, 0));

  if v_key is not null and exists (
    select 1 from public.coin_funding_ledger ledger
    where ledger.event_key = v_key
      and ledger.user_id = p_user_id
  ) then
    select wallet.balance into v_balance
    from public.beta_coin_wallets wallet
    where wallet.user_id = p_user_id;
    return coalesce(v_balance, 0);
  end if;

  select cash_backed_coins, promo_coins
    into v_cash, v_promo
  from public.coin_funding_balances
  where user_id = p_user_id
  for update;

  if v_cash + coalesce(p_cash_delta, 0) < 0 or
     v_promo + coalesce(p_promo_delta, 0) < 0 then
    raise exception 'insufficient funded coin balance' using errcode = '22003';
  end if;

  update public.coin_funding_balances
  set cash_backed_coins = cash_backed_coins + coalesce(p_cash_delta, 0),
      promo_coins = promo_coins + coalesce(p_promo_delta, 0),
      updated_at = now()
  where user_id = p_user_id;

  update public.beta_coin_wallets
  set balance = balance + v_total_delta,
      updated_at = now()
  where user_id = p_user_id
  returning balance into v_balance;

  if v_balance < 0 then
    raise exception 'coin wallet would become negative' using errcode = '22003';
  end if;

  insert into public.coin_funding_ledger (
    user_id, cash_delta, promo_delta, total_balance_after, event_type, event_key
  ) values (
    p_user_id,
    coalesce(p_cash_delta, 0),
    coalesce(p_promo_delta, 0),
    v_balance,
    p_event_type,
    v_key
  );

  return v_balance;
end;
$$;

-- Referral rewards are not paid for a bare signup. The new account must have a
-- confirmed email, a completed public profile and at least one genuine
-- Fameverse interaction (a follow or an accepted Live tap batch).
create or replace function public.qualify_beta_referral(p_code text)
returns table (
  accepted boolean,
  referrer_reward_coins integer,
  referred_reward_coins integer,
  referred_balance bigint
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_code text := upper(trim(coalesce(p_code, '')));
  v_referrer uuid;
  v_balance bigint;
  v_referral_id uuid;
  v_display text;
  v_username text;
  v_email_confirmed timestamptz;
  v_has_activity boolean := false;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if length(v_code) < 4 then
    raise exception 'valid referral code required' using errcode = '22023';
  end if;

  select code.user_id into v_referrer
  from public.beta_referral_codes code
  join public.beta_program_members member on member.user_id = code.user_id
  where code.code = v_code
    and code.active = true
    and member.status in ('active', 'earned');

  if v_referrer is null then
    raise exception 'referral code unavailable' using errcode = 'P0002';
  end if;
  if v_referrer = v_user then
    raise exception 'self referral is not allowed' using errcode = '42501';
  end if;

  select user_row.email_confirmed_at
    into v_email_confirmed
  from auth.users user_row
  where user_row.id = v_user;

  if v_email_confirmed is null then
    raise exception 'verify your email before referral rewards unlock' using errcode = '42501';
  end if;

  select trim(coalesce(display_name, '')), trim(coalesce(username, ''))
    into v_display, v_username
  from public.profiles
  where id = v_user;

  if coalesce(v_display, '') = '' or coalesce(v_username, '') = '' then
    raise exception 'complete your Fameverse profile before referral rewards unlock' using errcode = '22023';
  end if;

  select (
    exists (
      select 1 from public.follows f
      where f.follower_id = v_user or f.following_id = v_user
    ) or exists (
      select 1 from public.live_tap_batches tap
      where tap.actor_user_id = v_user
        and coalesce(tap.eligible_tap_count, 0) > 0
    )
  ) into v_has_activity;

  if not v_has_activity then
    raise exception 'complete a Fameverse activity before referral rewards unlock' using errcode = '22023';
  end if;

  if exists (select 1 from public.beta_referrals where referred_user_id = v_user) then
    select coalesce(wallet.balance, 0) into v_balance
    from public.beta_coin_wallets wallet where wallet.user_id = v_user;
    return query select false, 100, 50, coalesce(v_balance, 0);
    return;
  end if;

  insert into public.beta_referrals (
    referrer_user_id, referred_user_id, referral_code,
    referrer_reward_coins, referred_reward_coins
  ) values (
    v_referrer, v_user, v_code, 100, 50
  ) returning id into v_referral_id;

  perform public._credit_fame_coins(
    v_referrer, 0, 100, 'beta_referral_reward',
    'beta-referrer:' || v_referral_id::text
  );
  v_balance := public._credit_fame_coins(
    v_user, 0, 50, 'beta_referral_welcome',
    'beta-referred:' || v_referral_id::text
  );

  return query select true, 100, 50, v_balance;
end;
$$;

revoke all on function public._credit_fame_coins(uuid,bigint,bigint,text,text) from public;
revoke all on function public.qualify_beta_referral(text) from public;
grant execute on function public.qualify_beta_referral(text) to authenticated;

commit;
