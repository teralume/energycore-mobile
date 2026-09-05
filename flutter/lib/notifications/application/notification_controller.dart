import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/notification_models.dart';
import '../domain/notification_repository.dart';

final class NotificationController extends ChangeNotifier {
  NotificationController(this._repository);
  final NotificationRepository _repository;

  List<EnergyAlert> alerts = const [];
  List<AlertRule> rules = const [];
  NotificationPreference? preferences;
  List<AlertRuleProfile> profiles = const [];
  RuleEvaluationResult? evaluation;
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  int get unreadCount => alerts.where((item) => !item.read).length;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _repository.alerts(),
        _repository.rules(),
        _repository.preferences(),
        _repository.profiles(),
      ]);
      alerts = result[0] as List<EnergyAlert>;
      rules = result[1] as List<AlertRule>;
      preferences = result[2] as NotificationPreference;
      profiles = result[3] as List<AlertRuleProfile>;
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

  Future<bool> markRead(EnergyAlert alert) =>
      mutate(() => _repository.markRead(alert.id));
  Future<bool> dismiss(EnergyAlert alert) =>
      mutate(() => _repository.dismiss(alert.id));
  Future<bool> resolve(EnergyAlert alert) =>
      mutate(() => _repository.resolve(alert.id));
  Future<bool> deleteAlert(EnergyAlert alert) =>
      mutate(() => _repository.deleteAlert(alert.id));
  Future<bool> createAlert(
    String title,
    String message,
    String level,
    String evidence,
    String recommendedAction,
  ) => mutate(
    () => _repository.createAlert(
      title: title,
      message: message,
      level: level,
      evidence: evidence,
      recommendedAction: recommendedAction,
    ),
  );
  Future<bool> toggleRule(AlertRule rule) =>
      mutate(() => _repository.toggleRule(rule.id));
  Future<bool> deleteRule(AlertRule rule) =>
      mutate(() => _repository.deleteRule(rule.id));
  Future<bool> createRule(
    String name,
    String metric,
    String condition,
    double threshold,
    String level,
  ) => mutate(
    () => _repository.createRule(
      name: name,
      metric: metric,
      condition: condition,
      threshold: threshold,
      level: level,
    ),
  );
  Future<bool> savePreferences(NotificationPreference value) =>
      mutate(() => _repository.updatePreferences(value));
  Future<bool> createProfile(
    String name,
    String description,
    String mode,
    String sensitivity,
  ) => mutate(
    () => _repository.createProfile(
      name: name,
      description: description,
      mode: mode,
      sensitivity: sensitivity,
    ),
  );
  Future<bool> activateProfile(AlertRuleProfile profile) =>
      mutate(() => _repository.activateProfile(profile.id));

  Future<bool> evaluate(double observedValue) async {
    if (isMutating) return false;
    isMutating = true;
    failure = null;
    notifyListeners();
    try {
      evaluation = await _repository.evaluateRules(observedValue);
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  void clearEvaluation() {
    evaluation = null;
    notifyListeners();
  }
}
