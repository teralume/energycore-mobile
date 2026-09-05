import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/reporting_models.dart';
import '../domain/reporting_repository.dart';

final class ReportingApiRepository implements ReportingRepository {
  const ReportingApiRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<EnergyReading>> readings() async =>
      jsonList(await _api.get('/energy-readings'))
          .map(
            (json) => EnergyReading(
              id: jsonInt(json['id']),
              deviceId: jsonInt(json['deviceId']),
              deviceName: jsonString(json['deviceName']),
              watts: jsonDouble(json['watts']),
              kilowattHours: jsonDouble(json['kilowattHours']),
              estimatedCost: jsonDouble(json['estimatedCost']),
              recordedAt: DateTime.tryParse(jsonString(json['recordedAt'])),
              status: jsonString(json['status'], 'NORMAL'),
            ),
          )
          .toList(growable: false);

  EnergyReading _reading(Map<String, dynamic> json) => EnergyReading(
    id: jsonInt(json['id']),
    deviceId: jsonInt(json['deviceId']),
    deviceName: jsonString(json['deviceName']),
    watts: jsonDouble(json['watts']),
    kilowattHours: jsonDouble(json['kilowattHours']),
    estimatedCost: jsonDouble(json['estimatedCost']),
    recordedAt: DateTime.tryParse(jsonString(json['recordedAt'])),
    status: jsonString(json['status'], 'NORMAL'),
  );

  @override
  Future<List<EnergyReading>> readingsByDate(
    DateTime start,
    DateTime end,
  ) async => jsonList(
    await _api.get(
      '/energy-readings?recordedAt_gte=${_date(start)}&recordedAt_lte=${_date(end)}',
    ),
  ).map(_reading).toList(growable: false);

  @override
  Future<int> samplingSeconds() async {
    final json = jsonObject(
      await _api.get('/energy-readings/sampling-settings'),
    );
    return jsonInt(json['sampleSeconds'], 30);
  }

  @override
  Future<void> updateSamplingSeconds(int seconds) => _api.patchVoid(
    '/energy-readings/sampling-settings',
    body: {'sampleSeconds': seconds},
  );

  @override
  Future<List<ConsumptionReport>> reports() async =>
      jsonList(await _api.get('/reports'))
          .map(
            (json) => ConsumptionReport(
              id: jsonInt(json['id']),
              totalWatts: jsonDouble(json['totalWatts']),
              averageWatts: jsonDouble(json['averageWatts']),
              highestWatts: jsonDouble(json['highestWatts']),
              startDate: DateTime.tryParse(jsonString(json['startDate'])),
              endDate: DateTime.tryParse(jsonString(json['endDate'])),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<EnergyGoal>> goals() async =>
      jsonList(await _api.get('/reports/energy-goals'))
          .map(
            (json) => EnergyGoal(
              id: jsonInt(json['id']),
              title: jsonString(json['title']),
              targetKilowattHours: jsonDouble(
                json['targetKilowattHours'],
                jsonDouble(json['targetWatts']),
              ),
              currentKilowattHours: jsonDouble(
                json['currentKilowattHours'],
                jsonDouble(json['currentWatts']),
              ),
              deadline: DateTime.tryParse(jsonString(json['deadline'])),
              status: jsonString(json['status'], 'ACTIVE'),
              scopeName: jsonString(json['scopeName'], 'All operations'),
              scopeType: jsonString(json['scopeType'], 'GENERAL'),
              scopeId: json['scopeId'] is num ? jsonInt(json['scopeId']) : null,
              activeFrom: DateTime.tryParse(jsonString(json['activeFrom'])),
              activeTo: DateTime.tryParse(jsonString(json['activeTo'])),
              createdAt: DateTime.tryParse(jsonString(json['createdAt'])),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<ReportingEvent>> events() async =>
      jsonList(await _api.get('/reports/activity'))
          .map(
            (json) => ReportingEvent(
              id: jsonInt(json['id']),
              eventName: jsonString(json['eventName']),
              sourceContext: jsonString(json['sourceContext']),
              subjectType: jsonString(json['subjectType']),
              subjectId: json['subjectId']?.toString(),
              summary: jsonString(json['summary']),
              detail: json['detail']?.toString(),
              occurredOn: DateTime.tryParse(jsonString(json['occurredOn'])),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> generateReport(DateTime start, DateTime end) => _api.postVoid(
    '/reports',
    body: {'startDate': _date(start), 'endDate': _date(end)},
  );

  @override
  Future<void> deleteReport(int id) => _api.deleteVoid('/reports/$id');

  @override
  Future<void> createGoal({
    required String title,
    required double targetKilowattHours,
    required DateTime deadline,
    String scopeType = 'GENERAL',
    int? scopeId,
    String? scopeName,
  }) => _api.postVoid(
    '/reports/energy-goals',
    body: {
      'title': title,
      'targetKilowattHours': targetKilowattHours,
      'currentKilowattHours': 0,
      'deadline': _date(deadline),
      'status': 'ACTIVE',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'scopeType': scopeType,
      'scopeId': scopeId,
      'scopeName': scopeName ?? 'All operations',
    },
  );

  @override
  Future<void> updateGoal({
    required int id,
    required String title,
    required double targetKilowattHours,
    required double currentKilowattHours,
    required DateTime deadline,
    required String status,
    required String scopeType,
    int? scopeId,
    String? scopeName,
  }) async {
    await _api.patch(
      '/reports/energy-goals/$id',
      body: {
        'title': title,
        'targetKilowattHours': targetKilowattHours,
        'currentKilowattHours': currentKilowattHours,
        'deadline': _date(deadline),
        'status': status,
        'scopeType': scopeType,
        'scopeId': scopeId,
        'scopeName': scopeName,
      },
    );
  }

  @override
  Future<void> deleteGoal(int id) =>
      _api.deleteVoid('/reports/energy-goals/$id');
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
