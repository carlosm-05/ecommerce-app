import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            FlutterSecureStorage(
              aOptions: const AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
