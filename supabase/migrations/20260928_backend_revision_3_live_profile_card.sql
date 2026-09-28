begin;

update public.app_release_state
set
  backend_revision = greatest(backend_revision, 3),
  release_label = 'sep28-native-backend-3',
  manifest = jsonb_set(
    coalesce(manifest, '{}'::jsonb),
    '{features,live_profile_card}',
    'true'::jsonb,
    true
  ),
  updated_at = now()
where channel in ('internal', 'beta', 'production');

update public.app_update_notices
set active = false
where channel = 'internal';

insert into public.app_update_notices (
  channel,
  update_type,
  title,
  summary,
  version_label,
  build_number,
  changelog,
  active,
  requires_acknowledgement,
  published_at
)
values (
  'internal',
  'backend',
  'Fameverse backend updated',
  'Live identity, rankings, and system-status contracts were refreshed for the replacement candidate.',
  'sep28-native-backend-3',
  null,
  array[
    'Live profile cards now use server-authoritative social, FameTap, gifting, and relationship data',
    'Discover rankings remain server-authoritative',
    'Fame Algo and backend update status remain visible in Settings'
  ]::text[],
  true,
  true,
  now()
)
on conflict (channel, version_label, update_type)
do update set
  title = excluded.title,
  summary = excluded.summary,
  changelog = excluded.changelog,
  active = excluded.active,
  requires_acknowledgement = excluded.requires_acknowledgement,
  published_at = excluded.published_at;

commit;
