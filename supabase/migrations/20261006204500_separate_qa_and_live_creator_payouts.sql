
alter table public.creator_payout_methods
  add column if not exists sandbox_recipient_email text;

alter table public.creator_payout_requests
  add column if not exists payout_environment text not null default 'live',
  add column if not exists is_qa boolean not null default false;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'creator_payout_requests_environment_check'
  ) then
    alter table public.creator_payout_requests
      add constraint creator_payout_requests_environment_check
      check (payout_environment in ('sandbox','live'));
  end if;
end $$;

with qa_candidates as (
  select
    p.id,
    p.creator_user_id,
    p.payout_recipient,
    p.amount_cents,
    coalesce(sum(l.amount_cents) filter (
      where l.source_type in ('qa_payout_test','qa_payout_debit')
    ),0)::bigint as qa_net_cents,
    coalesce(sum(l.amount_cents) filter (
      where l.source_type not in ('qa_payout_test','qa_payout_debit')
    ),0)::bigint as real_net_cents
  from public.creator_payout_requests p
  left join public.creator_earnings_ledger l
    on l.creator_user_id = p.creator_user_id
  where p.status in ('pending_review','approved','processing','held')
  group by p.id
)
update public.creator_payout_requests p
set is_qa = true,
    payout_environment = 'sandbox'
from qa_candidates q
where p.id = q.id
  and q.qa_net_cents >= q.amount_cents
  and q.real_net_cents = 0;

update public.creator_payout_methods m
set sandbox_recipient_email = coalesce(
  m.sandbox_recipient_email,
  (
    select p.payout_recipient
    from public.creator_payout_requests p
    where p.creator_user_id = m.user_id
      and p.is_qa = true
      and p.payout_environment = 'sandbox'
      and p.payout_recipient is not null
    order by p.requested_at desc
    limit 1
  )
)
where m.sandbox_recipient_email is null;

create or replace function public.get_creator_payout_method_v2()
returns table(
  provider text,
  live_recipient_email text,
  sandbox_recipient_email text,
  enabled boolean
)
language sql
stable
set search_path to 'public'
as $$
  select
    m.provider,
    m.recipient_email,
    m.sandbox_recipient_email,
    m.enabled
  from public.creator_payout_methods m
  where m.user_id = auth.uid();
$$;

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
  v_user uuid := auth.uid();
  v_email text := lower(trim(coalesce(p_recipient_email,'')));
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
    v_user,'paypal','',v_email,true,now()
  )
  on conflict(user_id) do update set
    provider='paypal',
    sandbox_recipient_email=excluded.sandbox_recipient_email,
    enabled=true,
    updated_at=now();

  return query
  select m.provider,m.recipient_email,m.sandbox_recipient_email,m.enabled
  from public.creator_payout_methods m
  where m.user_id=v_user;
end;
$$;

