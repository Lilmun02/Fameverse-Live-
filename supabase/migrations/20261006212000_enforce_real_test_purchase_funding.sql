
alter table public.coin_recharge_orders
  add column if not exists environment text not null default 'live';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='coin_recharge_orders_environment_check'
  ) then
    alter table public.coin_recharge_orders
      add constraint coin_recharge_orders_environment_check
      check (environment in ('test','live'));
  end if;
end $$;

create or replace function public.set_creator_sandbox_payout_method(
  p_recipient_email text
)
returns table(
  provider text,
  live_recipient_email text,
  sandbox_recipient_email text,
  enabled boolean
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_user uuid:=auth.uid();
  v_email text:=lower(trim(coalesce(p_recipient_email,'')));
begin
  if v_user is null then
    raise exception 'authentication required' using errcode='42501';
  end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' then
    raise exception 'valid sandbox payout email required' using errcode='22023';
  end if;

  insert into public.creator_payout_methods(
    user_id,provider,recipient_email,sandbox_recipient_email,enabled,updated_at
  ) values (
    v_user,'paypal',v_email,v_email,true,now()
  )
  on conflict(user_id) do update set
    provider='paypal',
    sandbox_recipient_email=excluded.sandbox_recipient_email,
    enabled=true,
    updated_at=now();

  return query
  select
    m.provider,
    m.live_recipient_email,
    m.sandbox_recipient_email,
    m.enabled
  from public.creator_payout_methods m
  where m.user_id=v_user;
end;
$$;

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
returns table(
  wallet_balance bigint,
  credited_coins integer,
  already_completed boolean
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_platform text:=lower(coalesce(p_platform,''));
  v_environment text:=lower(trim(coalesce(p_environment,'')));
  v_product public.fame_coin_store_products%rowtype;
  v_tx_id uuid;
  v_existing public.fame_coin_store_transactions%rowtype;
  v_balance bigint;
  v_is_test boolean;
begin
  if p_user_id is null or p_transaction_id is null or btrim(p_transaction_id)='' then
    raise exception 'invalid store purchase identity' using errcode='22023';
  end if;

  if v_environment not in ('sandbox','production') then
    raise exception 'verified store environment required' using errcode='22023';
  end if;
  v_is_test:=v_environment='sandbox';

  select * into v_product
  from public.fame_coin_store_products product
  where product.platform=v_platform
    and product.product_id=p_product_id
    and product.active=true;
  if v_product.product_id is null then
    raise exception 'unknown or inactive store product' using errcode='22023';
  end if;

  insert into public.fame_coin_store_transactions(
    user_id,platform,product_id,transaction_id,original_transaction_id,
    environment,app_account_token,coins,status,purchase_date
  ) values (
    p_user_id,v_platform,v_product.product_id,p_transaction_id,
    nullif(btrim(coalesce(p_original_transaction_id,'')),''),
    p_environment,
    nullif(btrim(coalesce(p_app_account_token,'')),''),
    v_product.coins,'processing',p_purchase_date
  )
  on conflict(platform,transaction_id) do nothing
  returning id into v_tx_id;

  if v_tx_id is null then
    select * into v_existing
    from public.fame_coin_store_transactions tx
    where tx.platform=v_platform
      and tx.transaction_id=p_transaction_id;

    if v_existing.user_id<>p_user_id then
      raise exception 'store transaction belongs to another account' using errcode='42501';
    end if;
    if v_existing.status<>'completed' then
      raise exception 'store transaction is not complete' using errcode='55000';
    end if;

    select balance into v_balance
    from public.beta_coin_wallets
    where user_id=p_user_id;

    return query select coalesce(v_balance,0),v_existing.coins,true;
    return;
  end if;

  if v_is_test then
    v_balance:=public._credit_fame_coins(
      p_user_id,0,v_product.coins,'store_purchase_test',
      'store:'||v_platform||':'||p_transaction_id
    );
  else
    v_balance:=public._credit_fame_coins(
      p_user_id,v_product.coins,0,'store_purchase_real',
      'store:'||v_platform||':'||p_transaction_id
    );
  end if;

  insert into public.beta_coin_ledger(
    user_id,delta,balance_after,event_type
  ) values (
    p_user_id,v_product.coins,v_balance,
    case when v_is_test then 'store_purchase_test' else 'store_purchase_real' end
  );

  update public.fame_coin_store_transactions
  set status='completed',completed_at=now()
  where id=v_tx_id;

  return query select v_balance,v_product.coins,false;
end;
$$;

create or replace function public.finalize_coin_recharge(
  p_recharge_id uuid,
  p_provider_order_id text,
  p_provider_capture_id text,
  p_amount_cents integer,
  p_currency text
)
returns table(
  wallet_balance bigint,
  credited_coins integer,
  already_completed boolean
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_order public.coin_recharge_orders%rowtype;
  v_balance bigint;
  v_is_test boolean;
begin
  select * into v_order
  from public.coin_recharge_orders
  where id=p_recharge_id
  for update;

  if v_order.id is null then
    raise exception 'recharge order not found' using errcode='P0002';
  end if;

  if v_order.status='completed' then
    select balance into v_balance
    from public.beta_coin_wallets
    where user_id=v_order.user_id;
    return query select coalesce(v_balance,0),v_order.coins,true;
    return;
  end if;

  if v_order.status not in ('created','approved') then
    raise exception 'recharge order cannot be completed from current status'
      using errcode='22023';
  end if;

  if p_amount_cents<>v_order.amount_cents
     or upper(coalesce(p_currency,''))<>upper(v_order.currency) then
    raise exception 'captured payment does not match recharge order'
      using errcode='22023';
  end if;

  if exists(
    select 1
    from public.coin_recharge_orders other
    where other.provider_capture_id=p_provider_capture_id
      and other.id<>v_order.id
  ) then
    raise exception 'provider capture already used' using errcode='23505';
  end if;

  v_is_test:=lower(coalesce(v_order.environment,'live'))='test';

  if v_is_test then
    v_balance:=public._credit_fame_coins(
      v_order.user_id,0,v_order.coins,'recharge_test',
      'recharge:'||v_order.id::text
    );
  else
    v_balance:=public._credit_fame_coins(
      v_order.user_id,v_order.coins,0,'recharge_real',
      'recharge:'||v_order.id::text
    );
  end if;

  insert into public.beta_coin_ledger(
    user_id,delta,balance_after,event_type
  ) values (
    v_order.user_id,v_order.coins,v_balance,
    case when v_is_test then 'recharge_test' else 'recharge_real' end
  );

  update public.coin_recharge_orders
  set status='completed',
      provider_order_id=p_provider_order_id,
      provider_capture_id=p_provider_capture_id,
      completed_at=now(),
      updated_at=now()
  where id=v_order.id;

  return query select v_balance,v_order.coins,false;
end;
$$;

create or replace function public.mark_coin_recharge_refunded(
  p_recharge_id uuid,
  p_note text default null
)
returns text
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_order public.coin_recharge_orders%rowtype;
  v_balance bigint;
  v_cash bigint;
  v_promo bigint;
  v_is_test boolean;
begin
  select * into v_order
  from public.coin_recharge_orders
  where id=p_recharge_id
  for update;

  if v_order.id is null then
    raise exception 'recharge order not found' using errcode='P0002';
  end if;
  if v_order.status='refunded' then
    return 'refunded';
  end if;
  if v_order.status<>'completed' then
    raise exception 'only completed recharge orders can be refunded'
      using errcode='22023';
  end if;

  perform public._ensure_fame_coin_wallet(v_order.user_id);
  select cash_backed_coins,promo_coins
    into v_cash,v_promo
  from public.coin_funding_balances
  where user_id=v_order.user_id;

  v_is_test:=lower(coalesce(v_order.environment,'live'))='test';

  if (v_is_test and coalesce(v_promo,0)<v_order.coins)
     or (not v_is_test and coalesce(v_cash,0)<v_order.coins) then
    update public.coin_recharge_orders
    set status='refund_pending',
        risk_note=left(
          coalesce(
            p_note,
            'Purchased coins already spent from their original funding bucket; manual review required.'
          ),
          500
        ),
        updated_at=now()
    where id=v_order.id;
    return 'refund_pending';
  end if;

  if v_is_test then
    v_balance:=public._credit_fame_coins(
      v_order.user_id,0,-v_order.coins,'refund_test',
      'refund:'||v_order.id::text
    );
  else
    v_balance:=public._credit_fame_coins(
      v_order.user_id,-v_order.coins,0,'refund_real',
      'refund:'||v_order.id::text
    );
  end if;

  insert into public.beta_coin_ledger(
    user_id,delta,balance_after,event_type
  ) values (
    v_order.user_id,-v_order.coins,v_balance,
    case when v_is_test then 'refund_test' else 'refund_real' end
  );

  update public.coin_recharge_orders
  set status='refunded',
      refunded_at=now(),
      risk_note=left(nullif(trim(coalesce(p_note,'')),''),500),
      updated_at=now()
  where id=v_order.id;

  return 'refunded';
end;
$$;
