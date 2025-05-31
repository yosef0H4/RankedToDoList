import 'package:to_do_9/core/command.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/models/user.dart';

class AddTaskCommand implements Command {
  final User user;
  final String name;
  final TaskBase parent;
  final DateTime? deadLine;
  final TaskRarity rarity;
  final bool isRotating;

  TaskBase? _addedTask;

  AddTaskCommand({
    required this.user,
    required this.name,
    required this.parent,
    this.deadLine,
    this.rarity = TaskRarity.common,
    this.isRotating = false,
  });

  @override
  void execute() {
    user.addTask(
      name: name,
      parent: parent,
      deadLine: deadLine,
      rarity: rarity,
      isRotating: isRotating,
    );

    // Find the newly added task (should be the last one in parent's subtasks)
    if (parent.subTasks.isNotEmpty) {
      _addedTask = parent.subTasks.last;
    }
  }

  @override
  void undo() {
    if (_addedTask != null) {
      user.deleteTask(_addedTask! as Task);
    }
  }

  @override
  String get description => 'Add task: $name';
}

class DeleteTaskCommand implements Command {
  final User user;
  final Task task;

  // Save state for restoration
  late final TaskBase _parent;
  late final String _name;
  late final DateTime? _deadLine;
  late final TaskRarity _rarity;
  late final bool _isInherited;
  late final List<TaskBase> _subtasks;

  DeleteTaskCommand({
    required this.user,
    required this.task,
  }) {
    // Save task state before deletion
    _parent = task.parent;
    _name = task.name;
    _deadLine = task.deadLine;
    _rarity = task.rarity;
    _isInherited = task.isDeadLineInherited;
    _subtasks = List<TaskBase>.from(task.subTasks);
  }

  @override
  void execute() {
    user.deleteTask(task);
  }

  @override
  void undo() {
    // Recreate the task with original properties
    user.addTask(
      name: _name,
      parent: _parent,
      deadLine: _isInherited ? null : _deadLine,
      rarity: _rarity,
    );

    // Find the newly added task and restore its subtasks
    if (_parent.subTasks.isNotEmpty) {
      final newTask = _parent.subTasks.last as Task;
      newTask.subTasks.addAll(_subtasks);

      // Update parent references
      for (var subtask in _subtasks) {
        if (subtask is Task) {
          subtask.parent = newTask;
        }
      }
    }
  }

  @override
  String get description => 'Delete task: ${task.name}';
}

class UpdateTaskStatusCommand implements Command {
  final User user;
  final TaskBase task;
  final CompletionState newStatus;
  late final CompletionState _oldStatus;

  UpdateTaskStatusCommand({
    required this.user,
    required this.task,
    required this.newStatus,
  }) {
    _oldStatus = task.state;
  }

  @override
  void execute() {
    user.updateTaskStatus(task, newStatus);
  }

  @override
  void undo() {
    user.updateTaskStatus(task, _oldStatus);
  }

  @override
  String get description => 'Update status: ${task.name}';
}

class UpdateTaskCommand implements Command {
  final User user;
  final Task task;
  final String? name;
  final DateTime? deadLine;
  final TaskRarity? rarity;
  final bool? inheritDeadline;

  // Store original values
  late final String _oldName;
  late final DateTime? _oldDeadLine;
  late final TaskRarity _oldRarity;
  late final bool _oldInheritDeadline;

  UpdateTaskCommand({
    required this.user,
    required this.task,
    this.name,
    this.deadLine,
    this.rarity,
    this.inheritDeadline,
  }) {
    _oldName = task.name;
    _oldDeadLine = task.deadLine;
    _oldRarity = task.rarity;
    _oldInheritDeadline = task.isDeadLineInherited;
  }

  @override
  void execute() {
    user.updateTask(
      task: task,
      name: name,
      deadLine: deadLine,
      rarity: rarity,
      inheritDeadline: inheritDeadline,
    );
  }

  @override
  void undo() {
    user.updateTask(
      task: task,
      name: _oldName,
      deadLine: _oldInheritDeadline ? null : _oldDeadLine,
      rarity: _oldRarity,
      inheritDeadline: _oldInheritDeadline,
    );
  }

  @override
  String get description => 'Update task: ${task.name}';
}

class UpdateRootTaskCommand implements Command {
  final User user;
  final String? name;
  final DateTime? deadLine;
  final TaskRarity? rarity;

  // Store original values
  late final String _oldName;
  late final DateTime? _oldDeadLine;
  late final TaskRarity _oldRarity;

  UpdateRootTaskCommand({
    required this.user,
    this.name,
    this.deadLine,
    this.rarity,
  }) {
    _oldName = user.rootTask.name;
    _oldDeadLine = user.rootTask.deadLine;
    _oldRarity = user.rootTask.rarity;
  }

  @override
  void execute() {
    user.updateRootTask(
      name: name,
      deadLine: deadLine,
      rarity: rarity,
    );
  }

  @override
  void undo() {
    user.updateRootTask(
      name: _oldName,
      deadLine: _oldDeadLine,
      rarity: _oldRarity,
    );
  }

  @override
  String get description => 'Update root task';
}

class ReparentTaskCommand implements Command {
  final User user;
  final Task task;
  final TaskBase newParent;
  final String? name;
  final DateTime? deadLine;
  final TaskRarity? rarity;
  final bool? inheritDeadline;

  // Store original values
  late final TaskBase _oldParent;
  late final String _oldName;
  late final DateTime? _oldDeadLine;
  late final TaskRarity _oldRarity;
  late final bool _oldInheritDeadline;

  ReparentTaskCommand({
    required this.user,
    required this.task,
    required this.newParent,
    this.name,
    this.deadLine,
    this.rarity,
    this.inheritDeadline,
  }) {
    _oldParent = task.parent;
    _oldName = task.name;
    _oldDeadLine = task.deadLine;
    _oldRarity = task.rarity;
    _oldInheritDeadline = task.isDeadLineInherited;
  }

  @override
  void execute() {
    user.reparentTask(
      task: task,
      newParent: newParent,
      name: name,
      deadLine: deadLine,
      rarity: rarity,
      inheritDeadline: inheritDeadline,
    );
  }

  @override
  void undo() {
    user.reparentTask(
      task: task,
      newParent: _oldParent,
      name: _oldName,
      deadLine: _oldInheritDeadline ? null : _oldDeadLine,
      rarity: _oldRarity,
      inheritDeadline: _oldInheritDeadline,
    );
  }

  @override
  String get description => 'Move task: ${task.name}';
}

class AdvanceRotationCommand implements Command {
  final User user;
  final RotatingTask task;
  final int? specificIndex;

  late final int _oldIndex;

  AdvanceRotationCommand({
    required this.user,
    required this.task,
    this.specificIndex,
  }) {
    _oldIndex = task.currentIndex;
  }

  @override
  void execute() {
    user.advanceRotation(task, toIndex: specificIndex);
  }

  @override
  void undo() {
    task.currentIndex = _oldIndex;
  }

  @override
  String get description => 'Rotate task: ${task.name}';
}
