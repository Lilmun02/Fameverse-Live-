-- Fameverse QA helper for payout sandbox testing.
-- Owner-only. This creates cleared test earnings for the signed-in owner so the $25 payout path can be exercised without inventing a production gift-to-cash conversion.

create or replace function public.grant_owner_payout_test_earnings(p_amount_cents bigint default 2500)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_total bigint;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.account_roles role_row
    where role_row.user_id = v_user and role_row.role = 'owner'
  ) then
    raise exception 'owner QA access required' using errcode = '42501';
  end if;

  if p_amount_cents <> 2500 then
    raise exception 'sandbox payout test credit is fixed at $25.00' using errcode = '22023';
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
    v_user,
    2500,
    'available',
    'qa_payout_test',
    'qa-payout-test:' || gen_random_uuid()::text,
    'Owner sandbox payout test credit',
    now()
  );

  select coalesce(sum(amount_cents) filter (where state in ('available', 'paid', 'reversed')), 0)::bigint
    into v_total
  from public.creator_earnings_ledger
  where creator_user_id = v_user;

  return v_total;
end;
$$;

revoke all on function public.grant_owner_payout_test_earnings(bigint) from public;
grant execute on function public.grant_owner_payout_test_earnings(bigint) to authenticated;
