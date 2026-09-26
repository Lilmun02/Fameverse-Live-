-- Fameverse payout provider accounting corrections.
-- Held payouts stay reserved; PayPal provider results can be recorded by owner moderation.

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
      coalesce(sum(amount_cents) filter (where status in ('pending_review', 'approved', 'processing', 'held')), 0)::bigint as reserved_cents,
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

  if p_status not in ('pending_review', 'approved', 'processing', 'paid', 'rejected', 'failed', 'held') then
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
    external_reference = coalesce(
      nullif(trim(coalesce(p_external_reference, '')), ''),
      external_reference
    )
  where id = p_payout_id;

  return p_status;
end;
$$;

revoke all on function public.review_creator_payout(uuid, text, text, text) from public;
grant execute on function public.review_creator_payout(uuid, text, text, text) to authenticated;
