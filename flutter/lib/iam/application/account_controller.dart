import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/account_models.dart';
import '../domain/account_repository.dart';

final class AccountController extends ChangeNotifier {
  AccountController(this._repository);
  final AccountRepository _repository;

  AccountProfile? profile;
  List<AccountProfile> managedUsers = const [];
  List<AccessProfile> accessProfiles = const [];
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      profile = await _repository.currentProfile();
      try {
        final result = await Future.wait([
          _repository.managedUsers(),
          _repository.accessProfiles(),
        ]);
        managedUsers = result[0] as List<AccountProfile>;
        accessProfiles = result[1] as List<AccessProfile>;
      } on AppFailure catch (error) {
        if (error.kind != FailureKind.unauthorized) rethrow;
        managedUsers = const [];
        accessProfiles = const [];
      }
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> mutate(Future<void> Function() action) async {
    if (isMutating) return false;
    isMutating = true;
    failure = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String name, String email) =>
      mutate(() => _repository.updateProfile(name, email));
  Future<bool> assignProfile(AccountProfile user, int profileId) =>
      mutate(() => _repository.assignAccessProfile(user.id, profileId));
  Future<bool> requestRecovery() async {
    final email = profile?.email;
    if (email == null) return false;
    return mutate(() => _repository.requestPasswordRecovery(email));
  }

  Future<bool> deleteAccount() => mutate(_repository.deleteCurrentAccount);
}
