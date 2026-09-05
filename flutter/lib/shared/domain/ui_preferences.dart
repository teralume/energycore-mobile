final class UiPreferences {
  const UiPreferences({required this.language, required this.theme});

  final String language;
  final String theme;
}

abstract interface class UiPreferencesRepository {
  Future<UiPreferences> current();
  Future<UiPreferences> save({required String language, required String theme});
}
