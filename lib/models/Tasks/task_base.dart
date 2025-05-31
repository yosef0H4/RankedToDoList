import 'package:to_do_9/models/gamefiy/task_rarity.dart';

enum CompletionState {
  notStarted,
  completed,
  failed,
}

abstract class TaskBase {
  String name;
  CompletionState state;
  List<TaskBase> subTasks;
  DateTime? deadLine;
  TaskRarity rarity;
  late bool isDeadLineInherited;

  TaskBase({
    required this.name,
    required this.subTasks,
    this.state = CompletionState.notStarted,
    this.deadLine,
    this.rarity = TaskRarity.common,
    this.isDeadLineInherited = false,
  });

  // Convert TaskBase properties to JSON
  // Note: This doesn't handle subtasks or type - those are handled by subclasses
  Map<String, dynamic> toJsonBase() {
    return {
      'name': name,
      'state': state.index,
      'deadLine': deadLine?.toIso8601String(),
      'rarity': rarity.index,
      'isDeadLineInherited': isDeadLineInherited,
    };
  }

  // Abstract method that must be implemented by subclasses
  Map<String, dynamic> toJson();

  // Kept for backwards compatibility
  bool get isCompletedBasedOnSubtasks {
    if (subTasks.isEmpty) {
      return state == CompletionState.completed;
    }

    for (var subtask in subTasks) {
      if (subtask.state != CompletionState.completed) {
        return false;
      }
    }
    return true;
  }

  // Kept for backwards compatibility
  bool get isFailedBasedOnSubtasks {
    if (subTasks.isEmpty) {
      return state == CompletionState.failed;
    }

    for (var subtask in subTasks) {
      if (subtask.state == CompletionState.failed) {
        return true;
      }
    }
    return false;
  }

  /// Calculate the status based on subtasks
  CompletionState calculateStatusFromSubtasks() {
    if (subTasks.isEmpty) {
      return state;
    }

    bool anyFailed = false;
    bool allCompleted = true;

    for (var subtask in subTasks) {
      if (subtask.state == CompletionState.failed) {
        anyFailed = true;
        break;
      } else if (subtask.state != CompletionState.completed) {
        allCompleted = false;
      }
    }

    if (anyFailed) return CompletionState.failed;
    if (allCompleted) return CompletionState.completed;
    return CompletionState.notStarted;
  }

  void setCompleted() {
    setCompletionStatus(CompletionState.completed);
  }

  void setFailed() {
    setCompletionStatus(CompletionState.failed);
  }

  void resetStatus() {
    setCompletionStatus(CompletionState.notStarted);
  }

  void setCompletionStatus(CompletionState status) {
    state = status;

    // Downward propagation
    for (var subtask in subTasks) {
      subtask.state = status;

      if (subtask.subTasks.isNotEmpty) {
        subtask.setCompletionStatus(status);
      }
    }
  }

  bool checkIfDeadLineEnded() {
    if (deadLine == null) return false;
    final now = DateTime.now();
    return (now.isAfter(deadLine!));
  }

  static DateTime? newTimeAfterNow(DateTime? oldTime) {
    if (oldTime == null) return null;

    final now = DateTime.now();
    DateTime newTime =
        DateTime(now.year, now.month, now.day, oldTime.hour, oldTime.minute);

    if (newTime.isBefore(now)) {
      newTime = newTime.add(const Duration(days: 1));
    }
    return newTime;
  }

  void createNewDeadLine() {
    deadLine = newTimeAfterNow(deadLine);
  }

  void updateTaskOnDeadline() {
    if (checkIfDeadLineEnded()) {
      if (state == CompletionState.notStarted) setFailed();
      createNewDeadLine();
    }
  }

  void updateDeadline(DateTime? newDeadline) {
    deadLine = newDeadline;
  }

  void sortTasksByDeadline() {
    // Sort current tasks by deadline
    subTasks.sort((a, b) {
      if (a.deadLine == null && b.deadLine == null) return 0;
      if (a.deadLine == null) return 1;
      if (b.deadLine == null) return -1;
      return a.deadLine!.compareTo(b.deadLine!);
    });

    // Recursively sort subtasks
    for (var task in subTasks) {
      task.sortTasksByDeadline();
    }
  }

  int getValue(int midRange, int multiplier) {
    int total = midRange * multiplier * rarity.multiplier;
    for (TaskBase subTask in subTasks) {
      total += subTask.getValue(midRange, multiplier);
    }
    return total;
  }
}
