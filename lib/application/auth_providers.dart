import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracelet/data/auth/cognito_auth_service.dart';
import 'package:tracelet/data/auth/cognito_hosted_ui_auth.dart';
import 'package:tracelet/data/auth/guest_auth_context.dart';
import 'package:tracelet/data/session/tracelet_session.dart';
import 'package:tracelet/domain/auth/api_auth_context.dart';
import 'package:tracelet/domain/auth/auth_state.dart';
import 'package:tracelet/domain/auth/social_provider.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  CognitoAuthService get _cognito => ref.read(cognitoAuthServiceProvider);
  GuestAuthContext get _guest => ref.read(guestAuthContextProvider);
  CognitoHostedUiAuth get _hostedUi => ref.read(cognitoHostedUiAuthProvider);

  @override
  Future<AuthState> build() async {
    await ref.watch(sharedPreferencesProvider.future);
    await ref.read(guestAuthContextProvider).ensureReady();

    final restored = await _cognito.restoreSocialSession();
    if (restored != null && restored.isSignedIn) {
      return restored;
    }

    return AuthState.guest(_guest.userId!);
  }

  Future<void> signInWithSocial(SocialProvider provider) async {
    final current = state.value ?? const AuthState();
    state = AsyncValue.data(current.copyWith(clearError: true));

    try {
      final signedIn = await _hostedUi.signIn(provider);
      if (signedIn.isSignedIn) {
        state = AsyncValue.data(signedIn);
        return;
      }

      state = AsyncValue.data(
        AuthState.guest(
          _guest.userId ?? current.guestUserId ?? '',
        ).copyWith(errorMessage: signedIn.errorMessage),
      );
    } catch (error) {
      state = AsyncValue.data(
        AuthState.guest(
          _guest.userId ?? current.guestUserId ?? '',
        ).copyWith(errorMessage: error.toString()),
      );
    }
  }

  Future<void> revertToGuest() async {
    await _cognito.signOut();
    await _guest.ensureReady();
    state = AsyncValue.data(AuthState.guest(_guest.userId!));
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

final guestAuthContextProvider = Provider<GuestAuthContext>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return GuestAuthContext(TraceletSession(prefs));
});

final cognitoAuthServiceProvider = Provider<CognitoAuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return CognitoAuthService(prefs);
});

final cognitoHostedUiAuthProvider = Provider<CognitoHostedUiAuth>((ref) {
  return CognitoHostedUiAuth(
    authService: ref.watch(cognitoAuthServiceProvider),
  );
});

final apiAuthContextProvider = Provider<ApiAuthContext>((ref) {
  final auth = ref.watch(authNotifierProvider).value;
  if (auth?.isSignedIn == true) {
    return ref.watch(cognitoAuthServiceProvider);
  }
  return ref.watch(guestAuthContextProvider);
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final authSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authNotifierProvider).value?.session;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).value?.isSignedIn ?? false;
});

final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).value?.isGuest ?? true;
});
