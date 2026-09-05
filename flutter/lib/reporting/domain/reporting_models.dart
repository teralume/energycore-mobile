final class EnergyReading {
  const EnergyReading({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.watts,
    required this.kilowattHours,
    required this.estimatedCost,
    required this.recordedAt,
    required this.status,
  });

  final int id;
  final int deviceId;
  final String deviceName;
  final double watts;
  final double kilowattHours;
  final double estimatedCost;
  final DateTime? recordedAt;
  final String status;
}

final class ConsumptionReport {
  const ConsumptionReport({
    required this.id,
    required this.totalWatts,
    required this.averageWatts,
    required this.highestWatts,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final double totalWatts;
  final double averageWatts;
  final double highestWatts;
  final DateTime? startDate;
  final DateTime? endDate;
}

final class EnergyGoal {
  const EnergyGoal({
    required this.id,
    required this.title,
    required this.targetKilowattHours,
    required this.currentKilowattHours,
    required this.deadline,
    required this.status,
    required this.scopeName,
    this.scopeType = 'GENERAL',
    this.scopeId,
    this.activeFrom,
    this.activeTo,
    this.createdAt,
  });

  final int id;
  final String title;
  final double targetKilowattHours;
  final double currentKilowattHours;
  final DateTime? deadline;
  final String status;
  final String scopeName;
  final String scopeType;
  final int? scopeId;
  final DateTime? activeFrom;
  final DateTime? activeTo;
  final DateTime? createdAt;

  double get progress => targetKilowattHours <= 0
      ? 0
      : (currentKilowattHours / targetKilowattHours).clamp(0, 1);
}

final class ReportingEvent {
  const ReportingEvent({
    required this.id,
    required this.eventName,
    required this.sourceContext,
    required this.subjectType,
    required this.subjectId,
    required this.summary,
    required this.detail,
    required this.occurredOn,
  });

  final int id;
  final String eventName;
  final String sourceContext;
  final String subjectType;
  final String? subjectId;
  final String summary;
  final String? detail;
  final DateTime? occurredOn;
}
