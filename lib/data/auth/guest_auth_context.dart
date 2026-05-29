import 'package:tracelet/data/session/tracelet_session.dart';
import 'package:tracelet/domain/auth/api_auth_context.dart';

/// Local anonymous identity used until the user signs in with Google or Apple.
class GuestAuthContext implements ApiAuthContext {
  GuestAuthContext(this._session);

  final TraceletSession _session;
  String? _userId;

  Future<void> ensureReady() async {
    _userId ??= await _session.ensureUserId();
  }

  @override
  String? get userId => _userId ?? _session.userIdOrNull;

  @override
  Future<String?> bearerToken() async => null;
}
