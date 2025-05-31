// We'll need to modify the way subtasks are displayed. For any task shown in a list,
// we should check if the parent is a rotating task and if this is the current active subtask.

// Add this widget file for rendering subtasks of a rotating task:

// widgets/rotating_subtask_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/providers/user_provider.dart';

class RotatingSubtaskView extends StatelessWidget {
  final RotatingTask task;

  const RotatingSubtaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.w, bottom: 4.h),
          child: Text(
            "Rotation Order:",
            style: AppTextStyles.smallText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: task.subTasks.length,
          itemBuilder: (context, index) {
            final subtask = task.subTasks[index];
            final isActive = index == task.currentIndex;

            return InkWell(
              onTap: () {
                if (!isActive) {
                  // Allow manually changing the current rotation
                  userProvider.advanceRotation(task, toIndex: index);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryColor.withAlpha(26)
                      : Colors.transparent,
                  border: Border(
                      left: BorderSide(
                    color:
                        isActive ? AppColors.primaryColor : Colors.transparent,
                    width: 3,
                  )),
                ),
                child: Row(
                  children: [
                    if (isActive)
                      Icon(
                        Icons.chevron_right,
                        size: 16.r,
                        color: AppColors.primaryColor,
                      ),
                    SizedBox(width: isActive ? 4.w : 20.w),
                    Text(
                      subtask.name,
                      style: AppTextStyles.taskSubtitle.copyWith(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? AppColors.primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
