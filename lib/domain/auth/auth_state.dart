/// Signed-in Cognito session tokens.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.idToken,
    required this.accessToken,
    required this.refreshToken,
    this.displayName,
  });

  final String userId;
  final String idToken;
  final String accessToken;
  final String refreshToken;
  final String? displayName;
}

enum AuthStatus {
  unknown,
  guest,
  social,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.guestUserId,
    this.session,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? guestUserId;
  final AuthSession? session;
  final String? errorMessage;

  factory AuthState.guest(String guestUserId) {
    return AuthState(
      status: AuthStatus.guest,
      guestUserId: guestUserId,
    );
  }

  factory AuthState.social(AuthSession session) {
    return AuthState(
      status: AuthStatus.social,
      session: session,
    );
  }

  bool get isGuest => status == AuthStatus.guest;

  bool get isSignedIn => status == AuthStatus.social && session != null;

  bool get isReady => status == AuthStatus.guest || isSignedIn;

  String? get userId => isSignedIn ? session?.userId : guestUserId;

  String get accountLabel {
    if (isSignedIn) {
      return session?.displayName ?? 'Signed in';
    }
    return 'Guest';
  }

  AuthState copyWith({
    AuthStatus? status,
    String? guestUserId,
    AuthSession? session,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      guestUserId: guestUserId ?? this.guestUserId,
      session: clearSession ? null : (session ?? this.session),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
