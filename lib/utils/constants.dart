import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color backgroundColor = Color(0xFFF7F2FA);
  static const Color errorColor = Color(0xFFB3261E);
  static const Color successColor = Color(0xFF4CAF50);

  // Task completion state colors
  static const Color completedColor = Color(0xFF4CAF50); // Green
  static const Color failedColor = Color(0xFFB3261E); // Red
  static const Color notStartedColor = Color(0xFF9E9E9E); // Gray

  // Rank colors
  static const Color bronzeColor = Color(0xFFCD7F32);
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color platinumColor = Color(0xFFE5E4E2);
  static const Color diamondColor = Color(0xFFB9F2FF);
  static const Color masterColor = Color(0xFF9C27B0);
  static const Color grandMasterColor = Color(0xFFFF5722);

  static Color getRankColor(String rankName) {
    switch (rankName.toLowerCase()) {
      case 'bronze':
        return bronzeColor;
      case 'silver':
        return silverColor;
      case 'gold':
        return goldColor;
      case 'platinum':
        return platinumColor;
      case 'diamond':
        return diamondColor;
      case 'master':
        return masterColor;
      case 'grandmaster':
        return grandMasterColor;
      default:
        return bronzeColor;
    }
  }

  // Get color for task's completion state
  static Color getStateColor(CompletionState state) {
    switch (state) {
      case CompletionState.completed:
        return completedColor;
      case CompletionState.failed:
        return failedColor;
      case CompletionState.notStarted:
        return notStartedColor;
    }
  }
}

class AppTextStyles {
  static TextStyle get taskTitle => TextStyle(
        fontSize: 14.sp, // Reduced from 16.sp
        fontWeight: FontWeight.w500,
      );

  static TextStyle get taskSubtitle => TextStyle(
        fontSize: 11.sp, // Reduced from 14.sp
        color: Colors.grey,
      );

  static TextStyle get dialogTitle => TextStyle(
        fontSize: 16.sp, // Reduced from 20.sp
        fontWeight: FontWeight.bold,
      );

  static TextStyle get rankTitle => TextStyle(
        fontSize: 16.sp, // Reduced from 18.sp
        fontWeight: FontWeight.bold,
      );

  // Added styles for consistent sizing across the app
  static TextStyle get smallText => TextStyle(
        fontSize: 10.sp,
        color: Colors.grey,
      );

  static TextStyle get bodyText => TextStyle(
        fontSize: 12.sp,
      );

  static TextStyle get headingText => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      );
}

/// Widget styling constants for reuse throughout the app
class AppWidgetStyles {
  // Standard padding for most containers
  static EdgeInsets standardPadding() {
    return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
  }

  // Reduced padding for tighter layouts
  static EdgeInsets compactPadding() {
    return EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
  }

  // Standard border radius
  static BorderRadius standardBorderRadius() {
    return BorderRadius.circular(8.r);
  }

  // Card decoration with colored border
  static BoxDecoration cardDecoration(Color borderColor,
      {double borderWidth = 2.0}) {
    return BoxDecoration(
      borderRadius: standardBorderRadius(),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  // Container decoration with gradient background
  static BoxDecoration gradientContainer(Color baseColor) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [baseColor.withAlpha(26), baseColor.withAlpha(51)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: standardBorderRadius(),
      boxShadow: [
        BoxShadow(
          color: baseColor.withAlpha(26),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Badge decoration
  static BoxDecoration badgeDecoration(Color color) {
    return BoxDecoration(
      color: color.withAlpha(51),
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: color.withAlpha(77), width: 0.5),
    );
  }
}

class AppStrings {
  static const String appTitle = 'Gamified Todo';
  static const String addTask = 'Add Task';
  static const String editTask = 'Edit Task';
  static const String taskName = 'Task Name';
  static const String taskRarity = 'Task Rarity';
  static const String taskDeadline = 'Task Deadline';
  static const String inheritDeadline = 'Inherit Deadline from Parent';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String mmrPoints = 'MMR';
  static const String pointsToNextRank = 'Points to Next Rank';
}

// This will be needed when importing this file to access enum CompletionState
