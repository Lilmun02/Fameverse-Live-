
alter table public.creator_payout_methods
  add column if not exists live_recipient_email text;

update public.creator_payout_methods m
set live_recipient_email = m.recipient_email
where m.live_recipient_email is null
  and (
    m.sandbox_recipient_email is null
    or exists (
      select 1
      from public.creator_payout_requests p
      where p.creator_user_id=m.user_id
        and p.is_qa=false
    )
  );

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
    m.live_recipient_email,
    m.sandbox_recipient_email,
    m.enabled
  from public.creator_payout_methods m
  where m.user_id=auth.uid();
$$;

create or replace function public.set_creator_payout_method(
  p_provider text,
  p_recipient_email text
)
returns table(
  provider text,
  recipient_email text,
  enabled boolean
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_user uuid:=auth.uid();
  v_provider text:=lower(trim(coalesce(p_provider,'')));
  v_email text:=lower(trim(coalesce(p_recipient_email,'')));
begin
  if v_user is null then
    raise exception 'authentication required' using errcode='42501';
  end if;
  if v_provider<>'paypal' then
    raise exception 'unsupported payout provider' using errcode='22023';
  end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$' then
    raise exception 'valid payout email required' using errcode='22023';
  end if;

  insert into public.creator_payout_methods(
    user_id,provider,recipient_email,live_recipient_email,enabled,updated_at
  ) values (
    v_user,v_provider,v_email,v_email,true,now()
  )
  on conflict(user_id) do update set
    provider=excluded.provider,
    recipient_email=excluded.recipient_email,
    live_recipient_email=excluded.live_recipient_email,
    enabled=true,
    updated_at=now();

  return query
  select m.provider,m.recipient_email,m.enabled
  from public.creator_payout_methods m
  where m.user_id=v_user;
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
  v_user uuid:=auth.uid();
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
  if p_amount_cents is null or p_amount_cents<2500 then
    raise exception 'minimum payout is $25.00' using errcode='22023';
  end if;

  select status into v_verification
  from public.creator_verification_requests
  where user_id=v_user;
  if coalesce(v_verification,'unverified')<>'verified' then
    raise exception 'creator verification required before payout' using errcode='42501';
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
