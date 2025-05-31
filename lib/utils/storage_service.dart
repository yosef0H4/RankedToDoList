// utils/storage_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:to_do_9/core/logger.dart';
import 'package:to_do_9/models/Tasks/root_task.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/user.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _fileName = 'user_data.json';

  // Helper method to create the right type of task from JSON
  static TaskBase taskFromJson(Map<String, dynamic> json, [TaskBase? parent]) {
    final String type = json['type'];
    switch (type) {
      case 'root':
        return RootTask.fromJson(json);
      case 'rotating_task':
        if (parent == null) {
          throw Exception(
              'Parent task is required for RotatingTask deserialization');
        }
        return RotatingTask.fromJson(json, parent);
      case 'task':
      default:
        if (parent == null) {
          throw Exception('Parent task is required for Task deserialization');
        }
        return Task.fromJson(json, parent);
    }
  }

  // Save user data to local storage
  static Future<bool> saveUser(User user) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      // Convert user to JSON
      final userData = user.toJson();
      final jsonString = jsonEncode(userData);

      // Write to file
      await file.writeAsString(jsonString);

      AppLogger.info('User data saved successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save user data', e, stackTrace);
      return false;
    }
  }

  // Load user data from local storage
  static Future<User?> loadUser() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      // Check if file exists
      if (!await file.exists()) {
        AppLogger.info('No saved user data found, creating new user');
        return null;
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final userData = jsonDecode(jsonString);

      // Create user from JSON
      final user = User.fromJson(userData);

      AppLogger.info('User data loaded successfully');
      return user;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user data', e, stackTrace);
      // Return null to indicate failure, app will create a new user
      return null;
    }
  }

  // Delete saved user data (useful for testing or reset functionality)
  static Future<bool> deleteUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        await file.delete();
        AppLogger.info('User data deleted successfully');
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete user data', e, stackTrace);
      return false;
    }
  }
}
