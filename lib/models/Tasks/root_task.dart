import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';

class RootTask extends TaskBase {
  RootTask({
    required super.name,
    required super.subTasks,
    required super.deadLine,
    super.rarity = TaskRarity.common,
  });

  // Create a RootTask from JSON
  factory RootTask.fromJson(Map<String, dynamic> json) {
    // Create a RootTask with the base properties
    final rootTask = RootTask(
      name: json['name'],
      deadLine:
          json['deadLine'] != null ? DateTime.parse(json['deadLine']) : null,
      subTasks: [], // Initialize with empty list, will fill below
      rarity: TaskRarity.values[json['rarity']],
    );

    // Set the state
    rootTask.state = CompletionState.values[json['state']];

    // Set inherited deadline flag
    rootTask.isDeadLineInherited = json['isDeadLineInherited'];

    // Now deserialize all subtasks
    if (json['subTasks'] != null) {
      final subtasks = List<Map<String, dynamic>>.from(json['subTasks']);
      for (var subtaskJson in subtasks) {
        // Create subtask and add parent reference
        TaskBase subtask;
        if (subtaskJson['type'] == 'rotating_task') {
          subtask = RotatingTask.fromJson(subtaskJson, rootTask);
        } else {
          subtask = Task.fromJson(subtaskJson, rootTask);
        }
        rootTask.subTasks.add(subtask);
      }
    }

    return rootTask;
  }

  // Override toJson to include RootTask-specific properties
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = toJsonBase();

    // Add type identifier for deserialization
    data['type'] = 'root';

    // Add serialized subtasks
    data['subTasks'] = subTasks.map((subtask) => subtask.toJson()).toList();

    return data;
  }

  void restAllTasks() {
    if (subTasks.isNotEmpty) {
      for (TaskBase task in subTasks) {
        task.resetStatus();
      }
    }
  }

  @override
  void updateTaskOnDeadline() {
    if (checkIfDeadLineEnded()) {
      if (state == CompletionState.notStarted) setFailed();
      createNewDeadLine();
      restAllTasks();
    }
  }
}
