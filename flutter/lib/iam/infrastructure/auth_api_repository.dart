import '../../shared/domain/app_failure.dart';
import '../../shared/infrastructure/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

final class AuthApiRepository implements AuthRepository {
  const AuthApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/sign-in',
      body: {'email': email.trim(), 'password': password},
    );
    return _session(response);
  }

  @override
  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/sign-up',
      body: {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    return _session(response);
  }

  @override
  Future<AuthenticatedUser> currentUser() async {
    final response = await _api.get('/auth/me');
    return _user(_json(response));
  }

  @override
  Future<void> recoverPassword(String email) =>
      _api.postVoid('/auth/recover-password', body: {'email': email.trim()});

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => _api.postVoid(
    '/auth/reset-password',
    body: {'token': token.trim(), 'password': password},
  );

  @override
  Future<void> signOut() => _api.postVoid('/auth/sign-out', body: const {});

  AuthSession _session(Object? response) {
    final json = _json(response);
    final token = json['token'];
    final user = json['user'];
    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      throw const AppFailure(
        'The authentication response is incomplete.',
        kind: FailureKind.server,
      );
    }
    return AuthSession(user: _user(user), token: token);
  }

  AuthenticatedUser _user(Map<String, dynamic> json) => AuthenticatedUser(
    id: (json['id'] as num).toInt(),
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    accessProfileId: (json['accessProfileId'] as num?)?.toInt(),
    accessProfileName: json['accessProfileName'] as String?,
    status: json['status'] as String? ?? 'ACTIVE',
  );

  Map<String, dynamic> _json(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const AppFailure(
      'The server returned an unexpected response.',
      kind: FailureKind.server,
    );
  }
}
