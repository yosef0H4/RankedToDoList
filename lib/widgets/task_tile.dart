import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:to_do_9/utils/date_formatter.dart';
import 'package:to_do_9/utils/dialog_utils.dart';
import 'package:to_do_9/widgets/deadline_display.dart';
import 'package:to_do_9/widgets/task_action_buttons.dart';
import 'package:to_do_9/widgets/task_dialog.dart';

class TaskTile extends StatefulWidget {
  final TaskBase task;
  final int depth;
  final bool isRoot;
  final bool initiallyExpanded;
  final Function(bool)? onExpandChanged;

  const TaskTile({
    super.key,
    required this.task,
    this.depth = 0,
    this.isRoot = false,
    this.initiallyExpanded = false, // Default to collapsed in bottom-up view
    this.onExpandChanged,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (widget.onExpandChanged != null) {
      widget.onExpandChanged!(_isExpanded);
    }
  }

  void _showEditDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.isRoot) {
      // Handle root task edit
      DialogUtils.showTaskDialog(
        context: context,
        initialParent: widget.task,
        taskToEdit: widget.task,
        onComplete: (result) {
          userProvider.updateRootTask(
            name: result['name'],
            deadLine: result['deadline'],
            rarity: result['rarity'],
          );
        },
      );
    } else {
      // Handle regular task edit
      Task task = widget.task as Task;
      TaskBase oldParent = task.parent;

      DialogUtils.showTaskDialog(
        context: context,
        initialParent: oldParent,
        taskToEdit: task,
        onComplete: (result) {
          final TaskBase newParent = result['parent'];

          if (newParent != oldParent) {
            // Handle reparenting
            userProvider.reparentTask(
              task: task,
              newParent: newParent,
              name: result['name'],
              deadLine: result['deadline'],
              rarity: result['rarity'],
              inheritDeadline: result['inheritDeadline'],
            );
          } else {
            // Regular update without reparenting
            userProvider.updateTask(
              task: task,
              name: result['name'],
              deadLine: result['deadline'],
              rarity: result['rarity'],
              inheritDeadline: result['inheritDeadline'],
            );
          }
        },
      );
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    DialogUtils.showTaskDialog(
      context: context,
      initialParent: widget.task,
      onComplete: (result) {
        final taskType = result['taskType'] as TaskType?;
        final isRotating = taskType == TaskType.rotating;

        userProvider.addTask(
          name: result['name'],
          parent: result['parent'],
          deadLine: result['deadline'],
          rarity: result['rarity'],
          isRotating: isRotating,
        );

        // Auto-expand to show the new subtask if the selected parent is this task
        if (result['parent'] == widget.task && !_isExpanded) {
          setState(() {
            _isExpanded = true;
          });

          if (widget.onExpandChanged != null) {
            widget.onExpandChanged!(true);
          }
        }
      },
    );
  }

  void _deleteTask(BuildContext context) {
    if (widget.isRoot) {
      // Cannot delete root task
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the root task')),
      );
      return;
    }

