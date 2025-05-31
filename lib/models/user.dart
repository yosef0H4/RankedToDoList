import 'package:flutter/material.dart';
import 'package:to_do_9/models/Tasks/root_task.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/gamefiy/rank.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/models/gamefiy/user_rank.dart';
import 'package:to_do_9/utils/task_utils.dart';

class User {
  late RootTask rootTask;
  late UserRank rank;

  User({
    String rootTaskName = 'Daily Tasks',
    DateTime? rootTaskDeadline,
    TaskRarity rootTaskRarity = TaskRarity.common,
    Rank initialRank = Rank.bronze,
    int initialMmr = 0,
  }) {
    // Initialize root task
    rootTask = RootTask(
      name: rootTaskName,
      subTasks: [],
      deadLine:
          rootTaskDeadline ?? DateTime.now().add(const Duration(hours: 12)),
      rarity: rootTaskRarity,
    );

    // Initialize user rank
    rank = UserRank(
      currentRank: initialRank,
      mmr: initialMmr,
    );

    // Calculate initial threshold based on the root task
    calculateRankThreshold();
  }

  // Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    final user = User();

    // Deserialize root task
    user.rootTask = RootTask.fromJson(json['rootTask']);

    // Deserialize rank
    user.rank = UserRank.fromJson(json['rank']);

    // Recalculate threshold after loading
    user.calculateRankThreshold();

