import '../../shared/infrastructure/network/api_client.dart';
import '../../shared/infrastructure/network/json_readers.dart';
import '../domain/device_control_models.dart';
import '../domain/device_control_repository.dart';

final class DeviceControlApiRepository implements DeviceControlRepository {
  const DeviceControlApiRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Device>> devices() async => jsonList(await _api.get('/devices'))
      .map(
        (json) => Device(
          id: jsonInt(json['id']),
          name: jsonString(json['name']),
          room: jsonString(json['room'], 'Unassigned'),
          type: jsonString(json['type'], 'OTHER'),
          powerWatts: jsonDouble(json['powerWatts']),
          status: jsonString(json['status'], 'OFF'),
          createdAt: DateTime.tryParse(jsonString(json['createdAt'])),
        ),
      )
      .toList(growable: false);

  @override
  Future<List<DeviceGroup>> groups() async =>
      jsonList(await _api.get('/device-groups'))
          .map(
            (json) => DeviceGroup(
              id: jsonInt(json['id']),
              name: jsonString(json['name']),
              description: jsonString(json['description']),
              deviceIds: jsonIntList(json['deviceIds']),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<Routine>> routines() async =>
      jsonList(await _api.get('/routines'))
          .map(
            (json) => Routine(
              id: jsonInt(json['id']),
              name: jsonString(json['name']),
              action: jsonString(json['action'], 'TURN_ON'),
              time: jsonString(json['time']),
              targetName: jsonString(json['targetName'], 'Device'),
              enabled: jsonBool(json['enabled']),
              applicableDeviceCount: jsonInt(json['applicableDeviceCount'], 1),
              targetType: jsonString(json['targetType'], 'DEVICE'),
              targetId: jsonInt(json['targetId'], jsonInt(json['deviceId'])),
              repeatType: jsonString(json['repeatType'], 'DAILY'),
              daysOfWeek: jsonString(json['daysOfWeek']),
              intervalDays: json['intervalDays'] is num
                  ? jsonInt(json['intervalDays'])
                  : null,
              startsOn: DateTime.tryParse(jsonString(json['startsOn'])),
              blockedDeviceCount: jsonInt(json['blockedDeviceCount']),
            ),
          )
          .toList(growable: false);

  @override
  Future<List<OperationMode>> modes() async =>
      jsonList(await _api.get('/operation-modes'))
          .map(
            (json) => OperationMode(
              id: jsonInt(json['id']),
              locationId: jsonInt(json['locationId']),
              name: jsonString(json['name']),
              description: jsonString(json['description']),
              status: jsonString(json['status'], 'INACTIVE'),
              deviceIds: jsonIntList(json['deviceIds']),
              allDay: jsonBool(json['allDay']),
              startsAt: jsonString(json['startsAt']),
              endsAt: jsonString(json['endsAt']),
              roomIds: jsonIntList(json['roomIds']),
              groupIds: jsonIntList(json['groupIds']),
              turnOnDeviceIds: jsonIntList(json['turnOnDeviceIds']),
              turnOffDeviceIds: jsonIntList(json['turnOffDeviceIds']),
              keepOnDeviceIds: jsonIntList(json['keepOnDeviceIds']),
              routineIds: jsonIntList(json['routineIds']),
              goalIds: jsonIntList(json['goalIds']),
              lastActivatedAt: DateTime.tryParse(
                jsonString(json['lastActivatedAt']),
              ),
            ),
          )
          .toList(growable: false);

  @override
  Future<void> toggleDevice(int id) =>
      _api.patchVoid('/devices/$id/toggle', body: const {});

  @override
  Future<void> createDevice({
    required String name,
    required String room,
    required String type,
    required double powerWatts,
  }) => _api.postVoid(
    '/devices',
    body: {
      'name': name,
      'room': room,
      'type': type,
      'powerWatts': powerWatts,
      'status': 'OFF',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
  );

  @override
  Future<void> updateDevice({
    required int id,
    required String name,
    required String room,
    required String type,
    required double powerWatts,
  }) => _api.patchVoid(
    '/devices/$id',
    body: {'name': name, 'room': room, 'type': type, 'powerWatts': powerWatts},
  );

  @override
  Future<void> deleteDevice(int id) => _api.deleteVoid('/devices/$id');

  @override
  Future<void> pairDevice({
    required String code,
    String? alias,
    String? room,
  }) => _api.postVoid(
    '/devices/pairings',
    body: {'pairingCode': code, 'alias': alias, 'room': room},
  );

  @override
  Future<void> createGroup({
    required String name,
    required String description,
    required List<int> deviceIds,
  }) => _api.postVoid(
    '/device-groups',
    body: {
      'name': name,
      'description': description,
      'deviceIds': deviceIds,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
  );

  @override
  Future<void> executeGroup(int id, String status) =>
      _api.patchVoid('/device-groups/$id/execute', body: {'status': status});

  @override
  Future<void> updateGroup({
    required int id,
    required String name,
    required String description,
    required List<int> deviceIds,
  }) => _api.patchVoid(
    '/device-groups/$id',
    body: {'name': name, 'description': description, 'deviceIds': deviceIds},
  );

  @override
  Future<void> deleteGroup(int id) => _api.deleteVoid('/device-groups/$id');

  @override
  Future<void> createRoutine(CreateRoutineInput input) => _api.postVoid(
    '/routines',
    body: {
      'deviceId': input.targetType == 'DEVICE' ? input.targetId : null,
      'groupId': input.targetType == 'GROUP' ? input.targetId : null,
      'targetType': input.targetType,
      'targetId': input.targetId,
      'name': input.name,
      'action': input.action,
      'time': input.time,
      'repeatType': input.repeatType,
      'daysOfWeek': input.daysOfWeek.join(','),
      'intervalDays': input.intervalDays,
      'startsOn': input.startsOn?.toIso8601String().split('T').first,
      'enabled': true,
    },
  );

  @override
  Future<void> toggleRoutine(int id, bool enabled) =>
      _api.patchVoid('/routines/$id/status', body: {'enabled': enabled});

  @override
  Future<void> executeRoutine(int id) =>
      _api.patchVoid('/routines/$id/execute', body: const {});

  @override
  Future<void> deleteRoutine(int id) => _api.deleteVoid('/routines/$id');

  @override
  Future<void> activateMode(int id) =>
      _api.patchVoid('/operation-modes/$id/activate', body: const {});

  @override
  Future<OperationModePreview> previewMode(int id) async {
    final json = jsonObject(await _api.get('/operation-modes/$id/preview'));
    return OperationModePreview(
      locationName: jsonString(json['locationName']),
      affectedDeviceIds: jsonIntList(json['affectedDeviceIds']),
      ignoredDeviceIds: [
        ...jsonIntList(json['ignoredRemovedDeviceIds']),
        ...jsonIntList(json['ignoredMaintenanceDeviceIds']),
      ],
      evidence: jsonString(json['evidence']),
      explanation: jsonString(json['explanation']),
      recommendedAction: jsonString(json['recommendedAction']),
    );
  }

  @override
  Future<void> archiveMode(int id) => _api.deleteVoid('/operation-modes/$id');

  @override
  Future<void> createMode(CreateOperationModeInput input) => _api.postVoid(
    '/operation-modes',
    body: {
      'locationId': input.locationId,
      'name': input.name,
      'description': input.description,
      'roomIds': input.roomIds,
      'groupIds': input.groupIds,
      'deviceIds': input.deviceIds,
      'turnOnDeviceIds': input.turnOnDeviceIds,
      'turnOffDeviceIds': input.turnOffDeviceIds,
      'keepOnDeviceIds': input.keepOnDeviceIds,
      'routineIds': input.routineIds,
      'routinesToEnableIds': input.routinesToEnableIds,
      'routinesToDisableIds': input.routinesToDisableIds,
      'goalIds': input.goalIds,
      'internalRoutines': input.internalRoutines
          .map(
            (routine) => {
              'name': routine.name,
              'targetType': routine.targetType,
              'targetId': routine.targetId,
              'action': routine.action,
              'triggerTime': routine.triggerTime,
              'enabled': routine.enabled,
            },
          )
          .toList(growable: false),
      'allDay': input.allDay,
      'startsAt': input.startsAt,
      'endsAt': input.endsAt,
      'ruleProfileId': input.ruleProfileId,
      'preferenceId': input.preferenceId,
      'applyRuleProfile': input.applyRuleProfile,
      'applyNotificationPreference': input.applyNotificationPreference,
      'applyRoutines': input.applyRoutines,
      'preserveCriticalSound': input.preserveCriticalSound,
    },
  );
}
