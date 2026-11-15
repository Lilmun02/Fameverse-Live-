-- Build 48 security regression repair (REVIEW ONLY: not applied to production).
-- Root cause: prior helper granted restricted rights when no policy_acceptances row existed.
-- Keep the approved 7-day notice + 3-day grace and accepted permissions unchanged.
-- Declined, expired, absent, and unauthenticated records must fail closed.
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
        and (
          p.decision = 'accepted'
          or (
            p.decision = 'unsigned'
            and now() < p.notice_started_at + interval '10 days'
          )
        )
    );
$function$;
