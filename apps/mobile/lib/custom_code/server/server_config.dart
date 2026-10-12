import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kApiBase = 'vicoa_selfhost_api_base';
const _kWsUrl = 'vicoa_selfhost_ws_url';
const _kProvider = 'vicoa_selfhost_provider';
const _kAllowSignup = 'vicoa_selfhost_allow_signup';
const _kRequireEmailVerification = 'vicoa_selfhost_require_email_verification';
const _kSupabaseUrl = 'vicoa_selfhost_supabase_url';
const _kSupabaseAnonKey = 'vicoa_selfhost_supabase_anon_key';

/// A self-hosted deployment the app should talk to instead of Vicoa Cloud.
///
/// The published app bakes `api.vicoa.ai` in at build time. This store is the
/// runtime switch: the user types the backend address, we probe
/// `GET /api/v1/auth/config`, and every later REST/WebSocket call reads it.
class ServerConfig {
  ServerConfig._();

  static final ServerConfig instance = ServerConfig._();

  String apiBaseUrl = '';
  String wsUrl = '';
  String provider = '';
  bool allowSignup = true;
  bool requireEmailVerification = false;
  String supabaseUrl = '';
  String supabaseAnonKey = '';

  bool get isConfigured => apiBaseUrl.isNotEmpty;
  bool get isBuiltin => provider == 'builtin';
  bool get usesSupabase => provider == 'supabase';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    apiBaseUrl = prefs.getString(_kApiBase) ?? '';
    wsUrl = prefs.getString(_kWsUrl) ?? '';
    provider = prefs.getString(_kProvider) ?? '';
    allowSignup = prefs.getBool(_kAllowSignup) ?? true;
    requireEmailVerification =
        prefs.getBool(_kRequireEmailVerification) ?? false;
    supabaseUrl = prefs.getString(_kSupabaseUrl) ?? '';
    supabaseAnonKey = prefs.getString(_kSupabaseAnonKey) ?? '';
  }

  Future<void> save({
    required String apiBaseUrl,
    required String wsUrl,
    required String provider,
    required bool allowSignup,
    required bool requireEmailVerification,
    String supabaseUrl = '',
    String supabaseAnonKey = '',
  }) async {
    this.apiBaseUrl = apiBaseUrl;
    this.wsUrl = wsUrl;
    this.provider = provider;
    this.allowSignup = allowSignup;
    this.requireEmailVerification = requireEmailVerification;
    this.supabaseUrl = supabaseUrl;
    this.supabaseAnonKey = supabaseAnonKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiBase, apiBaseUrl);
    await prefs.setString(_kWsUrl, wsUrl);
    await prefs.setString(_kProvider, provider);
    await prefs.setBool(_kAllowSignup, allowSignup);
    await prefs.setBool(_kRequireEmailVerification, requireEmailVerification);
    await prefs.setString(_kSupabaseUrl, supabaseUrl);
    await prefs.setString(_kSupabaseAnonKey, supabaseAnonKey);
  }

  Future<void> clear() async {
    apiBaseUrl = '';
    wsUrl = '';
    provider = '';
    allowSignup = true;
    requireEmailVerification = false;
    supabaseUrl = '';
    supabaseAnonKey = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiBase);
    await prefs.remove(_kWsUrl);
    await prefs.remove(_kProvider);
    await prefs.remove(_kAllowSignup);
    await prefs.remove(_kRequireEmailVerification);
    await prefs.remove(_kSupabaseUrl);
    await prefs.remove(_kSupabaseAnonKey);
  }
}

/// What `GET /api/v1/auth/config` told us about a deployment.
class ServerProbe {
  const ServerProbe({
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.provider,
    required this.allowSignup,
    required this.requireEmailVerification,
  });

  final String apiBaseUrl;
  final String wsUrl;
  final String provider;
  final bool allowSignup;
  final bool requireEmailVerification;
}

