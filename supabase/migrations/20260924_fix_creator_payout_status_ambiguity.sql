-- Build 17 regression repair: remove PL/pgSQL output-column ambiguity from
-- request_creator_payout. RETURNS TABLE exposes `amount_cents`, `status`, and
-- `requested_at` as PL/pgSQL variables, so all table references must be
-- explicitly qualified.

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

  select verification_request.status
    into v_verification
  from public.creator_verification_requests as verification_request
  where verification_request.user_id = v_user;

  if coalesce(v_verification, 'unverified') <> 'verified' then
    raise exception 'creator verification required before payout' using errcode = '42501';
  end if;

  select method.provider, method.recipient_email
    into v_provider, v_recipient
  from public.creator_payout_methods as method
  where method.user_id = v_user
    and method.enabled = true;

  if v_provider is null or v_recipient is null then
    raise exception 'active payout method required' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_user::text, 2500));

  select coalesce(
      sum(ledger.amount_cents) filter (
        where ledger.state in ('available', 'paid', 'reversed')
      ),
      0
    )::bigint
    into v_available
  from public.creator_earnings_ledger as ledger
  where ledger.creator_user_id = v_user;

  select coalesce(
      sum(payout.amount_cents) filter (
        where payout.status in ('pending_review', 'approved', 'processing', 'held')
      ),
      0
    )::bigint
    into v_reserved
  from public.creator_payout_requests as payout
  where payout.creator_user_id = v_user;

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

  return query
  select
    v_request.id,
    v_request.amount_cents,
    v_request.status,
    v_request.requested_at;
end;
$$;

revoke all on function public.request_creator_payout(bigint) from public;
grant execute on function public.request_creator_payout(bigint) to authenticated;
