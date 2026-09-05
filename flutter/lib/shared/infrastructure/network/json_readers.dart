import '../../domain/app_failure.dart';

Map<String, dynamic> jsonObject(Object? value, {String? message}) {
  if (value is Map<String, dynamic>) return value;
  throw AppFailure(
    message ?? 'The server returned an unexpected response.',
    kind: FailureKind.server,
  );
}

List<Map<String, dynamic>> jsonList(Object? value, {String? message}) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  throw AppFailure(
    message ?? 'The server returned an unexpected response.',
    kind: FailureKind.server,
  );
}

String jsonString(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

int jsonInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double jsonDouble(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;

bool jsonBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

List<int> jsonIntList(Object? value) => value is List
    ? value.map((item) => jsonInt(item)).toList(growable: false)
    : const [];
