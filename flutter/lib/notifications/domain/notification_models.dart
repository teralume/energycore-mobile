final class EnergyAlert {
  const EnergyAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.sourceLabel,
    required this.read,
    required this.active,
    required this.resolved,
    required this.createdAt,
    required this.recommendedAction,
    this.evidence = '',
    this.explanation = '',
    this.severityScore = 0,
    this.repeatCount = 1,
    this.dismissedUntil,
    this.expired = false,
    this.silenced = false,
  });

  final int id;
  final String title;
  final String message;
  final String level;
  final String sourceLabel;
  final bool read;
  final bool active;
  final bool resolved;
  final DateTime? createdAt;
  final String recommendedAction;
  final String evidence;
  final String explanation;
  final double severityScore;
  final int repeatCount;
  final DateTime? dismissedUntil;
  final bool expired;
  final bool silenced;
}

final class AlertRule {
  const AlertRule({
    required this.id,
    required this.name,
    required this.metric,
    required this.condition,
    required this.threshold,
    required this.level,
    required this.enabled,
    this.scopeType = 'USER',
    this.scopeId,
    this.evaluatorType = 'THRESHOLD',
    this.weight = 1,
    this.profileName = '',
  });

  final int id;
  final String name;
  final String metric;
  final String condition;
  final double threshold;
  final String level;
  final bool enabled;
  final String scopeType;
  final String? scopeId;
  final String evaluatorType;
  final double weight;
  final String profileName;
}

final class NotificationPreference {
  const NotificationPreference({
    this.id,
    required this.emailEnabled,
    required this.pushEnabled,
    required this.inAppEnabled,
    this.toastEnabled = true,
    this.dashboardEnabled = true,
    required this.criticalOnly,
    required this.quietHoursEnabled,
    required this.dailySummaryEnabled,
    required this.weeklySummaryEnabled,
    required this.monthlyReportEnabled,
    this.minimumLevel = 'INFO',
    this.allowedLevels = const [
      'STABLE',
      'INFO',
      'WARNING',
      'CRITICAL',
      'SUCCESS',
    ],
    this.allowedSourceTypes = const [
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
    ],
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.criticalBreaksQuietHours = true,
    this.groupSimilarAlerts = true,
    this.remindersEnabled = true,
    this.cooldownMinutes = 10,
    this.maxAlertsPerHour = 20,
    this.routineNightSilence = true,
    this.goalDeadlineAlerts = true,
    this.maintenanceDeviceAlerts = false,
    this.systemRecommendations = true,
    this.defaultDeliveryMode = 'BANNER',
  });

  final int? id;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool inAppEnabled;
  final bool toastEnabled;
  final bool dashboardEnabled;
  final bool criticalOnly;
  final bool quietHoursEnabled;
  final bool dailySummaryEnabled;
  final bool weeklySummaryEnabled;
  final bool monthlyReportEnabled;
  final String minimumLevel;
  final List<String> allowedLevels;
  final List<String> allowedSourceTypes;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool criticalBreaksQuietHours;
  final bool groupSimilarAlerts;
  final bool remindersEnabled;
  final int cooldownMinutes;
  final int maxAlertsPerHour;
  final bool routineNightSilence;
  final bool goalDeadlineAlerts;
  final bool maintenanceDeviceAlerts;
  final bool systemRecommendations;
  final String defaultDeliveryMode;

  NotificationPreference copyWith({
    int? id,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? toastEnabled,
    bool? dashboardEnabled,
    bool? criticalOnly,
    bool? quietHoursEnabled,
    bool? dailySummaryEnabled,
    bool? weeklySummaryEnabled,
    bool? monthlyReportEnabled,
    String? minimumLevel,
    List<String>? allowedLevels,
    List<String>? allowedSourceTypes,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? criticalBreaksQuietHours,
    bool? groupSimilarAlerts,
    bool? remindersEnabled,
    int? cooldownMinutes,
    int? maxAlertsPerHour,
    bool? routineNightSilence,
    bool? goalDeadlineAlerts,
    bool? maintenanceDeviceAlerts,
    bool? systemRecommendations,
    String? defaultDeliveryMode,
  }) => NotificationPreference(
    id: id ?? this.id,
    emailEnabled: emailEnabled ?? this.emailEnabled,
    pushEnabled: pushEnabled ?? this.pushEnabled,
    inAppEnabled: inAppEnabled ?? this.inAppEnabled,
    toastEnabled: toastEnabled ?? this.toastEnabled,
    dashboardEnabled: dashboardEnabled ?? this.dashboardEnabled,
    criticalOnly: criticalOnly ?? this.criticalOnly,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
    weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
    monthlyReportEnabled: monthlyReportEnabled ?? this.monthlyReportEnabled,
    minimumLevel: minimumLevel ?? this.minimumLevel,
    allowedLevels: allowedLevels ?? this.allowedLevels,
    allowedSourceTypes: allowedSourceTypes ?? this.allowedSourceTypes,
    quietHoursStart: quietHoursStart ?? this.quietHoursStart,
    quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    criticalBreaksQuietHours:
        criticalBreaksQuietHours ?? this.criticalBreaksQuietHours,
    groupSimilarAlerts: groupSimilarAlerts ?? this.groupSimilarAlerts,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
    maxAlertsPerHour: maxAlertsPerHour ?? this.maxAlertsPerHour,
    routineNightSilence: routineNightSilence ?? this.routineNightSilence,
    goalDeadlineAlerts: goalDeadlineAlerts ?? this.goalDeadlineAlerts,
    maintenanceDeviceAlerts:
        maintenanceDeviceAlerts ?? this.maintenanceDeviceAlerts,
    systemRecommendations: systemRecommendations ?? this.systemRecommendations,
    defaultDeliveryMode: defaultDeliveryMode ?? this.defaultDeliveryMode,
  );
}

final class AlertRuleProfile {
  const AlertRuleProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.scopeType,
    required this.mode,
    required this.sensitivity,
    required this.active,
  });
  final int id;
  final String name;
  final String description;
  final String scopeType;
  final String mode;
  final String sensitivity;
  final bool active;
}

final class RuleEvaluationResult {
  const RuleEvaluationResult({
    required this.level,
    required this.severityScore,
    required this.evidence,
    required this.explanation,
    required this.recommendedAction,
    required this.activeEvaluatorCount,
  });
  final String level;
  final double severityScore;
  final String evidence;
  final String explanation;
  final String recommendedAction;
  final int activeEvaluatorCount;
}
