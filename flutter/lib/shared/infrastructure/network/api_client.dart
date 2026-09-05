import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/app_failure.dart';
import '../storage/token_store.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080/api/v1',
);

final class ApiClient {
  ApiClient(this._tokenStore, {http.Client? client})
    : _client = client ?? http.Client();

  final TokenStore _tokenStore;
  final http.Client _client;

  Future<Object?> get(String path) => _send('GET', path);

  Future<Object?> post(String path, {Map<String, Object?>? body}) =>
      _send('POST', path, body: body);

  Future<Object?> put(String path, {Map<String, Object?>? body}) =>
      _send('PUT', path, body: body);

  Future<Object?> patch(String path, {Map<String, Object?>? body}) =>
      _send('PATCH', path, body: body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<void> postVoid(String path, {Map<String, Object?>? body}) async {
    await _send('POST', path, body: body);
  }

  Future<void> patchVoid(String path, {Map<String, Object?>? body}) async {
    await _send('PATCH', path, body: body);
  }

  Future<void> deleteVoid(String path) async {
    await _send('DELETE', path);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    try {
      final token = await _tokenStore.read();
      final request = http.Request(method, Uri.parse('$apiBaseUrl$path'));
      request.headers['Accept'] = 'application/json';
      request.headers['Content-Type'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final message = _errorMessage(decoded, response.statusCode);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AppFailure(message, kind: FailureKind.unauthorized);
      }
      if (response.statusCode == 400 || response.statusCode == 422) {
        throw AppFailure(message, kind: FailureKind.validation);
      }
      throw AppFailure(message, kind: FailureKind.server);
    } on AppFailure {
      rethrow;
    } on SocketException catch (_) {
      throw const AppFailure(
        'No internet connection. Check your network and try again.',
        kind: FailureKind.offline,
      );
    } on TimeoutException catch (_) {
      throw const AppFailure(
        'The server took too long to respond. Check your connection.',
        kind: FailureKind.offline,
      );
    } on http.ClientException catch (_) {
      throw const AppFailure(
        'EnergyCore could not reach the server.',
        kind: FailureKind.offline,
      );
    } on FormatException catch (_) {
      throw const AppFailure(
        'The server returned an unexpected response.',
        kind: FailureKind.server,
      );
    }
  }

  String _errorMessage(Object? body, int statusCode) {
    if (body case final Map<String, dynamic> json) {
      for (final key in ['detail', 'message', 'title']) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return 'Request failed ($statusCode).';
  }
}
