import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../../shared/infrastructure/storage/token_store.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

enum AuthStatus { checking, unauthenticated, authenticating, authenticated }

final class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._tokenStore);

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  AuthStatus status = AuthStatus.checking;
  AuthenticatedUser? user;
  AppFailure? failure;
  String? notice;

  bool get isBusy => status == AuthStatus.authenticating;

  Future<void> initialize() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await _repository.currentUser();
      status = AuthStatus.authenticated;
    } on AppFailure catch (error) {
      failure = error;
      if (error.kind == FailureKind.unauthorized) await _tokenStore.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) =>
      _authenticate(() => _repository.signIn(email: email, password: password));

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) => _authenticate(
    () => _repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
    ),
  );

  Future<bool> recoverPassword(String email) async {
    _startRequest();
    try {
      await _repository.recoverPassword(email);
      status = AuthStatus.unauthenticated;
      notice = 'recoverySent';
      notifyListeners();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    _startRequest();
    try {
      await _repository.resetPassword(token: token, password: password);
      status = AuthStatus.unauthenticated;
      notice = 'passwordResetSuccess';
      notifyListeners();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } on AppFailure {
      // Local sign-out must still complete if the server is unavailable.
    } finally {
      await _tokenStore.clear();
      user = null;
      failure = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void clearFeedback() {
    failure = null;
    notice = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AuthSession> Function() request) async {
    _startRequest();
    try {
      final session = await request();
      await _tokenStore.write(session.token);
      user = session.user;
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  void _startRequest() {
    status = AuthStatus.authenticating;
    failure = null;
    notice = null;
    notifyListeners();
  }
}
