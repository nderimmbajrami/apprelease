import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

part 'backend.g.dart';

/// Where the repositories read and write.
///
/// [Backend.local] keeps everything in memory — it powers the widget tests and
/// the demo. Tests override [backendProvider] with it.
enum Backend { local, supabase }

@Riverpod(keepAlive: true)
Backend backend(Ref ref) =>
    AppConfig.isSupabaseEnabled ? Backend.supabase : Backend.local;

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;
