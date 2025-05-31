// models/Tasks/rotating_task.dart
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';

class RotatingTask extends Task {
  int currentIndex = 0;

  RotatingTask({
    required super.name,
    required super.subTasks,
    required super.parent,
    super.deadLine,
    super.rarity = TaskRarity.common,
    this.currentIndex = 0,
  });

  // Create a RotatingTask from JSON with parent reference
  factory RotatingTask.fromJson(
      Map<String, dynamic> json, TaskBase parentTask) {
    // Create a RotatingTask with the base properties and parent reference
    final task = RotatingTask(
      name: json['name'],
      deadLine:
          json['deadLine'] != null ? DateTime.parse(json['deadLine']) : null,
      subTasks: [], // Initialize with empty list, will fill below
      parent: parentTask,
      rarity: TaskRarity.values[json['rarity']],
      currentIndex: json['currentIndex'] ?? 0,
    );

    // Set the state
    task.state = CompletionState.values[json['state']];

    // Set inherited deadline flag
    task.isDeadLineInherited = json['isDeadLineInherited'];

    // Now deserialize all subtasks
    if (json['subTasks'] != null) {
      final subtasks = List<Map<String, dynamic>>.from(json['subTasks']);
      for (var subtaskJson in subtasks) {
        // Create subtask with the appropriate type
        TaskBase subtask;
        if (subtaskJson['type'] == 'rotating_task') {
          subtask = RotatingTask.fromJson(subtaskJson, task);
        } else {
          subtask = Task.fromJson(subtaskJson, task);
        }
        task.subTasks.add(subtask);
      }
    }

    return task;
  }

  // Override toJson to include RotatingTask-specific properties
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();

    // Update type identifier for deserialization
    data['type'] = 'rotating_task';
    data['currentIndex'] = currentIndex;

    return data;
  }

  // Get the current active subtask
  TaskBase? get currentSubtask {
    if (subTasks.isEmpty) return null;

    // Ensure currentIndex is valid
    if (currentIndex >= subTasks.length) {
      currentIndex = 0;
    }

    return subTasks[currentIndex];
  }

  // Advance to the next subtask
  void advanceToNextSubtask() {
    if (subTasks.isEmpty) return;

    currentIndex = (currentIndex + 1) % subTasks.length;
  }

  // Override the completion behavior to advance rotation
  @override
  void setCompleted() {
    // Handle completion of this rotating task
    super.setCompleted();

    // Advance to the next subtask for tomorrow
    advanceToNextSubtask();
  }

  @override
  void updateTaskOnDeadline() {
    if (checkIfDeadLineEnded()) {
      if (state == CompletionState.notStarted) setFailed();
      createNewDeadLine();
    }
  }
}
