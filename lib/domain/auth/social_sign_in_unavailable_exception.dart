import 'package:tracelet/domain/auth/auth_state.dart';
import 'package:tracelet/domain/auth/social_provider.dart';

/// Thrown when hosted UI / federated sign-in is not configured in Cognito.
class SocialSignInUnavailableException implements Exception {
  SocialSignInUnavailableException(this.provider);

  final SocialProvider provider;

  @override
  String toString() =>
      'SocialSignInUnavailableException: ${provider.name} is not configured';
}
