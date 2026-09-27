begin;

-- The Sep 27 features use SECURITY DEFINER RPCs so the API can preserve
-- server-authoritative money, beta and Story rules behind RLS. Postgres grants
-- EXECUTE to PUBLIC on new functions by default, so explicitly remove anon
-- access and keep internal money helpers service-role-only.

alter function public.compute_gifter_level(bigint)
  set search_path = public, pg_temp;

-- Internal money helpers: never callable from a client session.
revoke all on function public._ensure_fame_coin_wallet(uuid)
  from public, anon, authenticated;
revoke all on function public._credit_fame_coins(uuid,bigint,bigint,text,text)
  from public, anon, authenticated;
revoke all on function public._apply_creator_cash_coin_share(uuid,bigint)
  from public, anon, authenticated;
revoke all on function public.finalize_coin_recharge(uuid,text,text,integer,text)
  from public, anon, authenticated;

grant execute on function public._ensure_fame_coin_wallet(uuid) to service_role;
grant execute on function public._credit_fame_coins(uuid,bigint,bigint,text,text) to service_role;
grant execute on function public._apply_creator_cash_coin_share(uuid,bigint) to service_role;
grant execute on function public.finalize_coin_recharge(uuid,text,text,integer,text) to service_role;

-- Authenticated product RPCs. Each mutating function still enforces auth.uid(),
-- ownership and/or owner/admin role rules inside the function body.
revoke all on function public.get_beta_program_status()
  from public, anon, authenticated;
revoke all on function public.record_beta_test_mission(text)
  from public, anon, authenticated;
revoke all on function public.enroll_beta_tester(uuid)
  from public, anon, authenticated;

revoke all on function public.get_fame_coin_balance()
  from public, anon, authenticated;
revoke all on function public.exchange_creator_earnings_for_coins(bigint,text)
  from public, anon, authenticated;
revoke all on function public.get_creator_coin_exchange_history(integer)
  from public, anon, authenticated;
revoke all on function public.ensure_beta_referral_code()
  from public, anon, authenticated;
revoke all on function public.qualify_beta_referral(text)
  from public, anon, authenticated;
revoke all on function public.get_beta_referral_summary()
  from public, anon, authenticated;

revoke all on function public.get_fameverse_gift_catalog()
  from public, anon, authenticated;
revoke all on function public.send_fameverse_gift(uuid,text,integer)
  from public, anon, authenticated;
revoke all on function public.record_beta_gift(uuid,text,integer)
  from public, anon, authenticated;
revoke all on function public.refill_beta_wallet(integer)
  from public, anon, authenticated;

revoke all on function public.create_creator_story(text,text,text)
  from public, anon, authenticated;
revoke all on function public.list_active_creator_stories()
  from public, anon, authenticated;
revoke all on function public.record_creator_story_view(uuid)
  from public, anon, authenticated;
revoke all on function public.delete_creator_story(uuid)
  from public, anon, authenticated;
revoke all on function public.get_my_active_story_summary()
  from public, anon, authenticated;

revoke all on function public.get_recommended_creators_v2(uuid,integer)
  from public, anon, authenticated;
revoke all on function public.get_active_live_rooms_v2(uuid,timestamptz,integer)
  from public, anon, authenticated;

-- Existing creator/recharge RPCs surfaced by the database linter are also
-- client-authenticated only; their internal checks remain authoritative.
revoke all on function public.get_coin_recharge_packs()
  from public, anon, authenticated;
revoke all on function public.set_creator_moderator(uuid,boolean)
  from public, anon, authenticated;

grant execute on function public.get_beta_program_status() to authenticated;
grant execute on function public.record_beta_test_mission(text) to authenticated;
grant execute on function public.enroll_beta_tester(uuid) to authenticated;

grant execute on function public.get_fame_coin_balance() to authenticated;
grant execute on function public.exchange_creator_earnings_for_coins(bigint,text) to authenticated;
grant execute on function public.get_creator_coin_exchange_history(integer) to authenticated;
grant execute on function public.ensure_beta_referral_code() to authenticated;
grant execute on function public.qualify_beta_referral(text) to authenticated;
grant execute on function public.get_beta_referral_summary() to authenticated;

grant execute on function public.get_fameverse_gift_catalog() to authenticated;
grant execute on function public.send_fameverse_gift(uuid,text,integer) to authenticated;
grant execute on function public.record_beta_gift(uuid,text,integer) to authenticated;
grant execute on function public.refill_beta_wallet(integer) to authenticated;

grant execute on function public.create_creator_story(text,text,text) to authenticated;
grant execute on function public.list_active_creator_stories() to authenticated;
grant execute on function public.record_creator_story_view(uuid) to authenticated;
grant execute on function public.delete_creator_story(uuid) to authenticated;
grant execute on function public.get_my_active_story_summary() to authenticated;

grant execute on function public.get_recommended_creators_v2(uuid,integer) to authenticated;
grant execute on function public.get_active_live_rooms_v2(uuid,timestamptz,integer) to authenticated;
grant execute on function public.get_coin_recharge_packs() to authenticated;
grant execute on function public.set_creator_moderator(uuid,boolean) to authenticated;

commit;
