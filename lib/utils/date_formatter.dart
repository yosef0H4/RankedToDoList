import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_9/utils/constants.dart';

/// Utility class to handle date formatting consistently throughout the app
class DateFormatter {
  /// Formats a deadline with relative time information
  ///
  /// [deadline] - The deadline to format
  /// [includeTime] - Whether to include the actual time in the output
  static String formatDeadlineRelative(DateTime? deadline,
      {bool includeTime = true}) {
    if (deadline == null) return 'No deadline';

    final now = DateTime.now();
    final timeText = includeTime ? DateFormat('h:mm a').format(deadline) : '';

    if (deadline.isBefore(now)) {
      return includeTime ? '$timeText (Overdue)' : 'Overdue';
    }

    final difference = deadline.difference(now);
    String relativeTime;

    if (difference.inDays > 0) {
      relativeTime = '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      relativeTime = '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      relativeTime = '${difference.inMinutes}m';
    } else {
      relativeTime = includeTime ? 'Just now' : 'Now';
    }

    return includeTime ? '$timeText ($relativeTime)' : relativeTime;
  }

  /// Returns just the relative time component without the actual time
  static String formatRelativeTimeOnly(DateTime? deadline) {
    if (deadline == null) return 'No deadline';

    final now = DateTime.now();

    if (deadline.isBefore(now)) {
      return 'Overdue';
    }

    final difference = deadline.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  /// Gets a color to represent the deadline urgency
  static Color getDeadlineColor(DateTime? deadline) {
    if (deadline == null) return Colors.grey;

    final now = DateTime.now();

    if (deadline.isBefore(now)) {
      return AppColors.failedColor;
    }

    final difference = deadline.difference(now);

    if (difference.inHours < 1 && difference.isNegative == false) {
      return Colors.orange;
    }

    return Colors.blue;
  }
}
