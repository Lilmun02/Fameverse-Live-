-- Build 47 UTC-boundary regression, read-only.
-- Run SELECT-only against PostgreSQL; no tables, auth, payments or wallets are changed.
-- Expected result: cases_checked = 5, all_pass = true, failed_cases = NULL.
with cases(label, at_utc, expected_daily, expected_weekly) as (
  values
    ('Sunday boundary', '2026-11-08 00:00+00'::timestamptz, '2026-11-08 00:00+00'::timestamptz, '2026-11-08 00:00+00'::timestamptz),
    ('Saturday before reset', '2026-11-07 23:59:59+00'::timestamptz, '2026-11-07 00:00+00'::timestamptz, '2026-11-01 00:00+00'::timestamptz),
    ('Monday after reset', '2026-11-09 00:00+00'::timestamptz, '2026-11-09 00:00+00'::timestamptz, '2026-11-08 00:00+00'::timestamptz),
    ('US daylight-saving switch', '2026-03-08 07:00+00'::timestamptz, '2026-03-08 00:00+00'::timestamptz, '2026-03-08 00:00+00'::timestamptz),
    ('Year rollover', '2026-01-01 00:00+00'::timestamptz, '2026-01-01 00:00+00'::timestamptz, '2025-12-28 00:00+00'::timestamptz)
), checks as (
  select label,
    (date_trunc('day', at_utc at time zone 'UTC') at time zone 'UTC') = expected_daily as daily_ok,
    ((date_trunc('week', (at_utc at time zone 'UTC') + interval '1 day') - interval '1 day') at time zone 'UTC') = expected_weekly as weekly_ok
  from cases
)
select count(*) as cases_checked,
  bool_and(daily_ok and weekly_ok) as all_pass,
  array_agg(label) filter (where not (daily_ok and weekly_ok)) as failed_cases
from checks;
