begin;

-- Additive covering indexes for the new Sep 27 foreign keys. Nothing existing
-- is removed during beta.
create index if not exists beta_program_members_invited_by_idx
  on public.beta_program_members(invited_by)
  where invited_by is not null;
create index if not exists beta_referrals_referrer_idx
  on public.beta_referrals(referrer_user_id);
create index if not exists coin_funding_ledger_gift_event_idx
  on public.coin_funding_ledger(gift_event_id)
  where gift_event_id is not null;
create index if not exists coin_funding_ledger_user_created_idx
  on public.coin_funding_ledger(user_id, created_at desc);

-- Preserve existing RLS semantics while making auth.uid() an initplan instead
-- of recalculating it once per row.
drop policy if exists "authenticated testers can submit own feedback"
  on public.beta_feedback;
create policy "authenticated testers can submit own feedback"
on public.beta_feedback for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "testers can read own feedback"
  on public.beta_feedback;
create policy "testers can read own feedback"
on public.beta_feedback for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "users can read own recharge orders"
  on public.coin_recharge_orders;
create policy "users can read own recharge orders"
on public.coin_recharge_orders for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "creator moderator assignments are visible to participants"
  on public.creator_moderators;
create policy "creator moderator assignments are visible to participants"
on public.creator_moderators for select to authenticated
using (
  (select auth.uid()) = creator_user_id
  or (select auth.uid()) = moderator_user_id
);

drop policy if exists "owner can read cash reward reserve"
  on public.cash_reward_reserve;
create policy "owner can read cash reward reserve"
on public.cash_reward_reserve for select to authenticated
using (
  exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid())
      and r.role = 'owner'
  )
);

drop policy if exists "owner can read cash reward ledger"
  on public.cash_reward_reserve_ledger;
create policy "owner can read cash reward ledger"
on public.cash_reward_reserve_ledger for select to authenticated
using (
  exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid())
      and r.role = 'owner'
  )
);

drop policy if exists "staff can read own cash reward permission"
  on public.staff_cash_reward_permissions;
create policy "staff can read own cash reward permission"
on public.staff_cash_reward_permissions for select to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid())
      and r.role = 'owner'
  )
);

drop policy if exists "creator can read own gift share accruals"
  on public.creator_gift_share_accruals;
create policy "creator can read own gift share accruals"
on public.creator_gift_share_accruals for select to authenticated
using (
  creator_user_id = (select auth.uid())
  or exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid())
      and r.role = 'owner'
  )
);

drop policy if exists "creator can read own fractional earnings"
  on public.creator_earnings_fractional;
create policy "creator can read own fractional earnings"
on public.creator_earnings_fractional for select to authenticated
using (
  creator_user_id = (select auth.uid())
  or exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid())
      and r.role = 'owner'
  )
);

commit;
