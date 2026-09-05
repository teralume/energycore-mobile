final class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final DateTime? createdAt;
}

final class MaintenanceTicket {
  const MaintenanceTicket({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.description,
    required this.scheduledDate,
    required this.status,
  });

  final int id;
  final int deviceId;
  final String deviceName;
  final String type;
  final String description;
  final DateTime? scheduledDate;
  final String status;
}