create or replace function public.get_creator_payout_summary()
returns table(
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
set search_path to 'public'
as $$
  with ledger as (
    select
      coalesce(sum(amount_cents) filter (
        where state='pending'
          and source_type not in ('qa_payout_test','qa_payout_debit')
      ),0)::bigint as pending_cents,
      coalesce(sum(amount_cents) filter (
        where state in ('available','paid','reversed')
          and source_type not in ('qa_payout_test','qa_payout_debit')
      ),0)::bigint as available_cents
    from public.creator_earnings_ledger
    where creator_user_id=auth.uid()
  ), payout as (
    select
      coalesce(sum(amount_cents) filter (
        where status in ('pending_review','approved','processing','held')
          and is_qa=false
      ),0)::bigint as reserved_cents,
      coalesce(sum(amount_cents) filter (
        where status='paid' and is_qa=false
      ),0)::bigint as paid_cents
    from public.creator_payout_requests
    where creator_user_id=auth.uid()
  )
  select
    coalesce((
      select status from public.creator_verification_requests
      where user_id=auth.uid()
    ),'unverified')::text,
    ledger.pending_cents,
    ledger.available_cents,
    payout.reserved_cents,
    greatest(ledger.available_cents-payout.reserved_cents,0)::bigint,
    payout.paid_cents,
    2500::bigint
  from ledger cross join payout;
$$;

create or replace function public.get_creator_qa_payout_summary()
returns table(
  qa_available_cents bigint,
  qa_reserved_cents bigint,
  qa_withdrawable_cents bigint,
  qa_paid_cents bigint,
  minimum_qa_payout_cents bigint
)
language sql
stable
set search_path to 'public'
as $$
  with ledger as (
    select coalesce(sum(amount_cents),0)::bigint as available_cents
    from public.creator_earnings_ledger
    where creator_user_id=auth.uid()
      and source_type in ('qa_payout_test','qa_payout_debit')
      and state in ('available','paid','reversed')
  ), payout as (
    select
      coalesce(sum(amount_cents) filter (
        where status in ('pending_review','approved','processing','held')
          and is_qa=true
      ),0)::bigint as reserved_cents,
      coalesce(sum(amount_cents) filter (
        where status='paid' and is_qa=true
      ),0)::bigint as paid_cents
    from public.creator_payout_requests
    where creator_user_id=auth.uid()
  )
  select
    ledger.available_cents,
    payout.reserved_cents,
    greatest(ledger.available_cents-payout.reserved_cents,0)::bigint,
    payout.paid_cents,
    100::bigint
  from ledger cross join payout;
$$;

create or replace function public.owner_grant_creator_qa_earnings(
  p_username text,
  p_amount_cents bigint default 2500
)
returns table(
  creator_user_id uuid,
  username text,
  qa_available_cents bigint
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_owner uuid := auth.uid();
  v_target uuid;
  v_username text := lower(trim(leading '@' from trim(coalesce(p_username,''))));
  v_total bigint;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id=v_owner and r.role='owner'
  ) then
    raise exception 'owner access required' using errcode='42501';
  end if;

  if p_amount_cents is null or p_amount_cents < 100 or p_amount_cents > 100000 then
    raise exception 'QA payout grant must be between $1.00 and $1,000.00' using errcode='22023';
  end if;

  select p.id into v_target
  from public.profiles p
  where lower(p.username)=v_username
  limit 1;

  if v_target is null then
    raise exception 'tester profile not found' using errcode='P0002';
  end if;

  insert into public.creator_earnings_ledger(
    creator_user_id,amount_cents,state,source_type,source_key,note,available_at
  ) values (
    v_target,p_amount_cents,'available','qa_payout_test',
    'qa-payout-test:'||v_target::text||':'||gen_random_uuid()::text,
    'Owner-granted sandbox payout QA earnings; no real cash value',
    now()
  );

  select coalesce(sum(l.amount_cents),0)::bigint into v_total
  from public.creator_earnings_ledger l
  where l.creator_user_id=v_target
    and l.source_type in ('qa_payout_test','qa_payout_debit')
    and l.state in ('available','paid','reversed');

  return query select v_target,v_username,v_total;
end;
$$;

create or replace function public.request_creator_payout(p_amount_cents bigint)
returns table(
  payout_id uuid,
  amount_cents bigint,
  status text,
  requested_at timestamptz
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
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
    raise exception 'authentication required' using errcode='42501';
  end if;
  if p_amount_cents is null or p_amount_cents < 2500 then
    raise exception 'minimum payout is $25.00' using errcode='22023';
  end if;

  select status into v_verification
  from public.creator_verification_requests
  where user_id=v_user;
  if coalesce(v_verification,'unverified') <> 'verified' then
    raise exception 'creator verification required before payout' using errcode='42501';
  end if;

  select provider,recipient_email into v_provider,v_recipient
  from public.creator_payout_methods
  where user_id=v_user and enabled=true;
  if v_provider is null or nullif(trim(coalesce(v_recipient,'')),'') is null then
    raise exception 'active live payout method required' using errcode='22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_user::text,2500));

  select coalesce(sum(amount_cents) filter (
    where state in ('available','paid','reversed')
      and source_type not in ('qa_payout_test','qa_payout_debit')
  ),0)::bigint into v_available
  from public.creator_earnings_ledger
  where creator_user_id=v_user;

  select coalesce(sum(amount_cents) filter (
    where status in ('pending_review','approved','processing','held')
      and is_qa=false
  ),0)::bigint into v_reserved
  from public.creator_payout_requests
  where creator_user_id=v_user;

  if p_amount_cents > greatest(v_available-v_reserved,0) then
    raise exception 'insufficient cleared creator earnings' using errcode='22003';
  end if;

  insert into public.creator_payout_requests(
    creator_user_id,amount_cents,payout_provider,payout_recipient,
    payout_environment,is_qa
  ) values (
    v_user,p_amount_cents,v_provider,v_recipient,'live',false
  ) returning * into v_request;

  return query
  select v_request.id,v_request.amount_cents,v_request.status,v_request.requested_at;
end;
$$;

create or replace function public.request_creator_qa_payout(p_amount_cents bigint)
returns table(
  payout_id uuid,
  amount_cents bigint,
  status text,
  requested_at timestamptz
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_user uuid := auth.uid();
  v_available bigint;
  v_reserved bigint;
  v_recipient text;
  v_request public.creator_payout_requests%rowtype;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode='42501';
  end if;
  if p_amount_cents is null or p_amount_cents < 100 then
    raise exception 'minimum QA payout is $1.00' using errcode='22023';
  end if;

  select sandbox_recipient_email into v_recipient
  from public.creator_payout_methods
  where user_id=v_user and enabled=true;

  if nullif(trim(coalesce(v_recipient,'')),'') is null then
    raise exception 'sandbox payout email required' using errcode='22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('qa-payout:'||v_user::text,0));

  select coalesce(sum(amount_cents),0)::bigint into v_available
  from public.creator_earnings_ledger
  where creator_user_id=v_user
    and source_type in ('qa_payout_test','qa_payout_debit')
    and state in ('available','paid','reversed');

  select coalesce(sum(amount_cents) filter (
    where status in ('pending_review','approved','processing','held')
      and is_qa=true
  ),0)::bigint into v_reserved
  from public.creator_payout_requests
  where creator_user_id=v_user;

  if p_amount_cents > greatest(v_available-v_reserved,0) then
    raise exception 'insufficient QA payout balance' using errcode='22003';
  end if;

  insert into public.creator_payout_requests(
    creator_user_id,amount_cents,payout_provider,payout_recipient,
    payout_environment,is_qa
  ) values (
    v_user,p_amount_cents,'paypal',v_recipient,'sandbox',true
  ) returning * into v_request;

  return query
  select v_request.id,v_request.amount_cents,v_request.status,v_request.requested_at;
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
set search_path to 'public','pg_temp'
as $$
declare
  v_request public.creator_payout_requests%rowtype;
  v_verification text;
  v_provider_status text;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id=auth.uid() and r.role='owner'
  ) then
    raise exception 'owner moderation access required' using errcode='42501';
  end if;

  if p_status not in ('pending_review','approved','processing','paid','rejected','failed','held') then
    raise exception 'invalid payout status' using errcode='22023';
  end if;

  select * into v_request
  from public.creator_payout_requests
  where id=p_payout_id
  for update;
  if not found then
    raise exception 'payout request not found' using errcode='P0002';
  end if;

  if v_request.status='paid' and p_status<>'paid' then
    raise exception 'paid payout cannot be reopened' using errcode='22023';
  end if;

  v_provider_status := upper(coalesce(v_request.provider_status,''));

  if p_status='failed'
     and v_request.payout_provider='paypal'
     and v_provider_status not in (
       'FAILED','RETURNED','BLOCKED','REFUNDED','DENIED',
       'AUTH_FAILED','UNSUPPORTED_PROVIDER'
     ) then
    raise exception 'PayPal provider failure confirmation required before terminal failure'
      using errcode='22023';
  end if;

  if p_status='paid' then
    if v_request.payout_provider='paypal'
       and (v_request.provider_batch_id is null or v_provider_status<>'SUCCESS') then
      raise exception 'PayPal SUCCESS confirmation required before marking payout paid'
        using errcode='22023';
    end if;

    if v_request.is_qa then
      insert into public.creator_earnings_ledger(
        creator_user_id,amount_cents,state,source_type,source_key,note,available_at
      ) values (
        v_request.creator_user_id,-v_request.amount_cents,'paid',
        'qa_payout_debit','qa-payout:'||v_request.id::text,
        'Sandbox QA payout debit; no real cash value',now()
      )
      on conflict(source_key) do nothing;
    else
      select status into v_verification
      from public.creator_verification_requests
      where user_id=v_request.creator_user_id;
      if coalesce(v_verification,'unverified')<>'verified' then
        raise exception 'verified creator required before marking payout paid'
          using errcode='42501';
      end if;

      insert into public.creator_earnings_ledger(
        creator_user_id,amount_cents,state,source_type,source_key,note,available_at
      ) values (
        v_request.creator_user_id,-v_request.amount_cents,'paid',
        'payout','payout:'||v_request.id::text,'Creator payout debit',now()
      )
      on conflict(source_key) do nothing;
    end if;
  end if;

  update public.creator_payout_requests
  set status=p_status,
      reviewed_at=now(),
      reviewed_by=auth.uid(),
      paid_at=case when p_status='paid' then coalesce(paid_at,now()) else paid_at end,
      moderation_note=nullif(trim(coalesce(p_moderation_note,'')),''),
      external_reference=coalesce(
        nullif(trim(coalesce(p_external_reference,'')),''),
        external_reference
      )
  where id=p_payout_id;

  return p_status;
end;
$$;

create or replace function public.get_creator_payout_requests_v2(p_limit integer default 20)
returns table(
  payout_id uuid,
  amount_cents bigint,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  paid_at timestamptz,
  moderation_note text,
  external_reference text,
  provider_status text,
  provider_batch_id text,
  provider_status_updated_at timestamptz,
  payout_environment text,
  is_qa boolean
)
language sql
stable
set search_path to 'public'
as $$
  select
    r.id,r.amount_cents,r.status,r.requested_at,r.reviewed_at,r.paid_at,
    r.moderation_note,r.external_reference,r.provider_status,
    r.provider_batch_id,r.provider_status_updated_at,
    r.payout_environment,r.is_qa
  from public.creator_payout_requests r
  where r.creator_user_id=auth.uid()
  order by r.requested_at desc
  limit least(greatest(coalesce(p_limit,20),1),100);
$$;

create or replace function public.get_creator_payout_moderation_queue_v3(p_limit integer default 50)
returns table(
  payout_id uuid,
  creator_user_id uuid,
  display_name text,
  username text,
  verification_status text,
  amount_cents bigint,
  status text,
  requested_at timestamptz,
  moderation_note text,
  external_reference text,
  provider_status text,
  provider_batch_id text,
  provider_status_updated_at timestamptz,
  payout_environment text,
  is_qa boolean
)
language plpgsql
stable
security definer
set search_path to 'public','pg_temp'
as $$
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id=auth.uid() and r.role='owner'
  ) then
    raise exception 'owner moderation access required' using errcode='42501';
  end if;

  return query
  select
    request.id,
    request.creator_user_id,
    coalesce(profile.display_name,profile.username,'Fameverse User'),
    profile.username,
    coalesce(verification.status,'unverified'),
    request.amount_cents,
    request.status,
    request.requested_at,
    request.moderation_note,
    request.external_reference,
    request.provider_status,
    request.provider_batch_id,
    request.provider_status_updated_at,
    request.payout_environment,
    request.is_qa
  from public.creator_payout_requests request
  left join public.profiles profile on profile.id=request.creator_user_id
  left join public.creator_verification_requests verification
    on verification.user_id=request.creator_user_id
  where request.status in ('pending_review','approved','processing','held')
  order by request.requested_at asc
  limit least(greatest(coalesce(p_limit,50),1),200);
end;
$$;

revoke all on function public.get_creator_payout_method_v2() from public;
revoke all on function public.set_creator_sandbox_payout_method(text) from public;
revoke all on function public.get_creator_qa_payout_summary() from public;
revoke all on function public.owner_grant_creator_qa_earnings(text,bigint) from public;
revoke all on function public.request_creator_qa_payout(bigint) from public;
revoke all on function public.get_creator_payout_requests_v2(integer) from public;
revoke all on function public.get_creator_payout_moderation_queue_v3(integer) from public;

grant execute on function public.get_creator_payout_method_v2() to authenticated;
grant execute on function public.set_creator_sandbox_payout_method(text) to authenticated;
grant execute on function public.get_creator_qa_payout_summary() to authenticated;
grant execute on function public.owner_grant_creator_qa_earnings(text,bigint) to authenticated;
grant execute on function public.request_creator_qa_payout(bigint) to authenticated;
grant execute on function public.get_creator_payout_requests_v2(integer) to authenticated;
grant execute on function public.get_creator_payout_moderation_queue_v3(integer) to authenticated;