    return user;
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'rootTask': rootTask.toJson(),
      'rank': rank.toJson(),
    };
  }

  // Recalculate threshold based on all available tasks
  void calculateRankThreshold() {
    rank.calculateDynamicThreshold(rootTask);
  }

  // Check all tasks' deadlines and update statuses
  void checkDeadlines() {
    // Store previous states to detect changes
    Map<TaskBase, CompletionState> previousStates = {};
    _collectTaskStates(rootTask, previousStates);

    // Update all tasks based on deadlines
    rootTask.updateTaskOnDeadline();
    _updateAllTasksDeadlines(rootTask);

    // Check for tasks that changed to failed state and subtract points
    _applyPointsForStateChanges(rootTask, previousStates);
  }

  // Helper method to collect current states of all tasks
  void _collectTaskStates(
      TaskBase task, Map<TaskBase, CompletionState> states) {
    states[task] = task.state;
    for (var subtask in task.subTasks) {
      _collectTaskStates(subtask, states);
    }
  }

  // Apply points based on state changes
  void _applyPointsForStateChanges(
      TaskBase task, Map<TaskBase, CompletionState> previousStates) {
    final previousState = previousStates[task];
    final currentState = task.state;

    // Only handle transitions to completed or failed (not transitions back to not started)
    if (previousState != currentState) {
      // Task newly completed
      if (currentState == CompletionState.completed &&
          previousState != CompletionState.completed) {
        updateTaskPoints(task, true);
      }
      // Task newly failed
      else if (currentState == CompletionState.failed &&
          previousState != CompletionState.failed) {
        updateTaskPoints(task, false);
      }
    }

    // Process all subtasks
    for (var subtask in task.subTasks) {
      _applyPointsForStateChanges(subtask, previousStates);
    }
  }

  void _updateAllTasksDeadlines(TaskBase task) {
    task.updateTaskOnDeadline();
    for (var subtask in task.subTasks) {
      _updateAllTasksDeadlines(subtask);
    }
  }

  // Consolidated points management method
  void updateTaskPoints(TaskBase task, bool isCompletion) {
    final points = rank.updatePointsForTask(task, isCompletion);
    final action = isCompletion ? "Awarded" : "Subtracted";
    final outcome = isCompletion ? "completing" : "failing";

    debugPrint('$action $points points for $outcome "${task.name}"');
  }

  // Task management methods
  void updateRootTask({
    String? name,
    DateTime? deadLine,
    TaskRarity? rarity,
  }) {
    if (name != null) rootTask.name = name;
    if (deadLine != null) rootTask.updateDeadline(deadLine);
    if (rarity != null) rootTask.rarity = rarity;
  }

  void addTask({
    required String name,
    required TaskBase parent,
    DateTime? deadLine,
    TaskRarity rarity = TaskRarity.common,
    bool isRotating = false,
  }) {
    final TaskBase newTask = isRotating
        ? RotatingTask(
            name: name,
            subTasks: [],
            parent: parent,
            deadLine: deadLine,
            rarity: rarity,
          )
        : Task(
            name: name,
            subTasks: [],
            parent: parent,
            deadLine: deadLine,
            rarity: rarity,
          );

    parent.subTasks.add(newTask);
    rootTask.sortTasksByDeadline();

    // Recalculate rank threshold when adding new tasks
    calculateRankThreshold();
  }

  void updateTask({
    required Task task,
    String? name,
    DateTime? deadLine,
    TaskRarity? rarity,
    bool? inheritDeadline,
  }) {
    if (name != null) task.name = name;
    if (rarity != null) task.rarity = rarity;

    if (inheritDeadline == true) {
      task.inheritDeadline();
    } else if (deadLine != null) {
      task.updateDeadline(deadLine);
    }

    rootTask.sortTasksByDeadline();
    calculateRankThreshold();
  }

  void reparentTask({
    required Task task,
    required TaskBase newParent,
    String? name,
    DateTime? deadLine,
    TaskRarity? rarity,
    bool? inheritDeadline,
  }) {
    // Remove from old parent
    final oldParent = task.parent;
    oldParent.subTasks.remove(task);

    // Update properties
    if (name != null) task.name = name;
    if (rarity != null) task.rarity = rarity;

    // Set new parent
    task.parent = newParent;

    // Handle deadline
    if (inheritDeadline == true) {
      task.inheritDeadline();
    } else if (deadLine != null) {
      task.updateDeadline(deadLine);
    }

    // Add to new parent
    newParent.subTasks.add(task);

    // Update sorting and threshold
    rootTask.sortTasksByDeadline();
    calculateRankThreshold();
  }

  void deleteTask(Task task) {
    final parent = task.parent;
    parent.subTasks.remove(task);

    // Recalculate rank threshold when removing tasks
    calculateRankThreshold();
  }

  void updateTaskStatus(TaskBase task, CompletionState status) {
    final previousState = task.state;

    // Set the new status
    switch (status) {
      case CompletionState.completed:
        task.setCompleted();
        break;
      case CompletionState.failed:
        task.setFailed();
        break;
      case CompletionState.notStarted:
        task.resetStatus();
        break;
    }

    // Update points if status changed to completed or failed
    if (previousState != status) {
      if (status == CompletionState.completed) {
        updateTaskPoints(task, true);
      } else if (status == CompletionState.failed) {
        updateTaskPoints(task, false);
      }
    }
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

  // Use TaskUtils for all task collection methods
  List<TaskBase> getAllTasks() {
    return TaskUtils.getAllTasks(rootTask);
  }

  List<TaskBase> getLeafTasks() {
    return TaskUtils.getLeafTasks(rootTask);
  }

  List<TaskBase> getTasksByState(CompletionState state) {
    return TaskUtils.getTasksByState(rootTask, state);
  }

  List<TaskBase> getUpcomingTasks() {
    return TaskUtils.getUpcomingTasks(rootTask);
  }

  // Rank information methods
  double getProgressToNextRank() {
    return rank.getProgressToNextRank();
  }

  int getPointsToNextRank() {
    return rank.pointsToNextRank();
  }

  String getCurrentRankDisplayName() {
    return rank.currentRank.displayName;
  }

  int getCurrentMMR() {
    return rank.mmr;
  }

  int getThreshold() {
    return rank.threshold;
  }

  void advanceRotation(RotatingTask task, {int? toIndex}) {
    if (toIndex != null) {
      if (toIndex < task.subTasks.length) {
        task.currentIndex = toIndex;
      }
    } else {
      task.advanceToNextSubtask();
    }
  }
}
