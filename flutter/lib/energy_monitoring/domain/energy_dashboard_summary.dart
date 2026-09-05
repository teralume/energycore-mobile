final class EnergyDashboardSummary {
  const EnergyDashboardSummary({
    required this.currentWatts,
    required this.todayKilowattHours,
    required this.todayEstimatedCost,
    required this.projectedMonthlyCost,
    required this.costPerHour,
    required this.peakWatts,
    required this.averageWatts,
    required this.activeDevices,
    required this.monitoredDevices,
    required this.efficiencyScore,
    required this.operationalStatus,
    required this.recommendation,
    required this.activeAlerts,
    required this.criticalAlerts,
    required this.trend,
    required this.topDevices,
    required this.rooms,
  });

  final double currentWatts;
  final double todayKilowattHours;
  final double todayEstimatedCost;
  final double projectedMonthlyCost;
  final double costPerHour;
  final double peakWatts;
  final double averageWatts;
  final int activeDevices;
  final int monitoredDevices;
  final int efficiencyScore;
  final String operationalStatus;
  final String recommendation;
  final int activeAlerts;
  final int criticalAlerts;
  final List<EnergyTrendPoint> trend;
  final List<DeviceConsumption> topDevices;
  final List<RoomConsumption> rooms;
}

final class EnergyTrendPoint {
  const EnergyTrendPoint({
    required this.label,
    required this.watts,
    required this.kilowattHours,
    required this.high,
  });

  final String label;
  final double watts;
  final double kilowattHours;
  final bool high;
}

final class DeviceConsumption {
  const DeviceConsumption({
    required this.id,
    required this.name,
    required this.room,
    required this.type,
    required this.watts,
    required this.kilowattHours,
  });

  final int id;
  final String name;
  final String room;
  final String type;
  final double watts;
  final double kilowattHours;
}

final class RoomConsumption {
  const RoomConsumption({
    required this.room,
    required this.watts,
    required this.kilowattHours,
    required this.activeDevices,
  });

  final String room;
  final double watts;
  final double kilowattHours;
  final int activeDevices;
}
