final class Device {
  const Device({
    required this.id,
    required this.name,
    required this.room,
    required this.type,
    required this.powerWatts,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String name;
  final String room;
  final String type;
  final double powerWatts;
  final String status;
  final DateTime? createdAt;

  bool get isOn => status.toUpperCase() == 'ON';
  bool get isUnavailable =>
      const ['REMOVED', 'MAINTENANCE'].contains(status.toUpperCase());
}

final class DeviceGroup {
  const DeviceGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.deviceIds,
  });

  final int id;
  final String name;
  final String description;
  final List<int> deviceIds;
}

final class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.action,
    required this.time,
    required this.targetName,
    required this.enabled,
    required this.applicableDeviceCount,
    this.targetType = 'DEVICE',
    this.targetId = 0,
    this.repeatType = 'DAILY',
    this.daysOfWeek = '',
    this.intervalDays,
    this.startsOn,
    this.blockedDeviceCount = 0,
  });

  final int id;
  final String name;
  final String action;
  final String time;
  final String targetName;
  final bool enabled;
  final int applicableDeviceCount;
  final String targetType;
  final int targetId;
  final String repeatType;
  final String daysOfWeek;
  final int? intervalDays;
  final DateTime? startsOn;
  final int blockedDeviceCount;
}

final class CreateRoutineInput {
  const CreateRoutineInput({
    required this.name,
    required this.targetType,
    required this.targetId,
    required this.action,
    required this.time,
    required this.repeatType,
    required this.daysOfWeek,
    required this.intervalDays,
    required this.startsOn,
  });

  final String name;
  final String targetType;
  final int targetId;
  final String action;
  final String time;
  final String repeatType;
  final List<String> daysOfWeek;
  final int? intervalDays;
  final DateTime? startsOn;
}

final class OperationModeRoutineInput {
  const OperationModeRoutineInput({
    required this.name,
    required this.targetType,
    required this.targetId,
    required this.action,
    required this.triggerTime,
    this.enabled = true,
  });

  final String name;
  final String targetType;
  final int targetId;
  final String action;
  final String triggerTime;
  final bool enabled;
}

final class CreateOperationModeInput {
  const CreateOperationModeInput({
    required this.locationId,
    required this.name,
    required this.description,
    required this.roomIds,
    required this.groupIds,
    required this.deviceIds,
    required this.turnOnDeviceIds,
    required this.turnOffDeviceIds,
    required this.keepOnDeviceIds,
    required this.routineIds,
    required this.routinesToEnableIds,
    required this.routinesToDisableIds,
    required this.goalIds,
    required this.internalRoutines,
    required this.allDay,
    required this.startsAt,
    required this.endsAt,
    required this.ruleProfileId,
    required this.preferenceId,
    required this.applyRuleProfile,
    required this.applyNotificationPreference,
    required this.applyRoutines,
    required this.preserveCriticalSound,
  });

  final int locationId;
  final String name;
  final String description;
  final List<int> roomIds;
  final List<int> groupIds;
  final List<int> deviceIds;
  final List<int> turnOnDeviceIds;
  final List<int> turnOffDeviceIds;
  final List<int> keepOnDeviceIds;
  final List<int> routineIds;
  final List<int> routinesToEnableIds;
  final List<int> routinesToDisableIds;
  final List<int> goalIds;
  final List<OperationModeRoutineInput> internalRoutines;
  final bool allDay;
  final String startsAt;
  final String endsAt;
  final int? ruleProfileId;
  final int? preferenceId;
  final bool applyRuleProfile;
  final bool applyNotificationPreference;
  final bool applyRoutines;
  final bool preserveCriticalSound;
}

final class OperationMode {
  const OperationMode({
    required this.id,
    required this.locationId,
    required this.name,
    required this.description,
    required this.status,
    required this.deviceIds,
    required this.allDay,
    required this.startsAt,
    required this.endsAt,
    this.roomIds = const [],
    this.groupIds = const [],
    this.turnOnDeviceIds = const [],
    this.turnOffDeviceIds = const [],
    this.keepOnDeviceIds = const [],
    this.routineIds = const [],
    this.goalIds = const [],
    this.lastActivatedAt,
  });

  final int id;
  final int locationId;
  final String name;
  final String description;
  final String status;
  final List<int> deviceIds;
  final bool allDay;
  final String startsAt;
  final String endsAt;
  final List<int> roomIds;
  final List<int> groupIds;
  final List<int> turnOnDeviceIds;
  final List<int> turnOffDeviceIds;
  final List<int> keepOnDeviceIds;
  final List<int> routineIds;
  final List<int> goalIds;
  final DateTime? lastActivatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}

final class OperationModePreview {
  const OperationModePreview({
    required this.locationName,
    required this.affectedDeviceIds,
    required this.ignoredDeviceIds,
    required this.evidence,
    required this.explanation,
    required this.recommendedAction,
  });

  final String locationName;
  final List<int> affectedDeviceIds;
  final List<int> ignoredDeviceIds;
  final String evidence;
  final String explanation;
  final String recommendedAction;
}
