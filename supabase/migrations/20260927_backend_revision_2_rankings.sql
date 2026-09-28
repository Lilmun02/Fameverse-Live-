begin;

update public.app_release_state
set
  backend_revision = greatest(backend_revision, 2),
  release_label = 'sep27-native-backend-2',
  manifest = jsonb_set(
    jsonb_set(
      manifest,
      '{features,discover_rankings}',
      'true'::jsonb,
      true
    ),
    '{features,backend_updater}',
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
  'Discover rankings and visible system status are now part of the native backend contract.',
  'sep27-native-backend-2',
  null,
  array[
    'Discover rankings added for Top Tappers, Top Gifters and Creators',
    'Eligible FameTaps power tap rankings instead of raw spam',
    'Fame Algo and backend updater status can be inspected in Settings',
    'Backend updater revision advanced to 2'
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
