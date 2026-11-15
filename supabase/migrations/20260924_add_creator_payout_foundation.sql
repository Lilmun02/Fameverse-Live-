-- Fameverse creator payout foundation.
-- Product law: payout requests require verification, cleared creator earnings,
-- moderation approval, and a minimum request of $25.00 (2500 cents).
-- This migration intentionally does NOT define a coin-to-cash conversion or
-- creator revenue split. Real-dollar creator earnings are recorded separately.

create table if not exists public.creator_verification_requests (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  status text not null default 'unverified',
  requested_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  public_note text,
  updated_at timestamptz not null default now(),
  constraint creator_verification_status_check
    check (status in ('unverified', 'pending', 'verified', 'needs_info', 'rejected', 'suspended')),
  constraint creator_verification_note_length_check
    check (public_note is null or char_length(public_note) <= 500)
);

create table if not exists public.creator_earnings_ledger (
  id uuid primary key default gen_random_uuid(),
  creator_user_id uuid not null references public.profiles(id) on delete cascade,
  amount_cents bigint not null,
  state text not null default 'pending',
  source_type text not null,
  source_key text,
  note text,
  available_at timestamptz,
  created_at timestamptz not null default now(),
  constraint creator_earnings_nonzero_check check (amount_cents <> 0),
  constraint creator_earnings_state_check
    check (state in ('pending', 'available', 'paid', 'reversed')),
  constraint creator_earnings_source_type_length_check
    check (char_length(source_type) between 1 and 40),
  constraint creator_earnings_note_length_check
    check (note is null or char_length(note) <= 500)
);

create unique index if not exists creator_earnings_source_key_unique
  on public.creator_earnings_ledger(source_key)
  where source_key is not null;

create index if not exists creator_earnings_user_created_idx
  on public.creator_earnings_ledger(creator_user_id, created_at desc);

create table if not exists public.creator_payout_requests (
  id uuid primary key default gen_random_uuid(),
  creator_user_id uuid not null references public.profiles(id) on delete cascade,
  amount_cents bigint not null,
  status text not null default 'pending_review',
  requested_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  paid_at timestamptz,
  moderation_note text,
  external_reference text,
  constraint creator_payout_minimum_check check (amount_cents >= 2500),
  constraint creator_payout_status_check
    check (status in ('pending_review', 'approved', 'processing', 'paid', 'rejected', 'cancelled')),
  constraint creator_payout_note_length_check
    check (moderation_note is null or char_length(moderation_note) <= 500),
  constraint creator_payout_reference_length_check
    check (external_reference is null or char_length(external_reference) <= 200)
);

create index if not exists creator_payout_user_requested_idx
  on public.creator_payout_requests(creator_user_id, requested_at desc);
create index if not exists creator_payout_status_requested_idx
  on public.creator_payout_requests(status, requested_at asc);

alter table public.creator_verification_requests enable row level security;
alter table public.creator_earnings_ledger enable row level security;
alter table public.creator_payout_requests enable row level security;

drop policy if exists "creators can read own verification" on public.creator_verification_requests;
create policy "creators can read own verification"
on public.creator_verification_requests for select
to authenticated
using (
  auth.uid() = user_id
  or exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  )
);

drop policy if exists "creators can read own earnings" on public.creator_earnings_ledger;
create policy "creators can read own earnings"
on public.creator_earnings_ledger for select
to authenticated
using (
  auth.uid() = creator_user_id
  or exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  )
);

drop policy if exists "creators can read own payout requests" on public.creator_payout_requests;
create policy "creators can read own payout requests"
on public.creator_payout_requests for select
to authenticated
using (
  auth.uid() = creator_user_id
  or exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  )
);

create or replace function public.request_creator_verification()
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_status text;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  insert into public.creator_verification_requests (
    user_id,
    status,
    requested_at,
    reviewed_at,
    reviewed_by,
    public_note,
    updated_at
  ) values (
    v_user,
    'pending',
    now(),
    null,
    null,
    null,
    now()
  )
  on conflict (user_id) do update set
    status = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.status
      else 'pending'
    end,
    requested_at = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.requested_at
      else now()
    end,
    reviewed_at = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.reviewed_at
      else null
    end,
    reviewed_by = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.reviewed_by
      else null
    end,
    public_note = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.public_note
      else null
    end,
    updated_at = now()
  returning status into v_status;

  return v_status;
end;
$$;

