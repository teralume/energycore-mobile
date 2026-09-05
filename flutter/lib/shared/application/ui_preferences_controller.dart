import 'package:flutter/foundation.dart';

import '../domain/app_failure.dart';
import '../domain/ui_preferences.dart';

final class UiPreferencesController extends ChangeNotifier {
  UiPreferencesController(this._repository);

  final UiPreferencesRepository _repository;

  String? language;
  String? theme;
  AppFailure? failure;
  bool isLoading = false;
  bool isSaving = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final value = await _repository.current();
      language = _supportedLanguage(value.language);
      theme = _supportedTheme(value.theme);
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({required String language, required String theme}) async {
    if (isSaving) return false;
    this.language = _supportedLanguage(language);
    this.theme = _supportedTheme(theme);
    isSaving = true;
    failure = null;
    notifyListeners();
    try {
      final value = await _repository.save(
        language: this.language!,
        theme: this.theme!,
      );
      this.language = _supportedLanguage(value.language);
      this.theme = _supportedTheme(value.theme);
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  String _supportedLanguage(String value) =>
      const {'en', 'es', 'pt'}.contains(value) ? value : 'es';

  String _supportedTheme(String value) =>
      const {'light', 'dark'}.contains(value) ? value : 'light';
}
