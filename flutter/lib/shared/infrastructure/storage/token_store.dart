import 'package:flutter/services.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

final class SecureTokenStore implements TokenStore {
  static const _channel = MethodChannel(
    'com.teralume.energycore/secure_storage',
  );

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String token) =>
      _channel.invokeMethod<void>('write', {'token': token});

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');
}
