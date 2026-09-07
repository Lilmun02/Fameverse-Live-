create table if not exists public.beta_coin_wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance bigint not null default 10000 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.beta_coin_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  delta bigint not null,
  balance_after bigint not null check (balance_after >= 0),
  event_type text not null check (event_type in ('seed', 'refill', 'gift_send')),
  gift_event_id uuid references public.gift_events(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists beta_coin_ledger_user_created_idx
  on public.beta_coin_ledger(user_id, created_at desc);

alter table public.beta_coin_wallets enable row level security;
alter table public.beta_coin_ledger enable row level security;

drop policy if exists "users can read own beta wallet" on public.beta_coin_wallets;
create policy "users can read own beta wallet"
on public.beta_coin_wallets for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "users can read own beta coin ledger" on public.beta_coin_ledger;
create policy "users can read own beta coin ledger"
on public.beta_coin_ledger for select
to authenticated
using (auth.uid() = user_id);

insert into public.beta_coin_wallets (user_id, balance)
select id, 10000
from public.profiles
on conflict (user_id) do nothing;

insert into public.beta_coin_ledger (user_id, delta, balance_after, event_type)
select wallet.user_id, wallet.balance, wallet.balance, 'seed'
from public.beta_coin_wallets wallet
where not exists (
  select 1
  from public.beta_coin_ledger ledger
  where ledger.user_id = wallet.user_id
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), 'Fameverse User')
  )
  on conflict (id) do nothing;

  insert into public.beta_coin_wallets (user_id, balance)
  values (new.id, 10000)
  on conflict (user_id) do nothing;

  insert into public.beta_coin_ledger (user_id, delta, balance_after, event_type)
  select new.id, 10000, 10000, 'seed'
  where not exists (
    select 1 from public.beta_coin_ledger where user_id = new.id
  );

  return new;
end;
$$;

drop function if exists public.record_beta_gift(uuid, text, integer);

create function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sender uuid := auth.uid();
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
  v_balance bigint;
  v_gift_event_id uuid;
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  v_unit_cost := case p_gift_id
    when 'welcome-to-fameverse' then 100
    when 'rose' then 1
    when 'heart' then 1
    when 'fire' then 1
    when 'star' then 1
    when 'crown' then 1
    else null
  end;

  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  select host_user_id into v_recipient
  from public.live_rooms
  where id = p_room_id
    and status = 'live'
    and ended_at is null;

  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;

  insert into public.beta_coin_wallets (user_id, balance)
  values (v_sender, 10000)
  on conflict (user_id) do nothing;

  if found then
    insert into public.beta_coin_ledger (user_id, delta, balance_after, event_type)
    select v_sender, 10000, 10000, 'seed'
    where not exists (
      select 1 from public.beta_coin_ledger where user_id = v_sender
    );
  end if;

  select balance into v_balance
  from public.beta_coin_wallets
  where user_id = v_sender
  for update;

  if v_balance < v_total then
    raise exception 'insufficient beta coin balance' using errcode = 'P0001';
  end if;

  insert into public.gift_events (
    room_id,
    sender_user_id,
    recipient_user_id,
    gift_id,
    quantity,
    coins_spent
  )
  values (
    p_room_id,
    v_sender,
    v_recipient,
    p_gift_id,
    p_quantity,
    v_total
  )
  returning id into v_gift_event_id;

  update public.beta_coin_wallets
  set balance = balance - v_total,
      updated_at = now()
  where user_id = v_sender
  returning balance into v_balance;

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type,
    gift_event_id
  )
  values (
    v_sender,
    -v_total,
    v_balance,
    'gift_send',
    v_gift_event_id
  );

  insert into public.gifter_stats (
    user_id,
    total_coins_sent,
    gift_count,
    level,
    updated_at
  )
  values (
    v_sender,
    v_total,
    p_quantity,
    public.compute_gifter_level(v_total),
    now()
  )
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(public.gifter_stats.total_coins_sent + excluded.total_coins_sent),
    updated_at = now();

  return query
  select stats.total_coins_sent,
         stats.gift_count,
         stats.level,
         v_balance
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$$;

create or replace function public.refill_beta_wallet(p_amount integer default 10000)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_balance bigint;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_amount <> 10000 then
    raise exception 'beta refill amount must be 10000' using errcode = '22023';
  end if;

  insert into public.beta_coin_wallets (user_id, balance)
  values (v_user_id, 10000)
  on conflict (user_id) do nothing;

  if found then
    insert into public.beta_coin_ledger (user_id, delta, balance_after, event_type)
    select v_user_id, 10000, 10000, 'seed'
    where not exists (
      select 1 from public.beta_coin_ledger where user_id = v_user_id
    );
  else
    update public.beta_coin_wallets
    set balance = balance + p_amount,
        updated_at = now()
    where user_id = v_user_id
    returning balance into v_balance;

    insert into public.beta_coin_ledger (user_id, delta, balance_after, event_type)
    values (v_user_id, p_amount, v_balance, 'refill');
  end if;

  select balance into v_balance
  from public.beta_coin_wallets
  where user_id = v_user_id;

  return v_balance;
end;
$$;

revoke all privileges on table public.beta_coin_wallets from anon, authenticated;
revoke all privileges on table public.beta_coin_ledger from anon, authenticated;
revoke all privileges on table public.gift_events from anon, authenticated;
revoke all privileges on table public.gifter_stats from anon, authenticated;
revoke all privileges on table public.account_roles from anon, authenticated;

grant select on public.beta_coin_wallets to authenticated;
grant select on public.beta_coin_ledger to authenticated;
grant select on public.gift_events to authenticated;
grant select on public.gifter_stats to anon, authenticated;
grant select on public.account_roles to anon, authenticated;

revoke all on function public.record_beta_gift(uuid, text, integer) from public;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;
revoke all on function public.refill_beta_wallet(integer) from public;
grant execute on function public.refill_beta_wallet(integer) to authenticated;
