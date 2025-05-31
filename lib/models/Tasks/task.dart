import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';

class Task extends TaskBase {
  TaskBase parent;

  Task(
      {required super.name,
      required super.subTasks,
      required this.parent,
      super.deadLine,
      super.rarity = TaskRarity.common}) {
    if (deadLine == null) {
      deadLine = parent.deadLine;
      isDeadLineInherited = true;
    } else {
      isDeadLineInherited = false;
    }
  }

  // Create a Task from JSON with parent reference
  factory Task.fromJson(Map<String, dynamic> json, TaskBase parentTask) {
    // Create a Task with the base properties and parent reference
    final task = Task(
      name: json['name'],
      deadLine:
          json['deadLine'] != null ? DateTime.parse(json['deadLine']) : null,
      subTasks: [], // Initialize with empty list, will fill below
      parent: parentTask,
      rarity: TaskRarity.values[json['rarity']],
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

  // Override toJson to include Task-specific properties
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = toJsonBase();

    // Add type identifier for deserialization
    data['type'] = 'task';

    // Add serialized subtasks (but not parent to avoid circular references)
    data['subTasks'] = subTasks.map((subtask) => subtask.toJson()).toList();

    return data;
  }

  void updateParentStatus() {
    // Use the unified task status calculation
    final newParentState = parent.calculateStatusFromSubtasks();

    // Only update if needed
    if (parent.state != newParentState) {
      parent.state = newParentState;

      // Continue propagating upwards if this is a Task (not a RootTask)
      if (parent is Task) {
        (parent as Task).updateParentStatus();
      }
    }
  }

  @override
  void setCompletionStatus(CompletionState status) {
    super.setCompletionStatus(status);
    updateParentStatus();
  }

  @override
  void updateDeadline(DateTime? newDeadline) {
    super.updateDeadline(newDeadline);
    isDeadLineInherited = false;
  }

  void inheritDeadline() {
    deadLine = parent.deadLine;
    isDeadLineInherited = true;
  }
}
