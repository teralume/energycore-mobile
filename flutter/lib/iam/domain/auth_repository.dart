import 'auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AuthenticatedUser> currentUser();
  Future<void> recoverPassword(String email);
  Future<void> resetPassword({required String token, required String password});
  Future<void> signOut();
}
