/// Supplies Cognito credentials for backend HTTP calls.
abstract class ApiAuthContext {
  Future<String?> bearerToken();
  String? get userId;
}
