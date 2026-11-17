import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String userKey = 'user_data';

  Future<void> saveUserData(Map<String, dynamic> data) async {
    await _storage.write(key: userKey, value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: userKey);

    if (data == null || data.isEmpty) {
      return null;
    }

    return jsonDecode(data) as Map<String, dynamic>;
  }

    Future<String> getFarmerId() async {
    final userData = await getUserData();

    return userData?['user_id']?.toString() ?? '';
  }

  Future<void> deleteUserData() async {
    await _storage.delete(key: userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
