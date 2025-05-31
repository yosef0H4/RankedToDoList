import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/mixins/deadline_check_mixin.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/screens/tree_screen.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:to_do_9/utils/dialog_utils.dart';
import 'package:to_do_9/utils/task_utils.dart';
import 'package:to_do_9/widgets/rank_indicator.dart';
import 'package:to_do_9/widgets/task_card.dart';
import 'package:to_do_9/widgets/rotating_task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with DeadlineCheckMixin {
  void _showAddTaskDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rootTask = userProvider.user.rootTask;

    DialogUtils.showTaskDialog(
      context: context,
      initialParent: rootTask,
      onComplete: (result) {
        userProvider.addTask(
          name: result['name'],
          parent: result['parent'],
          deadLine: result['deadline'],
          rarity: result['rarity'],
        );
      },
    );
  }

  void _showBackupRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup & Restore', style: AppTextStyles.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can backup your data to a text string or restore from a previously saved backup.',
              style: AppTextStyles.bodyText,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTextStyles.bodyText),
          ),
          ElevatedButton(
            onPressed: () => _createBackup(context),
            child: Text('Backup', style: AppTextStyles.bodyText),
          ),
          ElevatedButton(
            onPressed: () => _showRestoreDialog(context),
            child: Text('Restore', style: AppTextStyles.bodyText),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final backupData = await userProvider.exportUserData();

    if (!context.mounted) return;

    Navigator.of(context).pop(); // Close current dialog

    // Show dialog with backup data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup Data', style: AppTextStyles.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Copy this text and save it somewhere safe:',
              style: AppTextStyles.bodyText,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: SelectableText(
                backupData,
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: AppTextStyles.bodyText),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backupData));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup copied to clipboard')),
              );
              Navigator.of(context).pop();
            },
            child: Text('Copy', style: AppTextStyles.bodyText),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final textController = TextEditingController();

    Navigator.of(context).pop(); // Close current dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore Backup', style: AppTextStyles.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paste your backup data below:',
              style: AppTextStyles.bodyText,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
                hintText: 'Paste backup data here',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Warning: This will replace all your current data!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTextStyles.bodyText),
          ),
          ElevatedButton(
            onPressed: () => _restoreBackup(context, textController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text(
              'Restore',
              style: AppTextStyles.bodyText.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(BuildContext context, String backupData) async {
    if (backupData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup data cannot be empty')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.importUserData(backupData);

    if (!context.mounted) return;

    Navigator.of(context).pop(); // Close the dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to restore backup')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Get leaf tasks that are not completed, using our utility
    List<TaskBase> leafTasks = userProvider
        .getActiveLeafTasks()
        .where((t) => t.state == CompletionState.notStarted)
        .toList();

    // Sort them by deadline
    leafTasks.sort((a, b) {
      if (a.deadLine == null && b.deadLine == null) return 0;
      if (a.deadLine == null) return 1;
      if (b.deadLine == null) return -1;
      return a.deadLine!.compareTo(b.deadLine!);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Dashboard',
          style: TextStyle(fontSize: 16.sp),
        ),
        actions: [
          // Backup/restore button
          IconButton(
            icon: Icon(Icons.save, size: 20.r),
            onPressed: () => _showBackupRestoreDialog(context),
            tooltip: 'Backup & Restore',
          ),
          // Button to navigate to tree view
          IconButton(
            icon: Icon(Icons.account_tree, size: 20.r),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TreeScreen()),
              );
            },
            tooltip: 'View Full Task Tree',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 20.r),
            onPressed: checkDeadlines,
            tooltip: 'Check Deadlines',
          ),
        ],
      ),
      body: Column(
        children: [
          // Reuse existing rank indicator
          const RankIndicator(),

          // Upcoming tasks section with add button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - title with icon
                Row(
                  children: [
                    Icon(Icons.task_alt,
                        size: 20.r, color: AppColors.primaryColor),
                    SizedBox(width: 8.w),
                    Text(
                      'Upcoming Tasks',
                      style: AppTextStyles.headingText.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),

                // Right side - add button
                IconButton(
                  icon: Icon(Icons.add_circle,
                      size: 24.r, color: AppColors.primaryColor),
                  onPressed: () => _showAddTaskDialog(context),
                  tooltip: 'Add Task',
                ),
              ],
            ),
          ),

          // Fixed layout showing 4 nearest deadline tasks
          Expanded(
            child: leafTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48.r, color: Colors.grey.withAlpha(128)),
                        SizedBox(height: 16.h),
                        Text(
                          'No upcoming tasks!',
                          style: AppTextStyles.bodyText.copyWith(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                        // Take just the 4 nearest tasks and space them evenly
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: leafTasks.take(4).length,
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            itemBuilder: (context, index) {
                              final task = leafTasks.take(4).toList()[index];

                              // Get breadcrumb using utility
                              String breadcrumb = task is Task
                                  ? TaskUtils.getBreadcrumbPath(task)
                                  : '';

                              // Check if this is from a rotating parent
                              if (task is Task && task.parent is RotatingTask) {
                                final rotatingParent =
                                    task.parent as RotatingTask;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 4.h),
                                  child: RotatingTaskCard(
                                    task: task,
                                    breadcrumb: breadcrumb,
                                    rotatingParent: rotatingParent,
                                    onComplete: () {
                                      userProvider.completeTask(task);
                                    },
                                    onFail: () {
                                      userProvider.failTask(task);
                                    },
                                  ),
                                );
                              } else {
                                // Regular task card
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 4.h),
                                  child: TaskCard(
                                    task: task,
                                    breadcrumb: breadcrumb,
                                    onComplete: () {
                                      userProvider.completeTask(task);
                                    },
                                    onFail: () {
                                      userProvider.failTask(task);
                                    },
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      // Add bottom app bar with undo/redo buttons
      bottomNavigationBar: Container(
        // Further reduce height to 40.h since we no longer have text
        height: 40.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Undo button - icon only
            IconButton(
              icon: Icon(
                Icons.undo,
                color:
                    userProvider.canUndo ? AppColors.primaryColor : Colors.grey,
                size: 24.r,
              ),
              onPressed: userProvider.canUndo ? userProvider.undo : null,
              tooltip: 'Undo',
            ),
            // Redo button - icon only
            IconButton(
              icon: Icon(
                Icons.redo,
                color:
                    userProvider.canRedo ? AppColors.primaryColor : Colors.grey,
                size: 24.r,
              ),
              onPressed: userProvider.canRedo ? userProvider.redo : null,
              tooltip: 'Redo',
            ),
          ],
        ),
      ),
    );
  }
}
