-- Build 32 payout recovery repair.
-- Provider-held payouts must remain visible to the owner so PayPal status can be
-- synchronized again. A temporary provider hold is not a terminal Fameverse state.

create or replace function public.get_creator_payout_moderation_queue(p_limit integer default 50)
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
  external_reference text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
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
  where request.status in ('pending_review', 'approved', 'processing', 'held')
  order by request.requested_at asc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
end;
$function$;

revoke all on function public.get_creator_payout_moderation_queue(integer) from public;
revoke all on function public.get_creator_payout_moderation_queue(integer) from anon;
grant execute on function public.get_creator_payout_moderation_queue(integer) to authenticated;
grant execute on function public.get_creator_payout_moderation_queue(integer) to service_role;
