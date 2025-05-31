import 'package:flutter/material.dart';
import 'package:to_do_9/core/command.dart';
import 'package:to_do_9/core/commands.dart';
import 'package:to_do_9/core/logger.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/models/user.dart';
import 'package:to_do_9/utils/storage_service.dart';
import 'package:to_do_9/utils/storage_service_extensions.dart';

class UserProvider extends ChangeNotifier {
  late User _user;
  bool _isInitialized = false;
  bool _isSaving = false;

  // Undo/redo stacks
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Maximum history size to prevent excessive memory usage
  static const int MAX_HISTORY_SIZE = 20;

  UserProvider() {
    // Initialize with a default user initially
    _user = User(
      rootTaskName: 'Daily Tasks',
      rootTaskDeadline: DateTime.now().add(const Duration(hours: 12)),
      rootTaskRarity: TaskRarity.common,
    );

    // Load saved data
    _loadUserData();
  }

  // Returns whether the user data is loaded
  bool get isInitialized => _isInitialized;

  User get user => _user;

  // Command execution method
  void executeCommand(Command command) {
    // Execute command
    command.execute();

    // Add to undo stack
    _undoStack.add(command);

    // Clear redo stack since we've taken a new action
    _redoStack.clear();

    // Limit stack size
    if (_undoStack.length > MAX_HISTORY_SIZE) {
      _undoStack.removeAt(0);
    }

    // Save and notify
    _saveUserData();
    notifyListeners();

    AppLogger.info('Command executed: ${command.description}');
  }

  // Undo the last command
  void undo() {
    if (!canUndo) return;

    // Get the last command
    final command = _undoStack.removeLast();

    // Undo it
    command.undo();

    // Add to redo stack
    _redoStack.add(command);

    // Save and notify
    _saveUserData();
    notifyListeners();

    AppLogger.info('Command undone: ${command.description}');
  }

  // Redo the last undone command
  void redo() {
    if (!canRedo) return;

    // Get the last undone command
    final command = _redoStack.removeLast();

    // Execute it again
    command.execute();

    // Add back to undo stack
    _undoStack.add(command);

    // Save and notify
    _saveUserData();
    notifyListeners();

    AppLogger.info('Command redone: ${command.description}');
  }

  // Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final loadedUser = await StorageService.loadUser();

