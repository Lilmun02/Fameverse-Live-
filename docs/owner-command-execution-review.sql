-- FAMEVERSE OWNER COMMANDS — REVIEW ONLY; NOT A DEPLOYABLE MIGRATION.
-- Prerequisite: separately reviewed docs/staged-owner-support-audit-read-foundation.sql.
-- Do not run on production or enable Vercel execution without separate CEO approval.
-- Entire transaction rolls back if action or its audit insert fails.
-- ONLY service_role can call this RPC; Vercel must verify confirmed owner JWT,
-- exactly one approved owner IP, origin, a request confirmation and idempotency key.
-- Purchasing, checkout, Stripe, balances, rewards and payouts are untouched.

create or replace function public.owner_apply_control_v1(
  p_actor_user_id uuid,
  p_idempotency_key uuid,
  p_operation text,
  p_target_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $owner_command$
declare
  v_previous public.owner_audit_events%rowtype;
  v_audit_id uuid;
  v_case_id uuid;
  v_section text;
  v_target_type text;
  v_result text;
begin
  if p_actor_user_id is null or p_idempotency_key is null or p_target_id is null then
    raise exception 'Actor, idempotency key, and target required' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = p_actor_user_id and r.role = 'owner'
  ) then
    raise exception 'Verified owner required' using errcode = '42501';
  end if;
  if char_length(trim(coalesce(p_reason, ''))) not between 12 and 600 then
    raise exception 'Reason must be between 12 and 600 characters' using errcode = '22023';
  end if;
  if p_actor_user_id = p_target_id then
    raise exception 'Owner cannot review own account' using errcode = '42501';
  end if;

  -- Serialize identical requests before checking the ledger; guarantees replay
  -- protection even if two browsers submit the same command concurrently.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_idempotency_key::text, 0));
  select * into v_previous from public.owner_audit_events a
  where a.idempotency_key = p_idempotency_key for update;
  if found then
    if v_previous.actor_user_id <> p_actor_user_id
       or v_previous.operation <> p_operation
       or v_previous.target_id is distinct from p_target_id
       or v_previous.reason <> trim(p_reason) then
      raise exception 'Idempotency key reused with different command' using errcode = '22023';
    end if;
    return pg_catalog.jsonb_build_object(
      'applied', true, 'recorded', true, 'replayed', true,
      'auditId', v_previous.id, 'operation', v_previous.operation,
      'targetId', v_previous.target_id, 'caseId', v_previous.case_id,
      'result', v_previous.outcome
    );
  end if;

  if p_operation in ('approve_badge', 'reject_badge') then
    -- These operations affect existing creator-verification requests ONLY.
    -- They do not create First Verse, Pioneer or imported recognition badges.
    if exists (
      select 1 from public.account_roles r
      where r.user_id = p_target_id and r.role = 'owner'
    ) then
      raise exception 'Cannot moderate another owner' using errcode = '42501';
    end if;
    v_section := 'badges';
    v_target_type := 'creator_verification_request';
    v_result := case when p_operation = 'approve_badge' then 'verified' else 'rejected' end;
    update public.creator_verification_requests
    set status = v_result, reviewed_at = now(), reviewed_by = p_actor_user_id,
        public_note = trim(p_reason), updated_at = now()
    where user_id = p_target_id and status in ('pending', 'needs_info');
    if not found then
      raise exception 'Pending creator verification request not found' using errcode = 'P0002';
    end if;
  elsif p_operation = 'review_support' then
    -- A review moves an EXISTING support case into under_review.
    -- It does not send a reply, ban a member, or resolve the case.
    v_section := 'support';
    v_target_type := 'owner_case';
    v_case_id := p_target_id;
    v_result := 'under_review';
    update public.owner_cases
    set status = 'under_review', updated_at = now()
    where id = p_target_id and case_type = 'support'
      and status in ('open', 'awaiting_member');
    if not found then
      raise exception 'Reviewable support case not found' using errcode = 'P0002';
    end if;
  else
    -- All other UI actions remain disabled until they have authoritative
    -- enforcement, notification, appeal, idempotency and audit contracts.
    raise exception 'Operation not activated' using errcode = '42501';
  end if;

  -- Atomic durable result: the operation commits only with a matching audit.
  insert into public.owner_audit_events(
    actor_user_id, case_id, section, operation, target_type, target_id,
    reason, outcome, idempotency_key
  ) values (
    p_actor_user_id, v_case_id, v_section, p_operation, v_target_type,
    p_target_id, trim(p_reason), 'applied', p_idempotency_key
  ) returning id into v_audit_id;

  return pg_catalog.jsonb_build_object(
    'applied', true, 'recorded', true, 'replayed', false,
    'auditId', v_audit_id, 'operation', p_operation,
    'targetId', p_target_id, 'caseId', v_case_id, 'result', v_result
  );
end;
$owner_command$;

-- PostgREST client JWT users cannot call this directly, bypassing the
-- web's approved IP gate. Only server-side service_role may execute.
revoke all on function public.owner_apply_control_v1(uuid,uuid,text,uuid,text)
  from public, anon, authenticated;
grant execute on function public.owner_apply_control_v1(uuid,uuid,text,uuid,text)
  to service_role;

-- REQUIRED BEFORE APPROVAL: Deploy to authorized isolated Supabase environment
-- with owner_cases/audit foundation. Test (1) approved/denied IP and JWT,
-- (2) missing/duplicate IDs, (3) concurrent same-key replay,
-- (4) failed audit insert rolls back action, (5) target-owner refusal,
-- (6) absence of any payment/checkout/ledger changes,
-- (7) updated verification request and support case appear in relevant sections.
