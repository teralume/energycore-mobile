import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/workplace_models.dart';
import '../domain/workplace_repository.dart';

final class WorkplaceApiRepository implements WorkplaceRepository {
  const WorkplaceApiRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<AddressSuggestion>> searchAddresses(
    String query,
    String language,
  ) async {
    if (query.trim().length < 3) return const [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'limit': '5',
      'addressdetails': '1',
      'accept-language': language,
      'q': query.trim(),
    });
    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'EnergyCore-Mobile/1.0'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (place) => AddressSuggestion(
            displayName: jsonString(place['display_name']),
            latitude: double.tryParse(jsonString(place['lat'])) ?? 0,
            longitude: double.tryParse(jsonString(place['lon'])) ?? 0,
          ),
        )
        .where((place) => place.displayName.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<WorkplaceLocation>> locations() async =>
      jsonList(await _api.get('/workplace/locations'))
          .map(
            (json) => WorkplaceLocation(
              id: jsonInt(json['id']),
              name: jsonString(json['name']),
              address: jsonString(json['address']),
              type: jsonString(json['type'], 'HOME'),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<WorkplaceRoom>> rooms() async =>
      jsonList(await _api.get('/workplace/rooms'))
          .map(
            (json) => WorkplaceRoom(
              id: jsonInt(json['id']),
              locationId: jsonInt(json['locationId']),
              name: jsonString(json['name']),
              floor: jsonString(json['floor']),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<DeviceAssignment>> assignments() async =>
      jsonList(await _api.get('/workplace/device-assignments'))
          .map(
            (json) => DeviceAssignment(
              id: jsonInt(json['id']),
              deviceId: jsonInt(json['deviceId']),
              locationId: jsonInt(json['locationId']),
              roomId: json['roomId'] is num ? jsonInt(json['roomId']) : null,
              assignedAt: DateTime.tryParse(jsonString(json['assignedAt'])),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> createLocation(String name, String address, String type) =>
      _api.postVoid(
        '/workplace/locations',
        body: {
          'name': name,
          'address': address,
          'type': type,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

  @override
  Future<void> updateLocation(
    int id,
    String name,
    String address,
    String type,
  ) => _api.patchVoid(
    '/workplace/locations/$id',
    body: {'name': name, 'address': address, 'type': type},
  );

  @override
  Future<void> createRoom(int locationId, String name, String floor) =>
      _api.postVoid(
        '/workplace/rooms',
        body: {
          'locationId': locationId,
          'name': name,
          'floor': floor,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

  @override
  Future<void> updateRoom(int id, int locationId, String name, String floor) =>
      _api.patchVoid(
        '/workplace/rooms/$id',
        body: {'locationId': locationId, 'name': name, 'floor': floor},
      );

  @override
  Future<void> assignDevice(int deviceId, int locationId, int? roomId) =>
      _api.postVoid(
        '/workplace/device-assignments',
        body: {
          'deviceId': deviceId,
          'locationId': locationId,
          'roomId': roomId,
          'assignedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );

  @override
  Future<void> moveAssignment(int id, int locationId, int? roomId) =>
      _api.patchVoid(
        '/workplace/device-assignments/$id',
        body: {'locationId': locationId, 'roomId': roomId},
      );

  @override
  Future<void> deleteLocation(int id) =>
      _api.deleteVoid('/workplace/locations/$id');

  @override
  Future<void> deleteRoom(int id) => _api.deleteVoid('/workplace/rooms/$id');

  @override
  Future<void> deleteAssignment(int id) =>
      _api.deleteVoid('/workplace/device-assignments/$id');
}
