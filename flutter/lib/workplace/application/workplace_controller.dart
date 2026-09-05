import 'package:flutter/foundation.dart';

import '../../shared/domain/app_failure.dart';
import '../domain/workplace_models.dart';
import '../domain/workplace_repository.dart';

final class WorkplaceController extends ChangeNotifier {
  WorkplaceController(this._repository);
  final WorkplaceRepository _repository;

  List<WorkplaceLocation> locations = const [];
  List<WorkplaceRoom> rooms = const [];
  List<DeviceAssignment> assignments = const [];
  AppFailure? failure;
  bool isLoading = false;
  bool isMutating = false;
  bool isSearchingAddresses = false;
  List<AddressSuggestion> addressSuggestions = const [];

  Future<void> searchAddresses(String query, String language) async {
    isSearchingAddresses = true;
    notifyListeners();
    try {
      addressSuggestions = await _repository.searchAddresses(query, language);
    } catch (_) {
      addressSuggestions = const [];
    } finally {
      isSearchingAddresses = false;
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    failure = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _repository.locations(),
        _repository.rooms(),
        _repository.assignments(),
      ]);
      locations = result[0] as List<WorkplaceLocation>;
      rooms = result[1] as List<WorkplaceRoom>;
      assignments = result[2] as List<DeviceAssignment>;
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

  Future<bool> createLocation(String name, String address, String type) =>
      mutate(() => _repository.createLocation(name, address, type));
  Future<bool> updateLocation(
    WorkplaceLocation location,
    String name,
    String address,
    String type,
  ) => mutate(
    () => _repository.updateLocation(location.id, name, address, type),
  );
  Future<bool> createRoom(int locationId, String name, String floor) =>
      mutate(() => _repository.createRoom(locationId, name, floor));
  Future<bool> updateRoom(
    WorkplaceRoom room,
    int locationId,
    String name,
    String floor,
  ) => mutate(() => _repository.updateRoom(room.id, locationId, name, floor));
  Future<bool> assignDevice(int deviceId, int locationId, int? roomId) =>
      mutate(() => _repository.assignDevice(deviceId, locationId, roomId));
  Future<bool> moveAssignment(
    DeviceAssignment assignment,
    int locationId,
    int? roomId,
  ) => mutate(
    () => _repository.moveAssignment(assignment.id, locationId, roomId),
  );
  Future<bool> deleteLocation(int id) =>
      mutate(() => _repository.deleteLocation(id));
  Future<bool> deleteRoom(int id) => mutate(() => _repository.deleteRoom(id));
  Future<bool> deleteAssignment(int id) =>
      mutate(() => _repository.deleteAssignment(id));

  String locationName(int id) =>
      locations
          .where((item) => item.id == id)
          .map((item) => item.name)
          .firstOrNull ??
      'Location #$id';

  String roomName(int? id) => id == null
      ? 'No room'
      : rooms
                .where((item) => item.id == id)
                .map((item) => item.name)
                .firstOrNull ??
            'Room #$id';
}
