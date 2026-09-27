import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/fameverse_app.dart';
import 'data/fameverse_backend.dart';
import 'data/fameverse_live_backend.dart';
import 'data/startup_update_service.dart';

const _supabaseUrl = 'https://lwasmvzsagowgmiqssph.supabase.co';
const _supabasePublishableKey =
    'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC';
const _releaseChannel = String.fromEnvironment(
  'FAMEVERSE_RELEASE_CHANNEL',
  defaultValue: 'internal',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );
  final client = Supabase.instance.client;

  // Silent startup sync: cached backend state is installed immediately and the
  // remote revision check has a short timeout. There is no repeated update
  // theater; only a genuinely newer revision may produce a one-time notice.
  await FvStartupUpdateService(client).sync(channel: _releaseChannel);

  runApp(
    FameverseApp(
      backend: SupabaseFameverseBackend(client),
      liveBackend: SupabaseFameverseLiveBackend(client),
    ),
  );
}
