import 'device_control_models.dart';

abstract interface class DeviceControlRepository {
  Future<List<Device>> devices();
  Future<List<DeviceGroup>> groups();
  Future<List<Routine>> routines();
  Future<List<OperationMode>> modes();

  Future<void> toggleDevice(int id);
  Future<void> createDevice({
    required String name,
    required String room,
    required String type,
    required double powerWatts,
  });
  Future<void> updateDevice({
    required int id,
    required String name,
    required String room,
    required String type,
    required double powerWatts,
  });
  Future<void> deleteDevice(int id);
  Future<void> pairDevice({required String code, String? alias, String? room});
  Future<void> createGroup({
    required String name,
    required String description,
    required List<int> deviceIds,
  });
  Future<void> executeGroup(int id, String status);
  Future<void> updateGroup({
    required int id,
    required String name,
    required String description,
    required List<int> deviceIds,
  });
  Future<void> deleteGroup(int id);
  Future<void> createRoutine(CreateRoutineInput input);
  Future<void> toggleRoutine(int id, bool enabled);
  Future<void> executeRoutine(int id);
  Future<void> deleteRoutine(int id);
  Future<void> activateMode(int id);
  Future<OperationModePreview> previewMode(int id);
  Future<void> archiveMode(int id);
  Future<void> createMode(CreateOperationModeInput input);
}
