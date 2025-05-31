import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/utils/constants.dart';

class TaskActionButtons extends StatelessWidget {
  final TaskBase task;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final bool useIconButtons;

  const TaskActionButtons({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onFail,
    this.useIconButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useIconButtons) {
      return _buildCompactIconButtons();
    } else {
      return _buildStyledIconButtons();
    }
  }

  Widget _buildCompactIconButtons() {
    return Row(
      children: [
        // Fail/Cancel button
        SizedBox(
          width: 28.r,
          height: 28.r,
          child: IconButton(
            icon: Icon(
              Icons.cancel,
              size: 22.r,
              color: task.state == CompletionState.failed
                  ? AppColors.failedColor
                  : Colors.grey.withAlpha(77),
            ),
            padding: EdgeInsets.zero,
            onPressed: onFail,
            tooltip: 'Mark as failed',
          ),
        ),

        SizedBox(width: 3.w),

        // Complete/Check button
        SizedBox(
          width: 28.r,
          height: 28.r,
          child: IconButton(
            icon: Icon(
              Icons.check_circle,
              size: 22.r,
              color: task.state == CompletionState.completed
                  ? AppColors.completedColor
                  : Colors.grey.withAlpha(77),
            ),
            padding: EdgeInsets.zero,
            onPressed: onComplete,
            tooltip: 'Mark as completed',
          ),
        ),
      ],
    );
  }

  Widget _buildStyledIconButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Fail button - styled with filled background
        Container(
          height: 36.h,
          width: 36.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: AppColors.failedColor,
          ),
          child: IconButton(
            icon: Icon(
              Icons.cancel,
              size: 20.r,
              color: Colors.white,
            ),
            padding: EdgeInsets.zero,
            onPressed: onFail,
            tooltip: 'Mark as failed',
          ),
        ),

        SizedBox(width: 8.w),

        // Complete button - styled
        Container(
          height: 36.h,
          width: 36.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: AppColors.completedColor,
          ),
          child: IconButton(
            icon: Icon(
              Icons.check_circle,
              size: 20.r,
              color: Colors.white,
            ),
            padding: EdgeInsets.zero,
            onPressed: onComplete,
            tooltip: 'Mark as completed',
          ),
        ),
      ],
    );
  }
}