class ServerProbeException implements Exception {
  ServerProbeException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Normalize a user-typed backend address.
///
/// Accepts `192.168.1.10:8000` as well as a full URL. Keeps an explicit path
/// so a reverse proxy mounted under a prefix still works. Returns null when
/// the text is not an http(s) URL with a host.
String? normalizeHttpBase(String raw) {
  var text = raw.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  var path = uri.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  if (path == '/') path = '';
  return _origin(uri, path: path);
}

/// Normalize a WebSocket address. An empty path becomes `/ws`.
String? normalizeWsUrl(String raw) {
  var text = raw.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return null;
  if (!text.contains('://')) {
    text = text.startsWith('https') ? text : 'ws://$text';
    if (text.startsWith('http://')) {
      text = 'ws://${text.substring('http://'.length)}';
    } else if (text.startsWith('https://')) {
      text = 'wss://${text.substring('https://'.length)}';
    }
  }
  if (text.startsWith('http://')) {
    text = 'ws://${text.substring('http://'.length)}';
  } else if (text.startsWith('https://')) {
    text = 'wss://${text.substring('https://'.length)}';
  }
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'ws' && uri.scheme != 'wss') return null;
  var path = uri.path;
  if (path.isEmpty || path == '/') path = '/ws';
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return _origin(uri, scheme: uri.scheme, path: path);
}

/// Derive the agent WebSocket from a backend base URL.
///
/// Self-host compose publishes REST on 8000 and the WebSocket on 8080. A URL
/// that already uses another port (a reverse proxy on 443) keeps that port
/// and only switches the scheme.
String deriveWsUrl(String apiBaseUrl) {
  final uri = Uri.parse(apiBaseUrl);
  final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final port = uri.hasPort && uri.port == 8000 ? 8080 : uri.port;
  return _origin(uri, scheme: scheme, port: port, path: '/ws');
}

String _host(Uri uri) {
  final host = uri.host;
  if (host.contains(':')) return '[$host]';
  return host;
}

String _origin(
  Uri uri, {
  String? scheme,
  int? port,
  String path = '',
}) {
  final resolvedScheme = scheme ?? uri.scheme;
  final resolvedPort = port ?? uri.port;
  final defaultPort = resolvedScheme == 'https' || resolvedScheme == 'wss'
      ? 443
      : 80;
  final explicit = uri.hasPort || port != null;
  final swappedTo8080 = port == 8080 && uri.port == 8000;
  final includePort = explicit &&
      resolvedPort != defaultPort &&
      (uri.hasPort || swappedTo8080 || port != null);
  final portPart = includePort ? ':$resolvedPort' : '';
  return '$resolvedScheme://${_host(uri)}$portPart$path';
}

/// Call the unauthenticated auth-config endpoint and return how to sign in.
Future<ServerProbe> probeServer(
  String apiRaw, {
  String wsRaw = '',
  Duration timeout = const Duration(seconds: 12),
}) async {
  final apiBase = normalizeHttpBase(apiRaw);
  if (apiBase == null) {
    throw ServerProbeException('invalid_url');
  }
  final ws = wsRaw.trim().isEmpty
      ? deriveWsUrl(apiBase)
      : normalizeWsUrl(wsRaw);
  if (ws == null) {
    throw ServerProbeException('invalid_ws');
  }

  final http.Response response;
  try {
    response = await http
        .get(
          Uri.parse('$apiBase/api/v1/auth/config'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(timeout);
  } on Exception {
    throw ServerProbeException('unreachable');
  }

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ServerProbeException('bad_response');
  }

  final dynamic decoded;
  try {
    decoded = jsonDecode(response.body);
  } on FormatException {
    throw ServerProbeException('bad_response');
  }
  if (decoded is! Map) {
    throw ServerProbeException('bad_response');
  }
  final provider = decoded['provider']?.toString() ?? '';
  if (provider != 'builtin' && provider != 'supabase') {
    throw ServerProbeException('bad_response');
  }
  return ServerProbe(
    apiBaseUrl: apiBase,
    wsUrl: ws,
    provider: provider,
    allowSignup: decoded['allow_signup'] != false,
    requireEmailVerification: decoded['require_email_verification'] == true,
  );
}
