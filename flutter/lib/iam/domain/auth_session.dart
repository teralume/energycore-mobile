final class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    this.accessProfileId,
    this.accessProfileName,
  });

  final int id;
  final String fullName;
  final String email;
  final int? accessProfileId;
  final String? accessProfileName;
  final String status;

  bool hasPermission(String permission) {
    final profile = (accessProfileName ?? 'GUEST').trim().toUpperCase();
    final permissions = switch (profile) {
      'OWNER' => _ownerPermissions,
      'ADMIN' => _adminPermissions,
      'MEMBER' => _memberPermissions,
      _ => _guestPermissions,
    };
    return permissions.contains(permission);
  }
}

const _ownerPermissions = {
  'VIEW_HOME',
  'CONTROL_DEVICES',
  'MANAGE_DEVICES',
  'MANAGE_ROUTINES',
  'MANAGE_SPACES',
  'VIEW_ENERGY',
  'VIEW_REPORTS',
  'MANAGE_ALERTS',
  'MANAGE_SUPPORT',
  'MANAGE_BILLING',
  'MANAGE_ACCESS',
};

const _adminPermissions = {
  'VIEW_HOME',
  'CONTROL_DEVICES',
  'MANAGE_DEVICES',
  'MANAGE_ROUTINES',
  'MANAGE_SPACES',
  'VIEW_ENERGY',
  'VIEW_REPORTS',
  'MANAGE_ALERTS',
  'MANAGE_SUPPORT',
  'MANAGE_ACCESS',
};

const _memberPermissions = {
  'VIEW_HOME',
  'CONTROL_DEVICES',
  'MANAGE_DEVICES',
  'MANAGE_ROUTINES',
  'VIEW_ENERGY',
  'VIEW_REPORTS',
  'MANAGE_ALERTS',
  'MANAGE_SUPPORT',
};

const _guestPermissions = {'VIEW_HOME', 'CONTROL_DEVICES'};

final class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AuthenticatedUser user;
  final String token;
}
