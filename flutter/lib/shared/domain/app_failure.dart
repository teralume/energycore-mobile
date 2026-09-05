enum FailureKind { offline, unauthorized, validation, server, unknown }

class AppFailure implements Exception {
  const AppFailure(this.message, {this.kind = FailureKind.unknown});

  final String message;
  final FailureKind kind;

  bool get isOffline => kind == FailureKind.offline;

  @override
  String toString() => message;
}
