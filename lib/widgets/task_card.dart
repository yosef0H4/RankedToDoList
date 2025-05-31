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
import 'package:to_do_9/widgets/deadline_display.dart';
import 'package:to_do_9/widgets/task_action_buttons.dart';

class TaskCard extends StatelessWidget {
  final TaskBase task;
  final String breadcrumb;
  final VoidCallback onComplete;
  final VoidCallback onFail;

  const TaskCard({
    super.key,
    required this.task,
    required this.breadcrumb,
    required this.onComplete,
    required this.onFail,
  });

  // Helper method to show rotation selector dialog
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
    final rarityProps = RarityProperties.getPropertiesForRarity(task.rarity);
    final statusColor = DateFormatter.getDeadlineColor(task.deadLine);

    // Try to extract rotating parent info from breadcrumb
    bool isFromRotatingParent = false;
    RotatingTask? rotatingParent;

    // Find rotating parent if this is a subtask of a rotating task
    if (task is Task && breadcrumb.contains('Rotation')) {
      isFromRotatingParent = true;
      final parent = (task as Task).parent;
      if (parent is RotatingTask) {
        rotatingParent = parent;
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main row with task info and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Task info section
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title only
                      Text(
                        task.name,
                        style: AppTextStyles.taskTitle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 2.h),

                      // Breadcrumb path - only if available
                      if (breadcrumb.isNotEmpty)
                        Text(
                          breadcrumb,
                          style: AppTextStyles.smallText.copyWith(
                            color: Colors.grey[600],
                            fontSize: 9.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      if (isFromRotatingParent && rotatingParent != null)
                        // Show rotating indicator badge
                        InkWell(
                          onTap: () => _showRotationIndexSelector(
                              context, rotatingParent!),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.h),
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
                                  "${rotatingParent.currentSubtask?.name ?? 'None'}",
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
                        )
                      else if (isFromRotatingParent)
                        // Simpler indicator if parent not available
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
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
                                "Rotation",
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Deadline display
                      DeadlineDisplay(task: task),
                    ],
                  ),
                ),

                // Action buttons section with rarity badge above
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Rarity badge
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      margin: EdgeInsets.only(bottom: 4.h),
                      decoration: BoxDecoration(
                        color: rarityProps.color.withAlpha(51),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        rarityProps.label,
                        style: TextStyle(
                          color: rarityProps.color,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Action buttons
                    TaskActionButtons(
                      task: task,
                      onComplete: onComplete,
                      onFail: onFail,
                      useIconButtons: false,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
