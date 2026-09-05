import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/service_models.dart';
import '../domain/service_repository.dart';

final class ServiceApiRepository implements ServiceRepository {
  const ServiceApiRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<SupportTicket>> supportTickets() async =>
      jsonList(await _api.get('/support-tickets'))
          .map(
            (json) => SupportTicket(
              id: jsonInt(json['id']),
              subject: jsonString(json['subject']),
              description: jsonString(json['description']),
              priority: jsonString(json['priority'], 'MEDIUM'),
              status: jsonString(json['status'], 'OPEN'),
              createdAt: DateTime.tryParse(jsonString(json['createdAt'])),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<MaintenanceTicket>> maintenanceTickets() async =>
      jsonList(await _api.get('/maintenance-tickets'))
          .map(
            (json) => MaintenanceTicket(
              id: jsonInt(json['id']),
              deviceId: jsonInt(json['deviceId']),
              deviceName: jsonString(json['deviceName']),
              type: jsonString(json['type'], 'INSPECTION'),
              description: jsonString(json['description']),
              scheduledDate: DateTime.tryParse(
                jsonString(json['scheduledDate']),
              ),
              status: jsonString(json['status'], 'PENDING'),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> createSupport(
    String subject,
    String description,
    String priority,
  ) => _api.postVoid(
    '/support-tickets',
    body: {
      'subject': subject,
      'description': description,
      'priority': priority,
      'status': 'OPEN',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
  );

  @override
  Future<void> updateSupportStatus(int id, String status) =>
      _api.patchVoid('/support-tickets/$id/status', body: {'status': status});

  @override
  Future<void> deleteSupport(int id) => _api.deleteVoid('/support-tickets/$id');

  @override
  Future<void> createMaintenance({
    required int deviceId,
    required String deviceName,
    required String type,
    required String description,
    required DateTime scheduledDate,
  }) => _api.postVoid(
    '/maintenance-tickets',
    body: {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'type': type,
      'description': description,
      'scheduledDate': _date(scheduledDate),
      'status': 'PENDING',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
  );

  @override
  Future<void> updateMaintenanceStatus(int id, String status) => _api.patchVoid(
    '/maintenance-tickets/$id/status',
    body: {'status': status},
  );

  @override
  Future<void> deleteMaintenance(int id) =>
      _api.deleteVoid('/maintenance-tickets/$id');
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
