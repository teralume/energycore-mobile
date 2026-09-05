final class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accessProfileId,
    required this.accessProfileName,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final int? accessProfileId;
  final String accessProfileName;
  final String status;
  final DateTime? createdAt;
}

final class AccessProfile {
  const AccessProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
  });

  final int id;
  final String name;
  final String description;
  final List<String> permissions;
}
