
create or replace function public.get_creator_verification_progress()
returns table(
  verification_status text,
  follower_count bigint,
  follower_requirement bigint,
  eligible_received_coins bigint,
  received_coins_requirement bigint,
  eligible boolean,
  requested_at timestamptz,
  reviewed_at timestamptz,
  public_note text,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_user uuid := auth.uid();
  v_status text := 'unverified';
  v_followers bigint := 0;
  v_received bigint := 0;
  v_requested_at timestamptz;
  v_reviewed_at timestamptz;
  v_public_note text;
  v_updated_at timestamptz;
  v_is_owner boolean := false;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode='42501';
  end if;

  select exists(
    select 1 from public.account_roles r
    where r.user_id=v_user and r.role='owner'
  ) into v_is_owner;

  select
    coalesce(r.status,'unverified'),
    r.requested_at,
    r.reviewed_at,
    r.public_note,
    r.updated_at
  into
    v_status,
    v_requested_at,
    v_reviewed_at,
    v_public_note,
    v_updated_at
  from (select 1) seed
  left join public.creator_verification_requests r
    on r.user_id=v_user;

  if v_is_owner then
    return query
    select
      'verified'::text,
      0::bigint,
      0::bigint,
      0::bigint,
      0::bigint,
      true,
      v_requested_at,
      v_reviewed_at,
      'Owner account — creator verification requirements do not apply.'::text,
      coalesce(v_updated_at,now());
    return;
  end if;

  select count(*)::bigint
  into v_followers
  from public.follows f
  where f.following_id=v_user;

  select coalesce(sum(funding.cash_backed_coins),0)::bigint
  into v_received
  from public.gift_events gift
  join public.gift_funding_breakdowns funding
    on funding.gift_event_id=gift.id
  where gift.recipient_user_id=v_user
    and gift.sender_user_id is not null
    and gift.sender_user_id<>gift.recipient_user_id
    and funding.cash_backed_coins>0;

  return query
  select
    coalesce(v_status,'unverified')::text,
    v_followers,
    100::bigint,
    v_received,
    500000::bigint,
    (v_followers>=100 and v_received>=500000)::boolean,
    v_requested_at,
    v_reviewed_at,
    v_public_note,
    v_updated_at;
end;
$$;

create or replace function public.request_creator_verification()
returns text
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_user uuid:=auth.uid();
  v_status text;
  v_followers bigint:=0;
  v_received bigint:=0;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode='42501';
  end if;

  if exists(
    select 1 from public.account_roles r
    where r.user_id=v_user and r.role='owner'
  ) then
    return 'verified';
  end if;

  select status into v_status
  from public.creator_verification_requests
  where user_id=v_user;

  if v_status='verified' then return 'verified'; end if;
  if v_status='suspended' then
    raise exception 'verification is suspended and cannot be requested right now'
      using errcode='42501';
  end if;

  select count(*)::bigint into v_followers
  from public.follows f
  where f.following_id=v_user;

  select coalesce(sum(funding.cash_backed_coins),0)::bigint into v_received
  from public.gift_events gift
  join public.gift_funding_breakdowns funding
    on funding.gift_event_id=gift.id
  where gift.recipient_user_id=v_user
    and gift.sender_user_id is not null
    and gift.sender_user_id<>gift.recipient_user_id
    and funding.cash_backed_coins>0;

  if v_followers<100 or v_received<500000 then
    raise exception 'verification eligibility requires 100 followers and 500000 eligible Fame Coins received'
      using errcode='22023';
  end if;

  insert into public.creator_verification_requests(
    user_id,status,requested_at,reviewed_at,reviewed_by,public_note,updated_at
  ) values (
    v_user,'pending',now(),null,null,null,now()
  )
  on conflict(user_id) do update set
    status=case
      when creator_verification_requests.status in ('verified','suspended')
        then creator_verification_requests.status
      else 'pending'
    end,
    requested_at=case
      when creator_verification_requests.status in ('verified','suspended')
        then creator_verification_requests.requested_at
      else now()
    end,
    reviewed_at=case
      when creator_verification_requests.status in ('verified','suspended')
        then creator_verification_requests.reviewed_at
      else null
    end,
    reviewed_by=case
      when creator_verification_requests.status in ('verified','suspended')
        then creator_verification_requests.reviewed_by
      else null
    end,
    public_note=case
      when creator_verification_requests.status in ('verified','suspended')
        then creator_verification_requests.public_note
      else null
    end,
    updated_at=now()
  returning status into v_status;

  return v_status;
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
  ), access as (
    select exists(
      select 1 from public.account_roles r
      where r.user_id=auth.uid() and r.role='owner'
    ) as is_owner
  )
  select
    case
      when access.is_owner then 'verified'
      else coalesce((
        select status
        from public.creator_verification_requests
        where user_id=auth.uid()
      ),'unverified')
    end::text,
    ledger.pending_cents,
    ledger.available_cents,
    payout.reserved_cents,
    greatest(ledger.available_cents-payout.reserved_cents,0)::bigint,
    payout.paid_cents,
    2500::bigint
  from ledger cross join payout cross join access;
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
  v_user uuid:=auth.uid();
  v_verification text;
  v_is_owner boolean:=false;
  v_available bigint;
  v_reserved bigint;
  v_provider text;
  v_recipient text;
  v_request public.creator_payout_requests%rowtype;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode='42501';
  end if;
  if p_amount_cents is null or p_amount_cents<2500 then
    raise exception 'minimum payout is $25.00' using errcode='22023';
  end if;

  select exists(
    select 1 from public.account_roles r
    where r.user_id=v_user and r.role='owner'
  ) into v_is_owner;

  if not v_is_owner then
    select status into v_verification
    from public.creator_verification_requests
    where user_id=v_user;
    if coalesce(v_verification,'unverified')<>'verified' then
      raise exception 'creator verification required before payout'
        using errcode='42501';
    end if;
  end if;

  select provider,live_recipient_email into v_provider,v_recipient
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

  if p_amount_cents>greatest(v_available-v_reserved,0) then
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
  v_target_is_owner boolean:=false;
begin
  if not exists(
    select 1 from public.account_roles r
    where r.user_id=auth.uid() and r.role='owner'
  ) then
    raise exception 'owner moderation access required' using errcode='42501';
  end if;

  if p_status not in (
    'pending_review','approved','processing','paid','rejected','failed','held'
  ) then
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

  v_provider_status:=upper(coalesce(v_request.provider_status,''));

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
       and (
         v_request.provider_batch_id is null
         or v_provider_status<>'SUCCESS'
       ) then
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
      select exists(
        select 1 from public.account_roles r
        where r.user_id=v_request.creator_user_id and r.role='owner'
      ) into v_target_is_owner;

      if not v_target_is_owner then
        select status into v_verification
        from public.creator_verification_requests
        where user_id=v_request.creator_user_id;
        if coalesce(v_verification,'unverified')<>'verified' then
          raise exception 'verified creator required before marking payout paid'
            using errcode='42501';
        end if;
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
      paid_at=case
        when p_status='paid' then coalesce(paid_at,now())
        else paid_at
      end,
      moderation_note=nullif(trim(coalesce(p_moderation_note,'')),''),
      external_reference=coalesce(
        nullif(trim(coalesce(p_external_reference,'')),''),
        external_reference
      )
  where id=p_payout_id;

  return p_status;
end;
$$;