      if (loadedUser != null) {
        _user = loadedUser;
        AppLogger.info('User data loaded successfully');
      } else {
        AppLogger.info('No saved user data found, using default user');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading user data', e, stackTrace);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save user data to storage
  Future<void> _saveUserData() async {
    // Prevent multiple simultaneous saves
    if (_isSaving) return;

    _isSaving = true;
    try {
      final success = await StorageService.saveUser(_user);
      if (success) {
        AppLogger.info('User data saved successfully');
      } else {
        AppLogger.warning('Failed to save user data');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error saving user data', e, stackTrace);
    } finally {
      _isSaving = false;
    }
  }

  // Export user data as JSON string (useful for sharing or backup)
  Future<String> exportUserData() async {
    return StorageServiceExtensions.exportUserDataAsJson(_user);
  }

  // Import user data from JSON string
  Future<bool> importUserData(String jsonData) async {
    try {
      final newUser =
          await StorageServiceExtensions.importUserDataFromJson(jsonData);
      if (newUser != null) {
        _user = newUser;

        // Clear undo/redo stacks when importing new data
        _undoStack.clear();
        _redoStack.clear();

        await _saveUserData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Error importing user data', e, stackTrace);
      return false;
    }
  }

  // Reset user data (useful for testing or user-requested reset)
  Future<void> resetUserData() async {
    await StorageService.deleteUserData();
    _user = User(
      rootTaskName: 'Daily Tasks',
      rootTaskDeadline: DateTime.now().add(const Duration(hours: 12)),
      rootTaskRarity: TaskRarity.common,
    );

    // Clear undo/redo stacks when resetting
    _undoStack.clear();
    _redoStack.clear();

    notifyListeners();
  }

  // Task status methods using commands
  void updateTaskStatus(TaskBase task, CompletionState status) {
    executeCommand(UpdateTaskStatusCommand(
      user: _user,
      task: task,
      newStatus: status,
    ));
  }

  void completeTask(TaskBase task) {
    updateTaskStatus(task, CompletionState.completed);
  }

  void failTask(TaskBase task) {
    updateTaskStatus(task, CompletionState.failed);
  }

  void resetTask(TaskBase task) {
    updateTaskStatus(task, CompletionState.notStarted);
  }

  // Task management methods using commands
  void updateRootTask({
    String? name,
    DateTime? deadLine,
    TaskRarity? rarity,
  }) {
    executeCommand(UpdateRootTaskCommand(
      user: _user,
      name: name,
      deadLine: deadLine,
      rarity: rarity,
    ));
  }

  void addTask({
    required String name,
    required TaskBase parent,
    DateTime? deadLine,
    TaskRarity rarity = TaskRarity.common,
    bool isRotating = false,
  }) {
    executeCommand(AddTaskCommand(
      user: _user,
      name: name,
      parent: parent,
      deadLine: deadLine,
      rarity: rarity,
      isRotating: isRotating,
    ));
  }

  void updateTask({
    required Task task,
    String? name,
    DateTime? deadLine,
    TaskRarity? rarity,
    bool? inheritDeadline,
  }) {
    executeCommand(UpdateTaskCommand(
      user: _user,
      task: task,
      name: name,
      deadLine: deadLine,
      rarity: rarity,
      inheritDeadline: inheritDeadline,
    ));
  }

  void reparentTask({
    required Task task,
    required TaskBase newParent,
    String? name,
    DateTime? deadLine,
    TaskRarity? rarity,
    bool? inheritDeadline,
  }) {
    executeCommand(ReparentTaskCommand(
      user: _user,
      task: task,
      newParent: newParent,
      name: name,
      deadLine: deadLine,
      rarity: rarity,
      inheritDeadline: inheritDeadline,
    ));
  }

  void deleteTask(Task task) {
    executeCommand(DeleteTaskCommand(
      user: _user,
      task: task,
    ));
  }

  void checkDeadlines() {
    _user.checkDeadlines();
    _saveUserData();
    notifyListeners();
  }

  // Task utility methods
  List<TaskBase> getAllTasks() {
    return _user.getAllTasks();
  }

  List<TaskBase> getLeafTasks() {
    return _user.getLeafTasks();
  }

  List<TaskBase> getTasksByState(CompletionState state) {
    return _user.getTasksByState(state);
  }

  List<TaskBase> getUpcomingTasks() {
    return _user.getUpcomingTasks();
  }

  // Rank information methods
  double getProgressToNextRank() {
    return _user.getProgressToNextRank();
  }

  int getPointsToNextRank() {
    return _user.getPointsToNextRank();
  }

  String getCurrentRankDisplayName() {
    return _user.getCurrentRankDisplayName();
  }

  int getCurrentMMR() {
    return _user.getCurrentMMR();
  }

  int getThreshold() {
    return _user.getThreshold();
  }

  void advanceRotation(RotatingTask task, {int? toIndex}) {
    executeCommand(AdvanceRotationCommand(
      user: _user,
      task: task,
      specificIndex: toIndex,
    ));
  }

  // Get active tasks for dashboard
  List<TaskBase> getActiveLeafTasks() {
    final allLeafTasks = _user.getLeafTasks();
    List<TaskBase> result = [];

    // First collect all rotating tasks to reference later
    final rotatingTasks =
        _user.getAllTasks().whereType<RotatingTask>().toList();
    final activeSubtaskIds = rotatingTasks
        .map((rt) => rt.currentSubtask?.hashCode)
        .where((id) => id != null)
        .toSet();

    for (var task in allLeafTasks) {
      bool isSubtaskOfRotating = false;

      // Check if this task is a subtask of any rotating task
      if (task is Task) {
        var parent = task.parent;
        while (parent is Task) {
          if (parent is RotatingTask) {
            isSubtaskOfRotating = true;
            // Only add if this is the active subtask
            if (activeSubtaskIds.contains(task.hashCode)) {
              result.add(task);
            }
            break;
          }
          parent = (parent as Task).parent;
        }
      }

      // Add non-rotating tasks
      if (!isSubtaskOfRotating) {
        result.add(task);
      }
    }

    return result;
  }
}
