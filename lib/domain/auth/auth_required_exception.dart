/// Thrown when the API requires a Cognito JWT and none is available or valid.
class AuthRequiredException implements Exception {
  AuthRequiredException([this.message = 'Authentication required']);

  final String message;

  @override
  String toString() => 'AuthRequiredException: $message';
}
