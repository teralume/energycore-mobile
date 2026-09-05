import 'notification_models.dart';

abstract interface class NotificationRepository {
  Future<List<EnergyAlert>> alerts();
  Future<List<AlertRule>> rules();
  Future<NotificationPreference> preferences();
  Future<List<AlertRuleProfile>> profiles();
  Future<void> markRead(int id);
  Future<void> dismiss(int id);
  Future<void> resolve(int id);
  Future<void> deleteAlert(int id);
  Future<void> createAlert({
    required String title,
    required String message,
    required String level,
    required String evidence,
    required String recommendedAction,
  });
  Future<void> toggleRule(int id);
  Future<void> deleteRule(int id);
  Future<void> createRule({
    required String name,
    required String metric,
    required String condition,
    required double threshold,
    required String level,
  });
  Future<void> updatePreferences(NotificationPreference value);
  Future<void> createProfile({
    required String name,
    required String description,
    required String mode,
    required String sensitivity,
  });
  Future<void> activateProfile(int id);
  Future<RuleEvaluationResult> evaluateRules(double observedValue);
}
