import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/Tasks/task.dart';

/// Utilities for working with task hierarchies
class TaskUtils {
  /// Collects tasks from a hierarchy based on a predicate function
  ///
  /// [root] - The root task to start collection from
  /// [predicate] - A function that determines which tasks to include
  /// Returns a list of tasks matching the predicate
  static List<TaskBase> collectTasks(
      TaskBase root, bool Function(TaskBase) predicate) {
    final List<TaskBase> result = [];

    void traverse(TaskBase task) {
      if (predicate(task)) {
        result.add(task);
      }
      for (var subtask in task.subTasks) {
        traverse(subtask);
      }
    }

    traverse(root);
    return result;
  }

  /// Gets all tasks in a hierarchy (including the root)
  static List<TaskBase> getAllTasks(TaskBase root) {
    return collectTasks(root, (_) => true);
  }

  /// Gets only leaf tasks (tasks with no subtasks)
  static List<TaskBase> getLeafTasks(TaskBase root) {
    return collectTasks(root, (task) => task.subTasks.isEmpty);
  }

  /// Gets tasks that match a specific completion state
  static List<TaskBase> getTasksByState(TaskBase root, CompletionState state) {
    return collectTasks(root, (task) => task.state == state);
  }

  /// Gets tasks with upcoming deadlines, sorted by deadline
  static List<TaskBase> getUpcomingTasks(TaskBase root) {
    final tasks = collectTasks(
        root,
        (task) =>
            task.state == CompletionState.notStarted && task.deadLine != null);

    // Sort by deadline
    tasks.sort((a, b) {
      if (a.deadLine == null && b.deadLine == null) return 0;
      if (a.deadLine == null) return 1;
      if (b.deadLine == null) return -1;
      return a.deadLine!.compareTo(b.deadLine!);
    });

    return tasks;
  }

  /// Gets the breadcrumb path for a task (shows hierarchy path)
  static String getBreadcrumbPath(TaskBase task, {String separator = ' → '}) {
    List<String> path = [];
    TaskBase current = task;

    // For tasks with parents, traverse up the hierarchy
    while (current is Task) {
      current = (current).parent;
      path.add(current.name);
    }

    // Reverse to get root -> leaf order
    path = path.reversed.toList();

    return path.join(separator);
  }
}
