import '../../shared/domain/app_failure.dart';
import '../../shared/infrastructure/network/api_client.dart';
import '../domain/energy_dashboard_summary.dart';
import '../domain/energy_repository.dart';

final class EnergyApiRepository implements EnergyRepository {
  const EnergyApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<EnergyDashboardSummary> dashboardSummary() async {
    final response = await _api.get('/energy-readings/dashboard-summary');
    if (response is! Map<String, dynamic>) {
      throw const AppFailure(
        'The energy response is invalid.',
        kind: FailureKind.server,
      );
    }
    return _DashboardSummaryAssembler.fromJson(response);
  }
}

abstract final class _DashboardSummaryAssembler {
  static EnergyDashboardSummary fromJson(Map<String, dynamic> json) {
    final trend = _list(json['trend'])
        .map(
          (item) => EnergyTrendPoint(
            label: _string(item['label']),
            watts: _double(item['watts']),
            kilowattHours: _double(item['kilowattHours']),
            high: item['high'] == true,
          ),
        )
        .toList(growable: false);
    final topDevices = _list(json['topDevices'])
        .map(
          (item) => DeviceConsumption(
            id: _int(item['deviceId']),
            name: _string(item['name']),
            room: _string(item['room']),
            type: _string(item['type']),
            watts: _double(item['watts']),
            kilowattHours: _double(item['kilowattHours']),
          ),
        )
        .toList(growable: false);
    final rooms = _list(json['rooms'])
        .map(
          (item) => RoomConsumption(
            room: _string(item['room']),
            watts: _double(item['watts']),
            kilowattHours: _double(item['kilowattHours']),
            activeDevices: _int(item['activeDevices']),
          ),
        )
        .toList(growable: false);

    return EnergyDashboardSummary(
      currentWatts: _double(json['currentWatts']),
      todayKilowattHours: _double(json['todayKilowattHours']),
      todayEstimatedCost: _double(json['todayEstimatedCost']),
      projectedMonthlyCost: _double(json['projectedMonthlyCost']),
      costPerHour: _double(json['costPerHour']),
      peakWatts: _double(json['peakWatts']),
      averageWatts: _double(json['averageWatts']),
      activeDevices: _int(json['activeDevices']),
      monitoredDevices: _int(json['monitoredDevices']),
      efficiencyScore: _int(json['efficiencyScore']),
      operationalStatus: _string(json['operationalStatus']),
      recommendation: _string(json['recommendation']),
      activeAlerts: _int(json['activeAlerts']),
      criticalAlerts: _int(json['criticalAlerts']),
      trend: trend,
      topDevices: topDevices,
      rooms: rooms,
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

  static double _double(Object? value) => value is num ? value.toDouble() : 0;
  static int _int(Object? value) => value is num ? value.toInt() : 0;
  static String _string(Object? value) => value?.toString() ?? '';
}
