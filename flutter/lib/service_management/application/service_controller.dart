import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/service_models.dart';
import '../domain/service_repository.dart';

final class ServiceController extends ChangeNotifier {
  ServiceController(this._repository);
  final ServiceRepository _repository;

  List<SupportTicket> supportTickets = const [];
  List<MaintenanceTicket> maintenanceTickets = const [];
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _repository.supportTickets(),
        _repository.maintenanceTickets(),
      ]);
      supportTickets = result[0] as List<SupportTicket>;
      maintenanceTickets = result[1] as List<MaintenanceTicket>;
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> mutate(Future<void> Function() action) async {
    if (isMutating) return false;
    isMutating = true;
    failure = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } on AppFailure catch (error) {
      failure = error;
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> createSupport(
    String subject,
    String description,
    String priority,
  ) => mutate(() => _repository.createSupport(subject, description, priority));
  Future<bool> updateSupportStatus(SupportTicket ticket, String status) =>
      mutate(() => _repository.updateSupportStatus(ticket.id, status));
  Future<bool> deleteSupport(SupportTicket ticket) =>
      mutate(() => _repository.deleteSupport(ticket.id));
  Future<bool> createMaintenance(
    int deviceId,
    String deviceName,
    String type,
    String description,
    DateTime date,
  ) => mutate(
    () => _repository.createMaintenance(
      deviceId: deviceId,
      deviceName: deviceName,
      type: type,
      description: description,
      scheduledDate: date,
    ),
  );
  Future<bool> updateMaintenanceStatus(
    MaintenanceTicket ticket,
    String status,
  ) => mutate(() => _repository.updateMaintenanceStatus(ticket.id, status));
  Future<bool> deleteMaintenance(MaintenanceTicket ticket) =>
      mutate(() => _repository.deleteMaintenance(ticket.id));
}
