import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'local_data_recovery.dart';

class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  static Future<String?> readSafely(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error, stackTrace) {
      LocalDataRecovery.log('secureRead:$key', error, stackTrace);
      try {
        await _storage.delete(key: key);
      } catch (deleteError, deleteStackTrace) {
        LocalDataRecovery.log(
          'secureDeleteAfterReadFailure:$key',
          deleteError,
          deleteStackTrace,
        );
      }
      return null;
    }
  }

  static Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  static Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}
