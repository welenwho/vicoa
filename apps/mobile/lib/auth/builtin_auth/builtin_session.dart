import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/base_auth_user_provider.dart';
import '/custom_code/server/server_config.dart';

const _kToken = 'vicoa_builtin_access_token';
const _kExpiresAt = 'vicoa_builtin_expires_at';
const _kUserId = 'vicoa_builtin_user_id';
const _kEmail = 'vicoa_builtin_email';
const _kDisplayName = 'vicoa_builtin_display_name';

enum BuiltinAuthEvent { signedIn, signedOut }

class BuiltinAuthException implements Exception {
  BuiltinAuthException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// A signed-in user from the backend's built-in email/password provider.
class BuiltinAuthUser extends BaseAuthUser {
  BuiltinAuthUser._(this._info, {required this.loggedIn});

  factory BuiltinAuthUser.signedOut() =>
      BuiltinAuthUser._(const AuthUserInfo(), loggedIn: false);

  factory BuiltinAuthUser.signedIn({
    required String id,
    required String email,
    String? displayName,
  }) =>
      BuiltinAuthUser._(
        AuthUserInfo(uid: id, email: email, displayName: displayName),
        loggedIn: true,
      );

  final AuthUserInfo _info;

  @override
  final bool loggedIn;

  @override
  bool get emailVerified => loggedIn;

  @override
  AuthUserInfo get authUserInfo => _info;

  @override
  Future? delete() async {}

  @override
  Future? updateEmail(String email) async {}

  @override
  Future? updatePassword(String newPassword) async {}

  @override
  Future? sendEmailVerification() async {}
}

/// Persists the built-in provider's session token and publishes auth changes.
///
/// The token is the same RS256 JWT the web dashboard stores in its cookie.
/// The backend verifies it on REST and, when offered as the `vicoa-supabase`
/// WebSocket subprotocol, on `/ws` as well.
class BuiltinSession {
  BuiltinSession._();

  static final BuiltinSession instance = BuiltinSession._();

  final _users = StreamController<BaseAuthUser>.broadcast();
  final _events = StreamController<BuiltinAuthEvent>.broadcast();

  BaseAuthUser current = BuiltinAuthUser.signedOut();
  String? _token;
  DateTime? _expiresAt;

  Stream<BaseAuthUser> get userStream {
    return Stream<BaseAuthUser>.multi((listener) {
      listener.add(current);
      final sub = _users.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = sub.cancel;
    });
  }

  Stream<BuiltinAuthEvent> get authEvents => _events.stream;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _expiresAt = DateTime.tryParse(prefs.getString(_kExpiresAt) ?? '');
    final id = prefs.getString(_kUserId) ?? '';
    final email = prefs.getString(_kEmail) ?? '';
    final name = prefs.getString(_kDisplayName);
    if (validToken() == null || id.isEmpty) {
      await _clearStored();
      current = BuiltinAuthUser.signedOut();
      currentUser = current;
      return;
    }
    current = BuiltinAuthUser.signedIn(
      id: id,
      email: email,
      displayName: name,
    );
    currentUser = current;
  }

  /// A non-expired access token, or null when the user must sign in again.
  String? validToken() {
    final token = _token;
    if (token == null || token.isEmpty) return null;
    final expiresAt = _expiresAt;
    if (expiresAt != null &&
        !expiresAt.isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      return null;
    }
    return token;
  }

  Future<BuiltinAuthUser> signIn(String email, String password) {
    return _postSession('/sign-in', {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<BuiltinAuthUser> signUp(
    String email,
    String password, {
    String? displayName,
  }) {
    final name = displayName?.trim() ?? '';
    return _postSession('/sign-up', {
      'email': email.trim(),
      'password': password,
      'display_name': name.isEmpty ? null : name,
    });
  }

  Future<String> forgotPassword(String email) async {
    final response = await _post('/forgot-password', {'email': email.trim()});
    return _message(response);
  }

  Future<void> signOut() async {
    await _clearStored();
    _emit(BuiltinAuthUser.signedOut(), BuiltinAuthEvent.signedOut);
  }

  Future<BuiltinAuthUser> _postSession(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _post(path, body);
    final payload = _decode(response);
    final userMap = payload['user'];
    if (userMap is! Map) {
      throw BuiltinAuthException('The server returned an unexpected session.');
    }
    final id = userMap['id']?.toString() ?? '';
    final email = userMap['email']?.toString() ?? '';
    final name = userMap['display_name']?.toString();
    final token = payload['access_token']?.toString() ?? '';
    if (id.isEmpty || token.isEmpty) {
      throw BuiltinAuthException('The server returned an unexpected session.');
    }
    final expiresAt = DateTime.tryParse(payload['expires_at']?.toString() ?? '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, id);
    await prefs.setString(_kEmail, email);
    if (name == null || name.isEmpty) {
      await prefs.remove(_kDisplayName);
    } else {
      await prefs.setString(_kDisplayName, name);
    }
    if (expiresAt == null) {
      await prefs.remove(_kExpiresAt);
    } else {
      await prefs.setString(_kExpiresAt, expiresAt.toIso8601String());
    }
    _token = token;
    _expiresAt = expiresAt;
    final user = BuiltinAuthUser.signedIn(
      id: id,
      email: email,
      displayName: name,
    );
    _emit(user, BuiltinAuthEvent.signedIn);
    return user;
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final base = ServerConfig.instance.apiBaseUrl;
    if (base.isEmpty) {
      throw BuiltinAuthException('Set a server address first.');
    }
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$base/api/v1/auth/builtin$path'),
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception {
      throw BuiltinAuthException(
        'Could not reach the server. Check the address and that the phone can reach it.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BuiltinAuthException(
        _detail(response),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  void _emit(BaseAuthUser user, BuiltinAuthEvent event) {
    current = user;
    currentUser = user;
    if (!_users.isClosed) _users.add(user);
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> _clearStored() async {
    _token = null;
    _expiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kExpiresAt);
    await prefs.remove(_kUserId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kDisplayName);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw BuiltinAuthException('The server returned an unexpected session.');
  }

  String _message(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return 'If that address has an account, a code is on its way.';
  }

  String _detail(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        return detail.toString();
      }
    } catch (_) {}
    if (response.statusCode == 401) return 'Incorrect email or password.';
    return 'Request failed (${response.statusCode}).';
  }
}
