-- Build 32 payout privacy repair.
-- Creator payout state and payout-method reads are authenticated account data.

revoke all on function public.get_creator_payout_method() from public;
revoke all on function public.get_creator_payout_method() from anon;
grant execute on function public.get_creator_payout_method() to authenticated;
grant execute on function public.get_creator_payout_method() to service_role;

revoke all on function public.get_creator_payout_requests(integer) from public;
revoke all on function public.get_creator_payout_requests(integer) from anon;
grant execute on function public.get_creator_payout_requests(integer) to authenticated;
grant execute on function public.get_creator_payout_requests(integer) to service_role;

revoke all on function public.get_creator_payout_summary() from public;
revoke all on function public.get_creator_payout_summary() from anon;
grant execute on function public.get_creator_payout_summary() to authenticated;
grant execute on function public.get_creator_payout_summary() to service_role;
