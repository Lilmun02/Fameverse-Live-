alter table public.coin_recharge_orders
  add column if not exists stripe_environment text;

create index if not exists coin_recharge_orders_stripe_pending_idx
  on public.coin_recharge_orders(user_id, pack_id, stripe_environment, created_at desc)
  where provider = 'stripe' and status = 'created';

create or replace function public.create_stripe_recharge_order(
  p_user_id uuid,
  p_pack_id text,
  p_environment text,
  p_amount_cents integer,
  p_currency text,
  p_coins integer
)
returns table (
  recharge_id uuid,
  provider_order_id text,
  reused boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_existing public.coin_recharge_orders%rowtype;
  v_order public.coin_recharge_orders%rowtype;
begin
  if p_user_id is null
     or p_pack_id is null
     or p_environment not in ('test', 'live')
     or p_amount_cents is null
     or p_amount_cents < 1
     or p_coins is null
     or p_coins < 1
     or p_currency is null
     or p_currency !~ '^[A-Z]{3}$' then
    raise exception 'invalid stripe recharge order input' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'fv-stripe-checkout:' || p_user_id::text || ':' || p_pack_id || ':' || p_environment,
      0
    )
  );

  if exists (
    select 1
    from public.coin_recharge_orders
    where user_id = p_user_id
      and pack_id = p_pack_id
      and provider = 'stripe'
      and status = 'created'
      and stripe_environment is null
  ) then
    raise exception 'legacy stripe order environment unresolved' using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.coin_recharge_orders
  where user_id = p_user_id
    and pack_id = p_pack_id
    and provider = 'stripe'
    and status = 'created'
    and stripe_environment = p_environment
    and amount_cents = p_amount_cents
    and currency = p_currency
    and coins = p_coins
  order by created_at desc
  limit 1;

  if v_existing.id is not null then
    return query select v_existing.id, v_existing.provider_order_id, true;
    return;
  end if;

  insert into public.coin_recharge_orders (
    user_id,
    pack_id,
    provider,
    stripe_environment,
    amount_cents,
    currency,
    coins,
    status
  ) values (
    p_user_id,
    p_pack_id,
    'stripe',
    p_environment,
    p_amount_cents,
    p_currency,
    p_coins,
    'created'
  )
  returning * into v_order;

  return query select v_order.id, v_order.provider_order_id, false;
end;
$$;

revoke all on function public.create_stripe_recharge_order(uuid, text, text, integer, text, integer) from public, anon, authenticated;
grant execute on function public.create_stripe_recharge_order(uuid, text, text, integer, text, integer) to service_role;