create or replace function public.get_creator_payout_summary()
returns table (
  verification_status text,
  pending_cents bigint,
  available_cents bigint,
  reserved_cents bigint,
  withdrawable_cents bigint,
  paid_cents bigint,
  minimum_payout_cents bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  with ledger as (
    select
      coalesce(sum(amount_cents) filter (where state = 'pending'), 0)::bigint as pending_cents,
      coalesce(sum(amount_cents) filter (where state in ('available', 'paid', 'reversed')), 0)::bigint as available_cents
    from public.creator_earnings_ledger
    where creator_user_id = auth.uid()
  ), payout as (
    select
      coalesce(sum(amount_cents) filter (where status in ('pending_review', 'approved', 'processing')), 0)::bigint as reserved_cents,
      coalesce(sum(amount_cents) filter (where status = 'paid'), 0)::bigint as paid_cents
    from public.creator_payout_requests
    where creator_user_id = auth.uid()
  )
  select
    coalesce((select status from public.creator_verification_requests where user_id = auth.uid()), 'unverified')::text,
    ledger.pending_cents,
    ledger.available_cents,
    payout.reserved_cents,
    greatest(ledger.available_cents - payout.reserved_cents, 0)::bigint,
    payout.paid_cents,
    2500::bigint
  from ledger cross join payout;
$$;

create or replace function public.get_creator_payout_requests(p_limit integer default 20)
returns table (
  payout_id uuid,
  amount_cents bigint,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  paid_at timestamptz,
  moderation_note text,
  external_reference text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    request.id,
    request.amount_cents,
    request.status,
    request.requested_at,
    request.reviewed_at,
    request.paid_at,
    request.moderation_note,
    request.external_reference
  from public.creator_payout_requests request
  where request.creator_user_id = auth.uid()
  order by request.requested_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
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

  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 2500));

  select coalesce(sum(amount_cents) filter (where state in ('available', 'paid', 'reversed')), 0)::bigint
    into v_available
  from public.creator_earnings_ledger
  where creator_user_id = v_user;

  select coalesce(sum(amount_cents) filter (where status in ('pending_review', 'approved', 'processing')), 0)::bigint
    into v_reserved
  from public.creator_payout_requests
  where creator_user_id = v_user;

  if p_amount_cents > greatest(v_available - v_reserved, 0) then
    raise exception 'insufficient cleared creator earnings' using errcode = '22003';
  end if;

  insert into public.creator_payout_requests (creator_user_id, amount_cents)
  values (v_user, p_amount_cents)
  returning * into v_request;

  return query select v_request.id, v_request.amount_cents, v_request.status, v_request.requested_at;
end;
$$;

create or replace function public.get_creator_verification_moderation_queue(p_limit integer default 50)
returns table (
  user_id uuid,
  display_name text,
  username text,
  status text,
  requested_at timestamptz,
  public_note text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  ) then
    raise exception 'owner moderation access required' using errcode = '42501';
  end if;

  return query
  select
    request.user_id,
    coalesce(profile.display_name, profile.username, 'Fameverse User'),
    profile.username,
    request.status,
    request.requested_at,
    request.public_note
  from public.creator_verification_requests request
  left join public.profiles profile on profile.id = request.user_id
  where request.status in ('pending', 'needs_info')
  order by request.requested_at asc nulls last
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
end;
$$;

create or replace function public.review_creator_verification(
  p_user_id uuid,
  p_status text,
  p_public_note text default null
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  ) then
    raise exception 'owner moderation access required' using errcode = '42501';
  end if;

  if p_status not in ('pending', 'verified', 'needs_info', 'rejected', 'suspended') then
    raise exception 'invalid verification status' using errcode = '22023';
  end if;

  insert into public.creator_verification_requests (
    user_id,
    status,
    requested_at,
    reviewed_at,
    reviewed_by,
    public_note,
    updated_at
  ) values (
    p_user_id,
    p_status,
    now(),
    now(),
    auth.uid(),
    nullif(trim(coalesce(p_public_note, '')), ''),
    now()
  )
  on conflict (user_id) do update set
    status = excluded.status,
    reviewed_at = now(),
    reviewed_by = auth.uid(),
    public_note = excluded.public_note,
    updated_at = now();

  return p_status;
end;
$$;

