import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/utils/constants.dart';

class RankIndicator extends StatelessWidget {
  final bool compact;

  const RankIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final rankName = userProvider.getCurrentRankDisplayName();
    final currentMMR = userProvider.getCurrentMMR();
    userProvider.getThreshold();
    final progress = userProvider.getProgressToNextRank();
    final pointsToNext = userProvider.getPointsToNextRank();

    // Get rank color for the current rank
    final rankColor = AppColors.getRankColor(rankName);

    if (compact) {
      // Compact version for dashboard
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [rankColor.withAlpha(26), rankColor.withAlpha(51)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: rankColor.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with rank and points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rank badge
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: rankColor,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        rankName,
                        style: AppTextStyles.rankTitle.copyWith(
                          color: rankColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),

                  // MMR display
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: rankColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: rankColor.withAlpha(77)),
                    ),
                    child: Text(
                      '${AppStrings.mmrPoints}: $currentMMR',
                      style: AppTextStyles.smallText.copyWith(
                        color: rankColor.withAlpha(204),
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress bar
              SizedBox(height: 8.h),
              Stack(
                children: [
                  // Background
                  Container(
                    height: 10.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),

                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 10.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rankColor.withAlpha(179),
                            rankColor,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                    ),
                  ),
                ],
              ),

              // Points left text (only if there are points left)
              if (pointsToNext > 0)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    '$pointsToNext left',
                    style: AppTextStyles.smallText.copyWith(
                      fontSize: 9.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Original full-size version for tree screen
    return Container(
      width: double.infinity,
      // Increased vertical margin for more space around the widget
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      // Added minimum height constraint for the container
      constraints: BoxConstraints(minHeight: 180.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [rankColor.withAlpha(26), rankColor.withAlpha(51)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: rankColor.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        // Increased padding for more internal space
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank title and badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rank with icon
                Row(
                  children: [
                    Container(
                      // Increased size of the icon container
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: rankColor.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: rankColor,
                        // Increased icon size
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'Rank: $rankName',
                      style: AppTextStyles.rankTitle.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w600,
                        // Increased font size
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),

                // MMR Points
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: rankColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: rankColor.withAlpha(77)),
                  ),
                  child: Text(
                    '${AppStrings.mmrPoints}: $currentMMR',
                    style: AppTextStyles.taskSubtitle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: rankColor.withAlpha(204),
                      // Increased font size
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),

            // Increased spacing
            SizedBox(height: 24.h),

            // Progress label
            Text(
              'Progress to Next Rank',
              style: AppTextStyles.taskSubtitle.copyWith(
                fontWeight: FontWeight.w500,
                // Increased font size
                fontSize: 14.sp,
              ),
            ),

            // Increased spacing
            SizedBox(height: 10.h),

            // Progress bar
            Stack(
              children: [
                // Background
                Container(
                  // Increased height of progress bar
                  height: 24.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Changed to a darker background color for better contrast with light colors
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(8.r),
                    // Added a subtle border for even better definition
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1.0,
                    ),
                  ),
                ),

                // Progress
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    // Increased height to match background
                    height: 24.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          rankColor.withAlpha(179),
                          rankColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),

            // Increased spacing
            SizedBox(height: 12.h),

            // Points needed text
            if (pointsToNext > 0)
              Text(
                '${pointsToNext.toString()} points left to next rank',
                style: AppTextStyles.smallText.copyWith(
                  // Changed to white text for better visibility on any background
                  color: Colors.white,
                  // Increased font size
                  fontSize: 12.sp,
                  // Added shadow for better readability
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2.0,
                      color: Colors.black.withAlpha(77),
                    ),
                  ],
                ),
              ),

            // Added extra space at bottom
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }
}
