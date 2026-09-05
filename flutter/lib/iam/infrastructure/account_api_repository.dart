import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/account_models.dart';
import '../domain/account_repository.dart';

final class AccountApiRepository implements AccountRepository {
  const AccountApiRepository(this._api);
  final ApiClient _api;

  AccountProfile _profile(Map<String, dynamic> json) => AccountProfile(
    id: jsonInt(json['id']),
    fullName: jsonString(json['fullName']),
    email: jsonString(json['email']),
    accessProfileId: json['accessProfileId'] is num
        ? jsonInt(json['accessProfileId'])
        : null,
    accessProfileName: jsonString(json['accessProfileName'], 'USER'),
    status: jsonString(json['status'], 'ACTIVE'),
    createdAt: DateTime.tryParse(jsonString(json['createdAt'])),
  );

  @override
  Future<AccountProfile> currentProfile() async =>
      _profile(jsonObject(await _api.get('/users/me')));

  @override
  Future<List<AccountProfile>> managedUsers() async =>
      jsonList(await _api.get('/users')).map(_profile).toList(growable: false);

  @override
  Future<List<AccessProfile>> accessProfiles() async =>
      jsonList(await _api.get('/access-profiles'))
          .map(
            (json) => AccessProfile(
              id: jsonInt(json['id']),
              name: jsonString(json['name']),
              description: jsonString(json['description']),
              permissions: json['permissions'] is List
                  ? (json['permissions'] as List)
                        .map((item) => item.toString())
                        .toList(growable: false)
                  : const [],
            ),
          )
          .toList(growable: false);

  @override
  Future<void> updateProfile(String fullName, String email) async {
    await _api.put('/users/me', body: {'fullName': fullName, 'email': email});
  }

  @override
  Future<void> assignAccessProfile(int userId, int profileId) => _api.patchVoid(
    '/users/$userId/access-profile',
    body: {'accessProfileId': profileId},
  );

  @override
  Future<void> deleteCurrentAccount() => _api.deleteVoid('/users/me');

  @override
  Future<void> requestPasswordRecovery(String email) =>
      _api.postVoid('/auth/recover-password', body: {'email': email});
}
