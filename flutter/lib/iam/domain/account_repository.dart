import 'account_models.dart';

abstract interface class AccountRepository {
  Future<AccountProfile> currentProfile();
  Future<List<AccountProfile>> managedUsers();
  Future<List<AccessProfile>> accessProfiles();
  Future<void> updateProfile(String fullName, String email);
  Future<void> assignAccessProfile(int userId, int profileId);
  Future<void> deleteCurrentAccount();
  Future<void> requestPasswordRecovery(String email);
}
