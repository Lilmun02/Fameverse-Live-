begin;

alter table public.app_release_state
  add column if not exists manifest jsonb not null default '{}'::jsonb;

insert into public.app_release_state (
  channel,
  backend_revision,
  release_label,
  manifest,
  updated_at
)
values
  (
    'internal',
    1,
    'sep27-native-backend-1',
    jsonb_build_object(
      'features', jsonb_build_object(
        'app_enabled', true,
        'stories', true,
        'first_verse', true,
        'coin_exchange', true,
        'creator_studio', true,
        'owner_control_panel', true,
        'fame_algo_v1', true,
        'backend_updater', true
      ),
      'labels', jsonb_build_object(
        'home', 'Home',
        'discover', 'Discover',
        'live', 'Live',
        'profile', 'Profile'
      ),
      'limits', jsonb_build_object(
        'story_video_seconds', 30,
        'profile_bio_chars', 160,
        'creator_moderators', 3
      ),
      'economy', jsonb_build_object(
        'coins_per_usd', 100,
        'creator_share_bps', 7000,
        'platform_share_bps', 3000,
        'referrer_reward_coins', 100,
        'referred_reward_coins', 50,
        'promo_creator_earnings', false
      ),
      'ranking', jsonb_build_object(
        'fame_algo_version', 'v1'
      )
    ),
    now()
  ),
  (
    'beta',
    1,
    'sep27-native-backend-1',
    jsonb_build_object(
      'features', jsonb_build_object(
        'app_enabled', true,
        'stories', true,
        'first_verse', true,
        'coin_exchange', true,
        'creator_studio', true,
        'owner_control_panel', false,
        'fame_algo_v1', true,
        'backend_updater', true
      ),
      'labels', jsonb_build_object(
        'home', 'Home',
        'discover', 'Discover',
        'live', 'Live',
        'profile', 'Profile'
      ),
      'limits', jsonb_build_object(
        'story_video_seconds', 30,
        'profile_bio_chars', 160,
        'creator_moderators', 3
      ),
      'economy', jsonb_build_object(
        'coins_per_usd', 100,
        'creator_share_bps', 7000,
        'platform_share_bps', 3000,
        'referrer_reward_coins', 100,
        'referred_reward_coins', 50,
        'promo_creator_earnings', false
      ),
      'ranking', jsonb_build_object(
        'fame_algo_version', 'v1'
      )
    ),
    now()
  ),
  (
    'production',
    1,
    'sep27-native-backend-1',
    jsonb_build_object(
      'features', jsonb_build_object(
        'app_enabled', true,
        'stories', true,
        'first_verse', false,
        'coin_exchange', true,
        'creator_studio', true,
        'owner_control_panel', false,
        'fame_algo_v1', true,
        'backend_updater', true
      ),
      'labels', jsonb_build_object(
        'home', 'Home',
        'discover', 'Discover',
        'live', 'Live',
        'profile', 'Profile'
      ),
      'limits', jsonb_build_object(
        'story_video_seconds', 30,
        'profile_bio_chars', 160,
        'creator_moderators', 3
      ),
      'economy', jsonb_build_object(
        'coins_per_usd', 100,
        'creator_share_bps', 7000,
        'platform_share_bps', 3000,
        'referrer_reward_coins', 100,
        'referred_reward_coins', 50,
        'promo_creator_earnings', false
      ),
      'ranking', jsonb_build_object(
        'fame_algo_version', 'v1'
      )
    ),
    now()
  )
on conflict (channel) do update set
  backend_revision = greatest(public.app_release_state.backend_revision, excluded.backend_revision),
  release_label = excluded.release_label,
  manifest = excluded.manifest,
  updated_at = excluded.updated_at;

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
  'The Sep 27 backend contract is synced before the app opens.',
  'sep27-native-backend-1',
  null,
  array[
    'Fame Algo v1 ranking is active',
    'First Verse missions and referral rewards are server-authoritative',
    'Promo and referral Fame Coins cannot create creator cash earnings',
    'Creator Stories, Coin Exchange and payout services are synced'
  ]::text[],
  true,
  true,
  now()
)
on conflict (channel, version_label, update_type)
do update set
  title = excluded.title,
  summary = excluded.summary,
  build_number = excluded.build_number,
  changelog = excluded.changelog,
  active = excluded.active,
  requires_acknowledgement = excluded.requires_acknowledgement,
  published_at = excluded.published_at;

comment on column public.app_release_state.manifest is
  'Server-driven manifest consumed by supported native Fameverse builds at startup. It cannot add capabilities absent from the installed binary.';

commit;
