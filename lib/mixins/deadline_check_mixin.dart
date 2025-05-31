import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/utils/periodic_timer.dart';

/// Mixin that provides deadline checking functionality for screens
mixin DeadlineCheckMixin<T extends StatefulWidget> on State<T> {
  late PeriodicTimer _deadlineCheckTimer;

  @override
  void initState() {
    super.initState();

    // Setup timer to check deadlines every minute
    _deadlineCheckTimer =
        PeriodicTimer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        checkDeadlines();
      }
    });

    // Initial check for deadlines
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkDeadlines();
    });
  }

  @override
  void dispose() {
    _deadlineCheckTimer.cancel();
    super.dispose();
  }

  /// Triggers deadline checking in the user provider
  void checkDeadlines() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.checkDeadlines();
  }
}
