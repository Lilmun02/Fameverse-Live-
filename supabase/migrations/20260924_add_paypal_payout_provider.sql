-- Fameverse payout provider foundation: PayPal-first, provider-agnostic schema.
-- Product law: $25 minimum, Fameverse verification, cleared earnings, owner moderation.
-- Provider credentials never live in Flutter or database rows.

create table if not exists public.creator_payout_methods (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  provider text not null default 'paypal',
  recipient_email text not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint creator_payout_method_provider_check check (provider in ('paypal')),
  constraint creator_payout_method_email_length_check check (char_length(recipient_email) between 5 and 254)
);

alter table public.creator_payout_methods enable row level security;

drop policy if exists "creators can read own payout method" on public.creator_payout_methods;
create policy "creators can read own payout method"
on public.creator_payout_methods for select
to authenticated
using (auth.uid() = user_id);

revoke all privileges on table public.creator_payout_methods from anon, authenticated;
grant select on table public.creator_payout_methods to authenticated;

alter table public.creator_payout_requests
  add column if not exists payout_provider text,
  add column if not exists payout_recipient text,
  add column if not exists provider_batch_id text,
  add column if not exists provider_item_id text,
  add column if not exists provider_status text,
  add column if not exists provider_status_updated_at timestamptz;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'creator_payout_status_check'
      and conrelid = 'public.creator_payout_requests'::regclass
  ) then
    alter table public.creator_payout_requests drop constraint creator_payout_status_check;
  end if;
end $$;

alter table public.creator_payout_requests
  add constraint creator_payout_status_check
  check (status in ('pending_review', 'approved', 'processing', 'paid', 'rejected', 'cancelled', 'failed', 'held'));

create or replace function public.set_creator_payout_method(
  p_provider text,
  p_recipient_email text
)
returns table (
  provider text,
  recipient_email text,
  enabled boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_provider text := lower(trim(coalesce(p_provider, '')));
  v_email text := lower(trim(coalesce(p_recipient_email, '')));
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if v_provider <> 'paypal' then
    raise exception 'unsupported payout provider' using errcode = '22023';
  end if;

  if v_email !~ '^[A-Za-z0-9.!#$%&''*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$' then
    raise exception 'valid payout email required' using errcode = '22023';
  end if;

  insert into public.creator_payout_methods (
    user_id, provider, recipient_email, enabled, updated_at
  ) values (
    v_user, v_provider, v_email, true, now()
  )
  on conflict (user_id) do update set
    provider = excluded.provider,
    recipient_email = excluded.recipient_email,
    enabled = true,
    updated_at = now();

  return query
  select method.provider, method.recipient_email, method.enabled
  from public.creator_payout_methods method
  where method.user_id = v_user;
end;
$$;

create or replace function public.get_creator_payout_method()
returns table (
  provider text,
  recipient_email text,
  enabled boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  select method.provider, method.recipient_email, method.enabled
  from public.creator_payout_methods method
  where method.user_id = auth.uid();
$$;

create or replace function public.request_creator_payout(p_amount_cents bigint)
returns table (
  payout_id uuid,
  amount_cents bigint,
  status text,
  requested_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_verification text;
  v_available bigint;
  v_reserved bigint;
  v_provider text;
  v_recipient text;
  v_request public.creator_payout_requests%rowtype;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_amount_cents is null or p_amount_cents < 2500 then
    raise exception 'minimum payout is $25.00' using errcode = '22023';
  end if;

  select status into v_verification
  from public.creator_verification_requests
  where user_id = v_user;

  if coalesce(v_verification, 'unverified') <> 'verified' then
    raise exception 'creator verification required before payout' using errcode = '42501';
  end if;

  select method.provider, method.recipient_email
    into v_provider, v_recipient
  from public.creator_payout_methods method
  where method.user_id = v_user and method.enabled = true;

  if v_provider is null or v_recipient is null then
    raise exception 'active payout method required' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 2500));

  select coalesce(sum(amount_cents) filter (where state in ('available', 'paid', 'reversed')), 0)::bigint
    into v_available
  from public.creator_earnings_ledger
  where creator_user_id = v_user;

  select coalesce(sum(amount_cents) filter (where status in ('pending_review', 'approved', 'processing', 'held')), 0)::bigint
    into v_reserved
  from public.creator_payout_requests
  where creator_user_id = v_user;

  if p_amount_cents > greatest(v_available - v_reserved, 0) then
    raise exception 'insufficient cleared creator earnings' using errcode = '22003';
  end if;

  insert into public.creator_payout_requests (
    creator_user_id,
    amount_cents,
    payout_provider,
    payout_recipient
  ) values (
    v_user,
    p_amount_cents,
    v_provider,
    v_recipient
  )
  returning * into v_request;

  return query select v_request.id, v_request.amount_cents, v_request.status, v_request.requested_at;
end;
$$;

create or replace function public.begin_creator_payout_processing(p_payout_id uuid)
returns table (
  payout_id uuid,
  creator_user_id uuid,
  amount_cents bigint,
  payout_provider text,
  payout_recipient text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_request public.creator_payout_requests%rowtype;
begin
  if not exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  ) then
    raise exception 'owner moderation access required' using errcode = '42501';
  end if;

  select * into v_request
  from public.creator_payout_requests
  where id = p_payout_id
  for update;

  if v_request.id is null then
    raise exception 'payout request not found' using errcode = 'P0002';
  end if;

  if v_request.status <> 'approved' then
    raise exception 'payout must be approved before processing' using errcode = '22023';
  end if;

  if v_request.payout_provider is null or v_request.payout_recipient is null then
    raise exception 'payout method snapshot missing' using errcode = '22023';
  end if;

  update public.creator_payout_requests
  set status = 'processing',
      provider_status = 'SUBMITTING',
      provider_status_updated_at = now(),
      reviewed_at = coalesce(reviewed_at, now()),
      reviewed_by = coalesce(reviewed_by, auth.uid())
  where id = p_payout_id;

  return query
  select v_request.id, v_request.creator_user_id, v_request.amount_cents,
         v_request.payout_provider, v_request.payout_recipient;
end;
$$;

revoke all on function public.set_creator_payout_method(text, text) from public;
grant execute on function public.set_creator_payout_method(text, text) to authenticated;
revoke all on function public.get_creator_payout_method() from public;
grant execute on function public.get_creator_payout_method() to authenticated;
revoke all on function public.begin_creator_payout_processing(uuid) from public;
grant execute on function public.begin_creator_payout_processing(uuid) to authenticated;
