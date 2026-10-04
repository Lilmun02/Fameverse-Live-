-- Build 32 payout recovery repair.
-- A payout whose PayPal submission result is unknown must stay reserved and may
-- be retried only through the same deterministic provider submission path.

create or replace function public.begin_creator_payout_processing(p_payout_id uuid)
returns table(
  payout_id uuid,
  creator_user_id uuid,
  amount_cents bigint,
  payout_provider text,
  payout_recipient text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_request public.creator_payout_requests%rowtype;
  v_is_recovery boolean := false;
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

  v_is_recovery :=
    v_request.status = 'processing'
    and v_request.provider_batch_id is null
    and coalesce(v_request.provider_status, '') in ('SUBMISSION_UNKNOWN', 'SUBMITTING');

  if v_request.status <> 'approved' and not v_is_recovery then
    raise exception 'payout must be approved or awaiting safe provider recovery' using errcode = '22023';
  end if;

  if v_request.payout_provider is null or v_request.payout_recipient is null then
    raise exception 'payout method snapshot missing' using errcode = '22023';
  end if;

  update public.creator_payout_requests
  set status = 'processing',
      provider_status = 'SUBMITTING',
      provider_status_updated_at = now(),
      reviewed_at = coalesce(reviewed_at, now()),
      reviewed_by = coalesce(reviewed_by, auth.uid()),
      moderation_note = case
        when v_is_recovery then 'Retrying an idempotent PayPal submission after an unknown provider result.'
        else moderation_note
      end
  where id = p_payout_id;

  return query
  select v_request.id, v_request.creator_user_id, v_request.amount_cents,
         v_request.payout_provider, v_request.payout_recipient;
end;
$function$;

revoke all on function public.begin_creator_payout_processing(uuid) from public;
revoke all on function public.begin_creator_payout_processing(uuid) from anon;
grant execute on function public.begin_creator_payout_processing(uuid) to authenticated;
grant execute on function public.begin_creator_payout_processing(uuid) to service_role;