create or replace function public.get_creator_payout_moderation_queue(p_limit integer default 50)
returns table (
  payout_id uuid,
  creator_user_id uuid,
  display_name text,
  username text,
  verification_status text,
  amount_cents bigint,
  status text,
  requested_at timestamptz,
  moderation_note text,
  external_reference text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  ) then
    raise exception 'owner moderation access required' using errcode = '42501';
  end if;

  return query
  select
    request.id,
    request.creator_user_id,
    coalesce(profile.display_name, profile.username, 'Fameverse User'),
    profile.username,
    coalesce(verification.status, 'unverified'),
    request.amount_cents,
    request.status,
    request.requested_at,
    request.moderation_note,
    request.external_reference
  from public.creator_payout_requests request
  left join public.profiles profile on profile.id = request.creator_user_id
  left join public.creator_verification_requests verification on verification.user_id = request.creator_user_id
  where request.status in ('pending_review', 'approved', 'processing')
  order by request.requested_at asc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
end;
$$;

create or replace function public.review_creator_payout(
  p_payout_id uuid,
  p_status text,
  p_moderation_note text default null,
  p_external_reference text default null
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_request public.creator_payout_requests%rowtype;
  v_verification text;
begin
  if not exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = auth.uid() and role_row.role = 'owner'
  ) then
    raise exception 'owner moderation access required' using errcode = '42501';
  end if;

  if p_status not in ('pending_review', 'approved', 'processing', 'paid', 'rejected') then
    raise exception 'invalid payout status' using errcode = '22023';
  end if;

  select * into v_request
  from public.creator_payout_requests
  where id = p_payout_id
  for update;

  if not found then
    raise exception 'payout request not found' using errcode = 'P0002';
  end if;

  if v_request.status = 'paid' and p_status <> 'paid' then
    raise exception 'paid payout cannot be reopened' using errcode = '22023';
  end if;

  if p_status = 'paid' then
    select status into v_verification
    from public.creator_verification_requests
    where user_id = v_request.creator_user_id;

    if coalesce(v_verification, 'unverified') <> 'verified' then
      raise exception 'verified creator required before marking payout paid' using errcode = '42501';
    end if;

    insert into public.creator_earnings_ledger (
      creator_user_id,
      amount_cents,
      state,
      source_type,
      source_key,
      note,
      available_at
    ) values (
      v_request.creator_user_id,
      -v_request.amount_cents,
      'paid',
      'payout',
      'payout:' || v_request.id::text,
      'Creator payout debit',
      now()
    )
    on conflict (source_key) do nothing;
  end if;

  update public.creator_payout_requests
  set
    status = p_status,
    reviewed_at = now(),
    reviewed_by = auth.uid(),
    paid_at = case when p_status = 'paid' then coalesce(paid_at, now()) else paid_at end,
    moderation_note = nullif(trim(coalesce(p_moderation_note, '')), ''),
    external_reference = nullif(trim(coalesce(p_external_reference, '')), '')
  where id = p_payout_id;

  return p_status;
end;
$$;

revoke all privileges on table public.creator_verification_requests from anon;
revoke all privileges on table public.creator_earnings_ledger from anon;
revoke all privileges on table public.creator_payout_requests from anon;
revoke insert, update, delete on table public.creator_verification_requests from authenticated;
revoke insert, update, delete on table public.creator_earnings_ledger from authenticated;
revoke insert, update, delete on table public.creator_payout_requests from authenticated;
grant select on table public.creator_verification_requests to authenticated;
grant select on table public.creator_earnings_ledger to authenticated;
grant select on table public.creator_payout_requests to authenticated;

revoke all on function public.request_creator_verification() from public;
grant execute on function public.request_creator_verification() to authenticated;
revoke all on function public.get_creator_payout_summary() from public;
grant execute on function public.get_creator_payout_summary() to authenticated;
revoke all on function public.get_creator_payout_requests(integer) from public;
grant execute on function public.get_creator_payout_requests(integer) to authenticated;
revoke all on function public.request_creator_payout(bigint) from public;
grant execute on function public.request_creator_payout(bigint) to authenticated;
revoke all on function public.get_creator_verification_moderation_queue(integer) from public;
grant execute on function public.get_creator_verification_moderation_queue(integer) to authenticated;
revoke all on function public.review_creator_verification(uuid, text, text) from public;
grant execute on function public.review_creator_verification(uuid, text, text) to authenticated;
revoke all on function public.get_creator_payout_moderation_queue(integer) from public;
grant execute on function public.get_creator_payout_moderation_queue(integer) to authenticated;
revoke all on function public.review_creator_payout(uuid, text, text, text) from public;
grant execute on function public.review_creator_payout(uuid, text, text, text) to authenticated;
