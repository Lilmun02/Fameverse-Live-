-- Build 48 security regression repair (REVIEW ONLY: not applied to production).
-- Root cause: prior helper granted restricted rights when no policy_acceptances row existed.
-- Notice (7 days) and grace (3 days) remain for reminders/support deadlines.
-- Owner requirement: unsigned status never grants restricted features.
-- Declined, unsigned, absent, and unauthenticated records fail closed.
-- No table, wallet, live room, Stream token or signing workflow changes.
create or replace function public.fv_policy_allows_restricted()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $function$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.policy_acceptances as p
      where p.user_id = (select auth.uid())
        and p.policy_version = '2026-10'
        and p.decision = 'accepted'
    );
$function$;
