import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:to_do_9/widgets/task_dialog.dart';

/// Utilities for showing common dialogs in the app
class DialogUtils {
  /// Shows the task dialog for adding or editing tasks
  ///
  /// [context] - The build context
  /// [initialParent] - The initial parent task
  /// [taskToEdit] - The task to edit (null for adding new task)
  /// [onComplete] - Callback when dialog is completed successfully
  static Future<void> showTaskDialog({
    required BuildContext context,
    required TaskBase initialParent,
    TaskBase? taskToEdit,
    required Function(Map<String, dynamic> result) onComplete,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rootTask = userProvider.user.rootTask;
    final allTasks = userProvider.getAllTasks();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TaskDialog(
        task: taskToEdit,
        initialParent: initialParent,
        isRootTask: taskToEdit == rootTask,
        allTasks: allTasks,
        rootTask: rootTask,
      ),
    );

    if (result != null && context.mounted) {
      onComplete(result);
    }
  }

  /// Shows a confirmation dialog for task deletion
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String taskName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: AppTextStyles.dialogTitle),
        content: Text(
          'Are you sure you want to delete "$taskName"?',
          style: AppTextStyles.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text(AppStrings.delete,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
