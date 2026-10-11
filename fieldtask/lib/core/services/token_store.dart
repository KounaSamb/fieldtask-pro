import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage securise du jeton (JWT simule) de la session.
class TokenStore {
  TokenStore._();
  static const _key = 'auth_token';
  static const _storage = FlutterSecureStorage();

  /// Passe a true si le stockage securise ne fonctionne pas sur la plateforme.
  static bool unavailable = false;

  static Future<void> save(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      unavailable = true;
    }
  }

  static Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      unavailable = true;
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}