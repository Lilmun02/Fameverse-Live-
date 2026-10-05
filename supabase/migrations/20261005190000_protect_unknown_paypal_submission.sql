-- Protect ambiguous PayPal submissions from becoming terminal or double-payable.
-- This repairs legacy rows that were manually marked failed while the provider
-- outcome was still unknown, and prevents old clients from doing that again.

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
as $function$
declare
  v_request public.creator_payout_requests%rowtype;
  v_verification text;
  v_provider_status text;
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

  v_provider_status := upper(coalesce(v_request.provider_status, ''));

  -- PayPal money state is provider-authoritative. Old app builds must not be
  -- able to turn an in-flight/unknown submission into a terminal failure,
  -- because that would release the reservation and could permit a second payout.
  if p_status = 'failed'
     and v_request.payout_provider = 'paypal'
     and v_provider_status not in (
       'FAILED', 'RETURNED', 'BLOCKED', 'REFUNDED', 'DENIED',
       'AUTH_FAILED', 'UNSUPPORTED_PROVIDER'
     ) then
    raise exception 'PayPal provider failure confirmation required before terminal failure'
      using errcode = '22023';
  end if;

  if p_status = 'paid' then
    select status into v_verification
    from public.creator_verification_requests
    where user_id = v_request.creator_user_id;

    if coalesce(v_verification, 'unverified') <> 'verified' then
      raise exception 'verified creator required before marking payout paid' using errcode = '42501';
    end if;

    if v_request.payout_provider = 'paypal'
       and (v_request.provider_batch_id is null or v_provider_status <> 'SUCCESS') then
      raise exception 'PayPal SUCCESS confirmation required before marking payout paid'
        using errcode = '22023';
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
$function$;

revoke all on function public.review_creator_payout(uuid, text, text, text) from public;
revoke all on function public.review_creator_payout(uuid, text, text, text) from anon;
grant execute on function public.review_creator_payout(uuid, text, text, text) to authenticated;
grant execute on function public.review_creator_payout(uuid, text, text, text) to service_role;

-- Repair any legacy payout that was made terminal while PayPal was still in an
-- ambiguous pre-batch state. Keep the money reserved and route it back through
-- the deterministic/idempotent recovery path.
update public.creator_payout_requests
set status = 'processing',
    provider_status = 'SUBMISSION_UNKNOWN',
    provider_status_updated_at = now(),
    moderation_note = 'Recovered from a legacy terminal state while PayPal submission outcome was unknown. Keep reserved until provider recovery/sync completes.'
where status = 'failed'
  and payout_provider = 'paypal'
  and provider_batch_id is null
  and upper(coalesce(provider_status, '')) in ('SUBMITTING', 'SUBMISSION_UNKNOWN');
