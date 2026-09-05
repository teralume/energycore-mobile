import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/notification_models.dart';
import '../domain/notification_repository.dart';

final class NotificationApiRepository implements NotificationRepository {
  const NotificationApiRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<EnergyAlert>> alerts() async =>
      jsonList(await _api.get('/alerts'))
          .map(
            (json) => EnergyAlert(
              id: jsonInt(json['id']),
              title: jsonString(json['title']),
              message: jsonString(json['message']),
              level: jsonString(json['level'], 'INFO'),
              sourceLabel: jsonString(
                json['sourceLabel'],
                jsonString(json['sourceType'], 'SYSTEM'),
              ),
              read: jsonBool(json['read'], jsonBool(json['readStatus'])),
              active: jsonBool(json['active'], true),
              resolved: jsonBool(json['resolved']),
              createdAt: DateTime.tryParse(jsonString(json['createdAt'])),
              recommendedAction: jsonString(json['recommendedAction']),
              evidence: jsonString(json['evidence']),
              explanation: jsonString(json['explanation']),
              severityScore: jsonDouble(json['severityScore']),
              repeatCount: jsonInt(json['repeatCount'], 1),
              dismissedUntil: DateTime.tryParse(
                jsonString(json['dismissedUntil']),
              ),
              expired: jsonBool(json['expired']),
              silenced: jsonBool(json['silenced']),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<AlertRule>> rules() async =>
      jsonList(await _api.get('/alerts/rules'))
          .map(
            (json) => AlertRule(
              id: jsonInt(json['id']),
              name: jsonString(json['name']),
              metric: jsonString(json['metric'], 'WATTS'),
              condition: jsonString(
                json['conditionType'],
                jsonString(json['condition'], 'GREATER_THAN'),
              ),
              threshold: jsonDouble(json['threshold']),
              level: jsonString(json['level'], 'WARNING'),
              enabled: jsonBool(json['enabled']),
              scopeType: jsonString(json['scopeType'], 'USER'),
              scopeId: json['scopeId']?.toString(),
              evaluatorType: jsonString(json['evaluatorType'], 'THRESHOLD'),
              weight: jsonDouble(json['weight'], 1),
              profileName: jsonString(json['profileName']),
            ),
          )
          .toList(growable: false);

  @override
  Future<NotificationPreference> preferences() async {
    final json = jsonObject(await _api.get('/notifications/preferences'));
    return NotificationPreference(
      id: json['id'] == null ? null : jsonInt(json['id']),
      emailEnabled: jsonBool(json['emailEnabled'], true),
      pushEnabled: jsonBool(json['pushEnabled'], true),
      inAppEnabled: jsonBool(json['inAppEnabled'], true),
      toastEnabled: jsonBool(json['toastEnabled'], true),
      dashboardEnabled: jsonBool(json['dashboardEnabled'], true),
      criticalOnly: jsonBool(json['criticalOnly']),
      quietHoursEnabled: jsonBool(json['quietHoursEnabled']),
      dailySummaryEnabled: jsonBool(json['dailySummaryEnabled'], true),
      weeklySummaryEnabled: jsonBool(json['weeklySummaryEnabled']),
      monthlyReportEnabled: jsonBool(json['monthlyReportEnabled'], true),
      minimumLevel: jsonString(json['minimumLevel'], 'INFO'),
      allowedLevels: _csvValues(json['allowedLevels'], const [
        'STABLE',
        'INFO',
        'WARNING',
        'CRITICAL',
        'SUCCESS',
      ]),
      allowedSourceTypes: _csvValues(json['allowedSourceTypes'], const [
        'DEVICE',
        'GROUP',
        'ROOM',
        'WORKPLACE',
        'ROUTINE',
        'GOAL',
        'REPORT',
        'RULE',
        'MODE',
        'SYSTEM',
      ]),
      quietHoursStart: jsonString(json['quietHoursStart'], '22:00'),
      quietHoursEnd: jsonString(json['quietHoursEnd'], '07:00'),
      criticalBreaksQuietHours: jsonBool(
        json['criticalBreaksQuietHours'],
        true,
      ),
      groupSimilarAlerts: jsonBool(json['groupSimilarAlerts'], true),
      remindersEnabled: jsonBool(json['remindersEnabled'], true),
      cooldownMinutes: jsonInt(json['cooldownMinutes'], 10),
      maxAlertsPerHour: jsonInt(json['maxAlertsPerHour'], 20),
      routineNightSilence: jsonBool(json['routineNightSilence'], true),
      goalDeadlineAlerts: jsonBool(json['goalDeadlineAlerts'], true),
      maintenanceDeviceAlerts: jsonBool(json['maintenanceDeviceAlerts']),
      systemRecommendations: jsonBool(json['systemRecommendations'], true),
      defaultDeliveryMode: jsonString(json['defaultDeliveryMode'], 'BANNER'),
    );
  }

  @override
  Future<List<AlertRuleProfile>> profiles() async =>
      jsonList(await _api.get('/alerts/rule-profiles'))
          .map(
            (json) => AlertRuleProfile(
              id: jsonInt(json['id']),
              name: jsonString(json['name']),
              description: jsonString(json['description']),
              scopeType: jsonString(json['scopeType'], 'USER'),
              mode: jsonString(json['mode'], 'BALANCED'),
              sensitivity: jsonString(json['sensitivity'], 'MEDIUM'),
              active: jsonBool(json['active']),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> markRead(int id) =>
      _api.patchVoid('/alerts/$id/read', body: const {});
  @override
  Future<void> dismiss(int id) =>
      _api.patchVoid('/alerts/$id/dismiss', body: const {});
  @override
  Future<void> resolve(int id) =>
      _api.patchVoid('/alerts/$id/resolve', body: const {});
  @override
  Future<void> deleteAlert(int id) => _api.deleteVoid('/alerts/$id');
  @override
  Future<void> createAlert({
    required String title,
    required String message,
    required String level,
    required String evidence,
    required String recommendedAction,
  }) => _api.postVoid(
    '/alerts',
    body: {
      'title': title,
      'message': message,
      'level': level,
      'sourceType': 'SYSTEM',
      'eventType': 'MANUAL',
      'threadKey': 'manual-${DateTime.now().millisecondsSinceEpoch}',
      'evidence': evidence.isEmpty ? null : evidence,
      'recommendedAction': recommendedAction.isEmpty ? null : recommendedAction,
      'severityScore': level == 'CRITICAL'
          ? 100
          : level == 'WARNING'
          ? 60
          : 20,
    },
  );
  @override
  Future<void> toggleRule(int id) =>
      _api.patchVoid('/alerts/rules/$id/toggle', body: const {});
  @override
  Future<void> deleteRule(int id) => _api.deleteVoid('/alerts/rules/$id');

  @override
  Future<void> createRule({
    required String name,
    required String metric,
    required String condition,
    required double threshold,
    required String level,
  }) => _api.postVoid(
    '/alerts/rules',
    body: {
      'name': name,
      'metric': metric,
      'conditionType': condition,
      'threshold': threshold,
      'level': level,
      'scopeType': 'USER',
      'evaluatorType': 'THRESHOLD',
      'weight': 1,
    },
  );

  @override
  Future<void> updatePreferences(NotificationPreference value) async {
    await _api.put(
      '/notifications/preferences',
      body: {
        'emailEnabled': value.emailEnabled,
        'pushEnabled': value.pushEnabled,
        'inAppEnabled': value.inAppEnabled,
        'toastEnabled': value.toastEnabled,
        'dashboardEnabled': value.dashboardEnabled,
        'criticalOnly': value.criticalOnly,
        'minimumLevel': value.minimumLevel,
        'scopeType': 'USER',
        'allowedLevels': value.allowedLevels.join(','),
        'allowedSourceTypes': value.allowedSourceTypes.join(','),
        'quietHoursEnabled': value.quietHoursEnabled,
        'quietHoursStart': value.quietHoursStart,
        'quietHoursEnd': value.quietHoursEnd,
        'criticalBreaksQuietHours': value.criticalBreaksQuietHours,
        'dailySummaryEnabled': value.dailySummaryEnabled,
        'weeklySummaryEnabled': value.weeklySummaryEnabled,
        'monthlyReportEnabled': value.monthlyReportEnabled,
        'groupSimilarAlerts': value.groupSimilarAlerts,
        'remindersEnabled': value.remindersEnabled,
        'cooldownMinutes': value.cooldownMinutes,
        'maxAlertsPerHour': value.maxAlertsPerHour,
        'routineNightSilence': value.routineNightSilence,
        'goalDeadlineAlerts': value.goalDeadlineAlerts,
        'maintenanceDeviceAlerts': value.maintenanceDeviceAlerts,
        'systemRecommendations': value.systemRecommendations,
        'defaultDeliveryMode': value.defaultDeliveryMode,
      },
    );
  }

  @override
  Future<void> createProfile({
    required String name,
    required String description,
    required String mode,
    required String sensitivity,
  }) => _api.postVoid(
    '/alerts/rule-profiles',
    body: {
      'name': name,
      'description': description,
      'scopeType': 'USER',
      'mode': mode,
      'sensitivity': sensitivity,
    },
  );

  @override
  Future<void> activateProfile(int id) =>
      _api.patchVoid('/alerts/rule-profiles/$id/activate', body: const {});

  @override
  Future<RuleEvaluationResult> evaluateRules(double observedValue) async {
    final json = jsonObject(
      await _api.post(
        '/alerts/rules/evaluate',
        body: {'scopeType': 'USER', 'observedValue': observedValue},
      ),
    );
    return RuleEvaluationResult(
      level: jsonString(json['level'], 'INFO'),
      severityScore: jsonDouble(json['severityScore']),
      evidence: jsonString(json['evidence']),
      explanation: jsonString(json['explanation']),
      recommendedAction: jsonString(json['recommendedAction']),
      activeEvaluatorCount: jsonInt(json['activeEvaluatorCount']),
    );
  }
}

List<String> _csvValues(Object? value, List<String> fallback) {
  final parsed = value
      ?.toString()
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return parsed == null || parsed.isEmpty ? fallback : parsed;
}
