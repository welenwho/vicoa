import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '/flutter_flow/flutter_flow_util.dart';

export 'database/database.dart';

// Build-time only: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
// No default here on purpose -- this is the open-source tree, so it must not
// point at Vicoa's own hosted project. Point these at your own Supabase
// project instead (see SELF_HOSTING.md).
//
// TODO(self-hosting): support pointing the mobile app at a self-hosted backend
// that uses the built-in auth provider (AUTH_PROVIDER=builtin), so Supabase is
// not required. Today auth is Supabase-only here and in auth/supabase_auth/;
// the web dashboard already supports both providers via lib/auth/.
const String _kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

class SupaFlow {
  SupaFlow._();

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  static bool _initialized = false;

  /// False when this process is talking to a built-in-auth self-hosted server
  /// and never called [initialize] with a Supabase project.
  static bool get isInitialized => _initialized;

  final _supabase = Supabase.instance.client;
  static SupabaseClient get client => instance._supabase;

  /// Starts Supabase when a project URL and anon key are available.
  ///
  /// A self-hosted server that uses `AUTH_PROVIDER=builtin` has neither, and
  /// must be allowed to launch. Pass [url] / [anonKey] from the in-app server
  /// settings; otherwise the build-time `--dart-define` values are used.
  /// Returns without throwing when nothing is configured.
  static Future<void> initialize({String? url, String? anonKey}) async {
    if (_initialized) return;
    final resolvedUrl = (url ?? _kSupabaseUrl).trim();
    final resolvedKey = (anonKey ?? _kSupabaseAnonKey).trim();
    if (resolvedUrl.isEmpty || resolvedKey.isEmpty) return;
    await Supabase.initialize(
        url: resolvedUrl,
        headers: {
          'X-Client-Info': 'flutterflow',
        },
        anonKey: resolvedKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          // Android strips URL fragments from deep links, so implicit flow
          // (#access_token=...) breaks OAuth callbacks there. PKCE uses
          // ?code= query params which Android preserves. iOS handles fragments
          // correctly in custom URL schemes so implicit keeps working there.
          // authFlowType: !kIsWeb && Platform.isAndroid
          //     ? AuthFlowType.pkce
          //     : AuthFlowType.implicit,
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
    _initialized = true;
  }
}
