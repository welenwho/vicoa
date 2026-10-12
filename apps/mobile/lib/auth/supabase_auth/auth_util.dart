import '/backend/supabase/supabase.dart';
import 'supabase_auth_manager.dart';
import 'supabase_user_provider.dart';

export 'supabase_auth_manager.dart';

final _authManager = SupabaseAuthManager();
SupabaseAuthManager get authManager => _authManager;

String get currentUserEmail => currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName => currentUser?.displayName ?? '';

String get currentUserPhoto => currentUser?.photoUrl ?? '';

String get currentPhoneNumber => currentUser?.phoneNumber ?? '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token.
///
/// Empty when Supabase was not initialized (built-in self-hosted auth). The
/// late stream is only touched after [SupaFlow.isInitialized] is true, so a
/// builtin-only launch never constructs a Supabase client.
String? _currentJwtToken;
Stream<String?> get jwtTokenStream {
  if (!SupaFlow.isInitialized) return const Stream<String?>.empty();
  return _supabaseJwtTokenStream;
}

late final Stream<String?> _supabaseJwtTokenStream =
    SupaFlow.client.auth.onAuthStateChange
        .map(
          (authState) => _currentJwtToken = authState.session?.accessToken,
        )
        .asBroadcastStream();
