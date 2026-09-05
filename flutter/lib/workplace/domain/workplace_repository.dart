import 'workplace_models.dart';

abstract interface class WorkplaceRepository {
  Future<List<AddressSuggestion>> searchAddresses(
    String query,
    String language,
  );
  Future<List<WorkplaceLocation>> locations();
  Future<List<WorkplaceRoom>> rooms();
  Future<List<DeviceAssignment>> assignments();
  Future<void> createLocation(String name, String address, String type);
  Future<void> updateLocation(int id, String name, String address, String type);
  Future<void> createRoom(int locationId, String name, String floor);
  Future<void> updateRoom(int id, int locationId, String name, String floor);
  Future<void> assignDevice(int deviceId, int locationId, int? roomId);
  Future<void> moveAssignment(int id, int locationId, int? roomId);
  Future<void> deleteLocation(int id);
  Future<void> deleteRoom(int id);
  Future<void> deleteAssignment(int id);
}
