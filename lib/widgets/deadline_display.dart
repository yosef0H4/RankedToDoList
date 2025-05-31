import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:to_do_9/utils/date_formatter.dart';
import 'package:intl/intl.dart';

class DeadlineDisplay extends StatelessWidget {
  final TaskBase task;

  const DeadlineDisplay({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = DateFormatter.getDeadlineColor(task.deadLine);
    final deadline = DateFormatter.formatRelativeTimeOnly(task.deadLine);

    return Row(
      children: [
        // Icon - shows inherited or regular clock icon
        Icon(
          task is Task && (task as Task).isDeadLineInherited
              ? Icons.account_tree
              : Icons.access_time,
          size: 12.r,
          color: Colors.grey[600],
        ),

        SizedBox(width: 2.w),

        // Time display - always shown
        Text(
          task.deadLine != null
              ? DateFormat('h:mm a').format(task.deadLine!)
              : 'No time',
          style: AppTextStyles.taskSubtitle.copyWith(fontSize: 10.sp),
        ),

        // Space between time and badge
        SizedBox(width: 4.w),

        // Deadline badge - always shown
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: AppWidgetStyles.badgeDecoration(statusColor),
          child: Text(
            deadline,
            style: TextStyle(
              color: statusColor,
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
