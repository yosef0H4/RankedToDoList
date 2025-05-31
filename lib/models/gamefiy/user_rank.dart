import 'dart:math';

import 'package:flutter/material.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/gamefiy/rank.dart';

class UserRank {
  Rank currentRank;

  int mmr;
  List<int> randomRange = [25, 75];

  // Threshold for advancing to next rank (dynamically calculated)
  int _threshold = 1000; // Default starting value

  UserRank({this.currentRank = Rank.bronze, this.mmr = 0});

  // Create UserRank from JSON
  factory UserRank.fromJson(Map<String, dynamic> json) {
    return UserRank(
      currentRank: Rank.values[json['currentRank']],
      mmr: json['mmr'],
    )
      // Restore random range
      ..randomRange = List<int>.from(json['randomRange'])
      // Restore threshold (will be recalculated anyway)
      .._threshold = json['threshold'];
  }

  // Convert UserRank to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentRank': currentRank.index,
      'mmr': mmr,
      'randomRange': randomRange,
      'threshold': _threshold,
    };
  }

  // Calculate threshold based on all tasks
  void calculateDynamicThreshold(TaskBase task) {
    int total = task.getValue(midRange, Rank.bronze.positiveMultiplier);

    // Set minimum threshold to prevent too easy progression
    _threshold = max(total, 1000);
    debugPrint('Dynamic threshold calculated: $_threshold points');
  }

  int get randomFromRange {
    if (randomRange[0] == 50) return 50;
    return Random().nextInt(randomRange[1] - 24) + randomRange[0];
  }

  int get midRange {
    if (randomRange[0] == 50) return 50;
    return ((randomRange[0] + randomRange[1]) ~/ 2);
  }

  void addToRange(int number) {
    randomRange[0] = max(randomRange[0] - number, 0);
    randomRange[1] = min(randomRange[1] + number, 100);
  }

  void subFromRange(int number) {
    randomRange[0] = max(randomRange[0] + number, 50);
    randomRange[1] = min(randomRange[1] - number, 50);
  }

  int get threshold => _threshold;

  /// Calculates and applies points for a task based on its completion status
  /// Returns the number of points added or subtracted
  int updatePointsForTask(TaskBase task, bool isCompletion) {
    final points = calculatePointsForTask(task, isCompletion);

    if (isCompletion) {
      mmr += points;
      _checkRankProgression();
    } else {
      mmr -= points;
      _checkRankRegression();
    }

    return points;
  }

  /// Calculates points for a task without updating MMR
  int calculatePointsForTask(TaskBase task, bool isCompletion) {
    if (isCompletion) {
      return randomFromRange *
          currentRank.positiveMultiplier *
          task.rarity.multiplier;
    } else {
      return randomFromRange *
          currentRank.negativeMultiplier *
          task.rarity.multiplier;
    }
  }

  void _checkRankProgression() {
    // Continue upgrading rank as long as points exceed threshold
    // and we haven't reached the maximum rank
    while (mmr >= _threshold && currentRank != Rank.values.last) {
      // Upgrade to next rank
      final nextRankIndex = currentRank.index + 1;
      currentRank = Rank.values[nextRankIndex];

      // Subtract threshold from points (carrying over remainder)
      mmr -= _threshold;

      debugPrint(
          'Rank upgraded to: ${currentRank.displayName}, Remaining points: $mmr');
    }
  }

  void _checkRankRegression() {
    // Continue downgrading rank as long as points are negative
    // and we haven't reached the lowest rank
    while (mmr < 0 && currentRank != Rank.values.first) {
      // Downgrade to previous rank
      final prevRankIndex = currentRank.index - 1;
      currentRank = Rank.values[prevRankIndex];

      // Add threshold to points (borrowing from previous rank)
      mmr += _threshold;

      debugPrint(
          'Rank downgraded to: ${currentRank.displayName}, Adjusted points: $mmr');
    }
  }

  double getProgressToNextRank() {
    if (currentRank == Rank.values.last) {
      return 1.0; // Max rank achieved
    }

    return mmr / _threshold;
  }

  int pointsToNextRank() {
    if (currentRank == Rank.values.last) {
      return 0;
    }

    return _threshold - mmr;
  }
}
