-- Build 16's internal startup notice must never surface in later native candidates.
-- The current product candidate is physically tested from TestFlight, so stale
-- backend notices are retired rather than replayed on every launch.
update public.app_update_notices
set active = false
where channel = 'internal'
  and build_number = 16
  and active = true;
