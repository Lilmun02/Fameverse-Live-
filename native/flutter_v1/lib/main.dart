import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/fameverse_app.dart';
import 'data/fameverse_backend.dart';

const _supabaseUrl = 'https://lwasmvzsagowgmiqssph.supabase.co';
const _supabasePublishableKey =
    'sb_publishable_Zukw53JQ0R_rMuxxC1eeRg_28_QavNC';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );
  runApp(
    FameverseApp(
      backend: SupabaseFameverseBackend(Supabase.instance.client),
    ),
  );
}