    // Store task reference before async gap
    final Task taskToDelete = widget.task as Task;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    userProvider.deleteTask(taskToDelete);
  }

  void _toggleTaskCompletion(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.task.state == CompletionState.completed) {
      // Already completed, reset to not started
      userProvider.resetTask(widget.task);
    } else {
      // Not completed, mark as completed
      userProvider.completeTask(widget.task);
    }
  }

  void _toggleTaskFailure(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.task.state == CompletionState.failed) {
      // Already failed, reset to not started
      userProvider.resetTask(widget.task);
    } else {
      // Not failed, mark as failed
      userProvider.failTask(widget.task);
    }
  }

  void _showRotationIndexSelector(BuildContext context, RotatingTask task) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Active Task', style: AppTextStyles.dialogTitle),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: task.subTasks.length,
            itemBuilder: (context, index) {
              final subtask = task.subTasks[index];
              final isSelected = index == task.currentIndex;

              return ListTile(
                title: Text(subtask.name),
                tileColor:
                    isSelected ? AppColors.primaryColor.withAlpha(26) : null,
                leading: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.primaryColor)
                    : Icon(Icons.circle_outlined),
                onTap: () {
                  userProvider.advanceRotation(task, toIndex: index);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTextStyles.bodyText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rarityProps =
        RarityProperties.getPropertiesForRarity(widget.task.rarity);
    final indentation = widget.depth * 20.0.w; // Reduced from 24.0.w
    DateFormatter.formatDeadlineRelative(widget.task.deadLine);
    final hasSubtasks = widget.task.subTasks.isNotEmpty;

    // For bottom-up design: larger elevation for parent tasks (visual hierarchy)
    final cardElevation = widget.isRoot ? 3.0 : 1.0 + (widget.depth * 0.5);

    // Check if this is a rotating task or inside a rotating task
    final bool isRotatingTask = widget.task is RotatingTask;

    // Get the current index for rotating tasks to show indicator
    int? currentTaskIndex;
    if (isRotatingTask) {
      currentTaskIndex = (widget.task as RotatingTask).currentIndex;
    }

    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: Card(
        margin: EdgeInsets.symmetric(
            horizontal: 8.w, vertical: 3.h), // Reduced vertical margin
        elevation: cardElevation,
        // Add a subtle color accent for root and parent tasks
        color: widget.isRoot
            ? Theme.of(context).cardColor.withAlpha(242)
            : Theme.of(context).cardColor,
        child: InkWell(
          onTap: hasSubtasks ? _toggleExpanded : null,
          child: Padding(
            padding: AppWidgetStyles.compactPadding(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Expand/collapse indicator for tasks with subtasks
                    if (hasSubtasks)
                      Icon(
                        // Changed icon direction for upward expansion
                        _isExpanded ? Icons.expand_less : Icons.chevron_right,
                        size: 20.r, // Reduced from 24.r
                        color: Colors.grey,
                      ),

                    // Rotating task indicator
                    if (isRotatingTask)
                      InkWell(
                        onTap: () {
                          final rotatingTask = widget.task as RotatingTask;
                          _showRotationIndexSelector(context, rotatingTask);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                          margin: EdgeInsets.only(right: 4.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                size: 12.r,
                                color: AppColors.primaryColor,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                "${(widget.task as RotatingTask).currentSubtask?.name ?? 'None'}",
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.edit,
                                size: 10.r,
                                color: AppColors.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Task name
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            widget.task.name,
                            style: AppTextStyles.taskTitle,
                          ),
                          SizedBox(width: 6.w), // Reduced from 8.w

                          // Using the new TaskActionButtons component
                          TaskActionButtons(
                            task: widget.task,
                            onComplete: () => _toggleTaskCompletion(context),
                            onFail: () => _toggleTaskFailure(context),
                            useIconButtons: true,
                          ),
                        ],
                      ),
                    ),

                    // Rarity indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h), // Reduced padding
                      decoration:
                          AppWidgetStyles.badgeDecoration(rarityProps.color),
                      child: Text(
                        rarityProps.label,
                        style: TextStyle(
                          color: rarityProps.color,
                          fontSize: 10.sp, // Reduced from 12.sp
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h), // Reduced from 4.h

                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Replace the existing deadline display with DeadlineDisplay
                    DeadlineDisplay(
                      task: widget.task,
                    ),
                    const Spacer(),
                    // Edit button
                    SizedBox(
                      width: 30.r, // Reduced from 36.r
                      height: 30.r, // Reduced from 36.r
                      child: IconButton(
                        icon: Icon(Icons.edit, size: 18.r), // Reduced from 24.r
                        onPressed: () => _showEditDialog(context),
                        tooltip: 'Edit',
                        padding: EdgeInsets.all(6.r),
                      ),
                    ),

                    // Delete button (not for root task)
                    if (!widget.isRoot)
                      SizedBox(
                        width: 30.r, // Reduced from 36.r
                        height: 30.r, // Reduced from 36.r
                        child: IconButton(
                          icon: Icon(Icons.delete,
                              size: 18.r), // Reduced from 24.r
                          onPressed: () => _deleteTask(context),
                          tooltip: 'Delete',
                          padding: EdgeInsets.all(6.r),
                        ),
                      ),

                    // Add subtask button
                    SizedBox(
                      width: 30.r, // Reduced from 36.r
                      height: 30.r, // Reduced from 36.r
                      child: IconButton(
                        icon: Icon(Icons.add_circle,
                            size: 18.r,
                            color: AppColors.primaryColor), // Reduced from 24.r
                        onPressed: () => _showAddTaskDialog(context),
                        tooltip: 'Add Subtask',
                        padding: EdgeInsets.all(6.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
