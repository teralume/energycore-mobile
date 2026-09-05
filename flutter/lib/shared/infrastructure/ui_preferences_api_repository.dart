import '../domain/ui_preferences.dart';
import 'network/api_client.dart';
import 'network/json_readers.dart';

final class UiPreferencesApiRepository implements UiPreferencesRepository {
  const UiPreferencesApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<UiPreferences> current() async =>
      _preference(jsonObject(await _api.get('/users/me/ui-preferences')));

  @override
  Future<UiPreferences> save({
    required String language,
    required String theme,
  }) async => _preference(
    jsonObject(
      await _api.put(
        '/users/me/ui-preferences',
        body: {'language': language, 'theme': theme},
      ),
    ),
  );

  UiPreferences _preference(Map<String, dynamic> json) => UiPreferences(
    language: jsonString(json['language'], 'es').toLowerCase(),
    theme: jsonString(json['theme'], 'light').toLowerCase(),
  );
}
