import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  static Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  static Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}
