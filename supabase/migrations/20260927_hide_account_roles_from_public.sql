begin;

-- Owner/admin infrastructure must not be enumerable by ordinary users.
-- The native app only needs to read the signed-in user's own role. Service role
-- and SECURITY DEFINER backend functions continue to operate with their normal
-- privileges.
drop policy if exists "account roles are publicly readable" on public.account_roles;

drop policy if exists "users can read own account role" on public.account_roles;
create policy "users can read own account role"
on public.account_roles
for select
to authenticated
using (user_id = (select auth.uid()));

commit;
