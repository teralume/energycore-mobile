import 'service_models.dart';

abstract interface class ServiceRepository {
  Future<List<SupportTicket>> supportTickets();
  Future<List<MaintenanceTicket>> maintenanceTickets();
  Future<void> createSupport(
    String subject,
    String description,
    String priority,
  );
  Future<void> updateSupportStatus(int id, String status);
  Future<void> deleteSupport(int id);
  Future<void> createMaintenance({
    required int deviceId,
    required String deviceName,
    required String type,
    required String description,
    required DateTime scheduledDate,
  });
  Future<void> updateMaintenanceStatus(int id, String status);
  Future<void> deleteMaintenance(int id);
}
