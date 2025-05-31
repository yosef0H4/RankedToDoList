import 'dart:convert';

import 'package:to_do_9/core/logger.dart';
import 'package:to_do_9/models/user.dart';
import 'package:to_do_9/utils/storage_service.dart';

/// Extension methods for StorageService to add import/export functionality
extension StorageServiceExtensions on StorageService {
  /// Export user data as a JSON string
  static Future<String> exportUserDataAsJson(User user) async {
    try {
      final userData = user.toJson();
      return jsonEncode(userData);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export user data', e, stackTrace);
      return "";
    }
  }

  /// Import user data from a JSON string
  static Future<User?> importUserDataFromJson(String jsonData) async {
    try {
      final userData = jsonDecode(jsonData);
      final user = User.fromJson(userData);
      return user;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to import user data', e, stackTrace);
      return null;
    }
  }
}
