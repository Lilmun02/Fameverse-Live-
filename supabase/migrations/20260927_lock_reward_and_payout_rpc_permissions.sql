-- Lock exposed SECURITY DEFINER money/control RPCs to signed-in callers only.
-- Each privileged function still performs its own owner/role checks internally.

revoke all on function public._apply_creator_gift_share(uuid, text) from public, anon, authenticated;

revoke all on function public.owner_allocate_reward_reserve(bigint, text) from public, anon, authenticated;
grant execute on function public.owner_allocate_reward_reserve(bigint, text) to authenticated;

revoke all on function public.owner_set_staff_cash_reward(uuid, boolean, bigint) from public, anon, authenticated;
grant execute on function public.owner_set_staff_cash_reward(uuid, boolean, bigint) to authenticated;

revoke all on function public.get_my_cash_reward_permission() from public, anon, authenticated;
grant execute on function public.get_my_cash_reward_permission() to authenticated;

revoke all on function public.get_owner_reward_control_summary() from public, anon, authenticated;
grant execute on function public.get_owner_reward_control_summary() to authenticated;

revoke all on function public.owner_publish_update_notice(text, text, text, text[], boolean) from public, anon, authenticated;
grant execute on function public.owner_publish_update_notice(text, text, text, text[], boolean) to authenticated;

revoke all on function public.record_beta_gift(uuid, text, integer) from public, anon, authenticated;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;

revoke all on function public.refill_beta_wallet(integer) from public, anon, authenticated;
grant execute on function public.refill_beta_wallet(integer) to authenticated;

revoke all on function public.begin_creator_payout_processing(uuid) from public, anon, authenticated;
grant execute on function public.begin_creator_payout_processing(uuid) to authenticated;

revoke all on function public.get_creator_payout_moderation_queue(integer) from public, anon, authenticated;
grant execute on function public.get_creator_payout_moderation_queue(integer) to authenticated;

revoke all on function public.get_creator_verification_moderation_queue(integer) from public, anon, authenticated;
grant execute on function public.get_creator_verification_moderation_queue(integer) to authenticated;

revoke all on function public.review_creator_payout(uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.review_creator_payout(uuid, text, text, text) to authenticated;

revoke all on function public.review_creator_verification(uuid, text, text) from public, anon, authenticated;
grant execute on function public.review_creator_verification(uuid, text, text) to authenticated;

revoke all on function public.request_creator_payout(bigint) from public, anon, authenticated;
grant execute on function public.request_creator_payout(bigint) to authenticated;

revoke all on function public.request_creator_verification() from public, anon, authenticated;
grant execute on function public.request_creator_verification() to authenticated;

revoke all on function public.set_creator_payout_method(text, text) from public, anon, authenticated;
grant execute on function public.set_creator_payout_method(text, text) to authenticated;

revoke all on function public.grant_owner_payout_test_earnings(bigint) from public, anon, authenticated;
grant execute on function public.grant_owner_payout_test_earnings(bigint) to authenticated;
