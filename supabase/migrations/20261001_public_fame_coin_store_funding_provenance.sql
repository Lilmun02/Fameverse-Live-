-- Public store purchases are paid currency and must enter the cash-backed
-- funding bucket. This keeps creator gift earnings funded while leaving
-- promo/QA coins zero-liability.

create or replace function public.finalize_fame_coin_store_purchase(
  p_user_id uuid,
  p_platform text,
  p_product_id text,
  p_transaction_id text,
  p_original_transaction_id text default null,
  p_environment text default null,
  p_app_account_token text default null,
  p_purchase_date timestamptz default null
)
returns table (
  wallet_balance bigint,
  credited_coins integer,
  already_completed boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_platform text := lower(coalesce(p_platform, ''));
  v_product public.fame_coin_store_products%rowtype;
  v_tx_id uuid;
  v_existing public.fame_coin_store_transactions%rowtype;
  v_balance bigint;
begin
  if p_user_id is null or p_transaction_id is null or btrim(p_transaction_id) = '' then
    raise exception 'invalid store purchase identity' using errcode = '22023';
  end if;

  select * into v_product
  from public.fame_coin_store_products product
  where product.platform = v_platform
    and product.product_id = p_product_id
    and product.active = true;

  if v_product.product_id is null then
    raise exception 'unknown or inactive store product' using errcode = '22023';
  end if;

  insert into public.fame_coin_store_transactions (
    user_id,
    platform,
    product_id,
    transaction_id,
    original_transaction_id,
    environment,
    app_account_token,
    coins,
    status,
    purchase_date
  ) values (
    p_user_id,
    v_platform,
    v_product.product_id,
    p_transaction_id,
    nullif(btrim(coalesce(p_original_transaction_id, '')), ''),
    nullif(btrim(coalesce(p_environment, '')), ''),
    nullif(btrim(coalesce(p_app_account_token, '')), ''),
    v_product.coins,
    'processing',
    p_purchase_date
  )
  on conflict (platform, transaction_id) do nothing
  returning id into v_tx_id;

  if v_tx_id is null then
    select * into v_existing
    from public.fame_coin_store_transactions tx
    where tx.platform = v_platform
      and tx.transaction_id = p_transaction_id;

    if v_existing.user_id <> p_user_id then
      raise exception 'store transaction belongs to another account' using errcode = '42501';
    end if;

    if v_existing.status <> 'completed' then
      raise exception 'store transaction is not complete' using errcode = '55000';
    end if;

    select wallet.balance into v_balance
    from public.beta_coin_wallets wallet
    where wallet.user_id = p_user_id;

    return query select coalesce(v_balance, 0), v_existing.coins, true;
    return;
  end if;

  -- Paid store coins are cash-backed. _credit_fame_coins atomically updates
  -- both the visible wallet and funding-provenance ledger under the same user
  -- advisory lock. The provider transaction ID is also the idempotency key.
  v_balance := public._credit_fame_coins(
    p_user_id,
    v_product.coins,
    0,
    'purchase',
    'store:' || v_platform || ':' || p_transaction_id
  );

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type
  ) values (
    p_user_id,
    v_product.coins,
    v_balance,
    'purchase'
  );

  update public.fame_coin_store_transactions
  set status = 'completed',
      completed_at = now()
  where id = v_tx_id;

  return query select v_balance, v_product.coins, false;
end;
$$;

revoke all on function public.finalize_fame_coin_store_purchase(
  uuid, text, text, text, text, text, text, timestamptz
) from public, anon, authenticated;
grant execute on function public.finalize_fame_coin_store_purchase(
  uuid, text, text, text, text, text, text, timestamptz
) to service_role;
