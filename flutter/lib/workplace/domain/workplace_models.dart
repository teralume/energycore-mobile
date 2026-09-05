final class WorkplaceLocation {
  const WorkplaceLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
  });

  final int id;
  final String name;
  final String address;
  final String type;
}

final class WorkplaceRoom {
  const WorkplaceRoom({
    required this.id,
    required this.locationId,
    required this.name,
    required this.floor,
  });

  final int id;
  final int locationId;
  final String name;
  final String floor;
}

final class DeviceAssignment {
  const DeviceAssignment({
    required this.id,
    required this.deviceId,
    required this.locationId,
    required this.roomId,
    required this.assignedAt,
  });

  final int id;
  final int deviceId;
  final int locationId;
  final int? roomId;
  final DateTime? assignedAt;
}

final class AddressSuggestion {
  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}
