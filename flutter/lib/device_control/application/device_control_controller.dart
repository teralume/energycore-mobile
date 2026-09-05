import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/device_control_models.dart';
import '../domain/device_control_repository.dart';

final class DeviceControlController extends ChangeNotifier {
  DeviceControlController(this._repository);

  final DeviceControlRepository _repository;

  List<Device> devices = const [];
  List<DeviceGroup> groups = const [];
  List<Routine> routines = const [];
  List<OperationMode> modes = const [];
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.devices(),
        _repository.groups(),
        _repository.routines(),
        _repository.modes(),
      ]);
      devices = values[0] as List<Device>;
      groups = values[1] as List<DeviceGroup>;
      routines = values[2] as List<Routine>;
      modes = values[3] as List<OperationMode>;
    } on AppFailure catch (error) {
      failure = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _mutate(Future<void> Function() action) async {
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

  Future<bool> toggleDevice(Device device) =>
      _mutate(() => _repository.toggleDevice(device.id));

  Future<bool> createDevice(
    String name,
    String room,
    String type,
    double powerWatts,
  ) => _mutate(
    () => _repository.createDevice(
      name: name,
      room: room,
      type: type,
      powerWatts: powerWatts,
    ),
  );

  Future<bool> updateDevice(
    Device device,
    String name,
    String room,
    String type,
    double powerWatts,
  ) => _mutate(
    () => _repository.updateDevice(
      id: device.id,
      name: name,
      room: room,
      type: type,
      powerWatts: powerWatts,
    ),
  );

  Future<bool> deleteDevice(Device device) =>
      _mutate(() => _repository.deleteDevice(device.id));

  Future<bool> pairDevice(String code, String alias, String room) => _mutate(
    () => _repository.pairDevice(code: code, alias: alias, room: room),
  );

  Future<bool> createGroup(String name, String description, List<int> ids) =>
      _mutate(
        () => _repository.createGroup(
          name: name,
          description: description,
          deviceIds: ids,
        ),
      );

  Future<bool> executeGroup(DeviceGroup group, String status) =>
      _mutate(() => _repository.executeGroup(group.id, status));

  Future<bool> updateGroup(
    DeviceGroup group,
    String name,
    String description,
    List<int> ids,
  ) => _mutate(
    () => _repository.updateGroup(
      id: group.id,
      name: name,
      description: description,
      deviceIds: ids,
    ),
  );

  Future<bool> deleteGroup(DeviceGroup group) =>
      _mutate(() => _repository.deleteGroup(group.id));

  Future<bool> createRoutine(CreateRoutineInput input) =>
      _mutate(() => _repository.createRoutine(input));

  Future<bool> toggleRoutine(Routine routine) =>
      _mutate(() => _repository.toggleRoutine(routine.id, !routine.enabled));

  Future<bool> executeRoutine(Routine routine) =>
      _mutate(() => _repository.executeRoutine(routine.id));

  Future<bool> deleteRoutine(Routine routine) =>
      _mutate(() => _repository.deleteRoutine(routine.id));

  Future<bool> activateMode(OperationMode mode) =>
      _mutate(() => _repository.activateMode(mode.id));

  Future<OperationModePreview?> previewMode(OperationMode mode) async {
    try {
      return await _repository.previewMode(mode.id);
    } on AppFailure catch (error) {
      failure = error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> archiveMode(OperationMode mode) =>
      _mutate(() => _repository.archiveMode(mode.id));

  Future<bool> createMode(CreateOperationModeInput input) =>
      _mutate(() => _repository.createMode(input));
}
