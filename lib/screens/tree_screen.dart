import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/mixins/deadline_check_mixin.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:to_do_9/widgets/rank_indicator.dart';
import 'package:to_do_9/widgets/task_tile.dart';

class TreeScreen extends StatefulWidget {
  const TreeScreen({super.key});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> with DeadlineCheckMixin {
  // Track expanded state of each task by its hashCode
  final Map<int, bool> _expandedState = {};

  // Update expanded state for a task
  void _updateExpandedState(TaskBase task, bool isExpanded) {
    setState(() {
      _expandedState[task.hashCode] = isExpanded;
    });
  }

  // Get expanded state for a task (default to false if not set)
  bool _getExpandedState(TaskBase task) {
    return _expandedState[task.hashCode] ?? false;
  }

  // Recursive function to build task hierarchy widgets for bottom-up layout with upward expansion
  List<Widget> _buildTaskHierarchyBottomUp(TaskBase task, int depth,
      {bool isRoot = false}) {
    final List<Widget> widgets = [];
    final isExpanded = _getExpandedState(task);

    // First add subtasks if expanded (they'll appear above the parent after reversal)
    if (isExpanded && task.subTasks.isNotEmpty) {
      // Process tasks in proper order for display
      for (int i = 0; i < task.subTasks.length; i++) {
        widgets
            .addAll(_buildTaskHierarchyBottomUp(task.subTasks[i], depth + 1));
      }
    }

    // Then add the current task (after subtasks, so it appears below them)
    widgets.add(TaskTile(
      task: task,
      depth: depth,
      isRoot: isRoot,
      initiallyExpanded: isExpanded,
      onExpandChanged: (isExpanded) => _updateExpandedState(task, isExpanded),
    ));

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final rootTask = userProvider.user.rootTask;

    // Build the entire hierarchy starting from the root
    final List<Widget> hierarchyWidgets = [];

    // First add the rank indicator (it will appear at the top after reversal)
    hierarchyWidgets.add(const RankIndicator());

    // Then add the task hierarchy in bottom-up order with upward expansion
    hierarchyWidgets
        .addAll(_buildTaskHierarchyBottomUp(rootTask, 0, isRoot: true));

    // Reverse the entire list for the bottom-up display
    final reversedWidgets = hierarchyWidgets.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56.h, // Reduced from default
        title: Text(
          AppStrings.appTitle,
          style: TextStyle(fontSize: 16.sp), // Explicitly set title font size
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 20.r), // Reduced from default size
            onPressed: checkDeadlines,
            tooltip: 'Check Deadlines',
          ),
        ],
      ),
      body: ListView(
        // Reverse the scroll direction so bottom is the starting point
        reverse: true,
        // Use bouncing physics for a more natural feel
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 6.h), // Reduced from 8.h
        children: reversedWidgets,
      ),
      // Add bottom app bar with undo/redo buttons
      bottomNavigationBar: Container(
        // Further reduce height to 40.h since we no longer have text
        height: 40.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Undo button - icon only
            IconButton(
              icon: Icon(
                Icons.undo,
                color:
                    userProvider.canUndo ? AppColors.primaryColor : Colors.grey,
                size: 24.r,
              ),
              onPressed: userProvider.canUndo ? userProvider.undo : null,
              tooltip: 'Undo',
            ),
            // Redo button - icon only
            IconButton(
              icon: Icon(
                Icons.redo,
                color:
                    userProvider.canRedo ? AppColors.primaryColor : Colors.grey,
                size: 24.r,
              ),
              onPressed: userProvider.canRedo ? userProvider.redo : null,
              tooltip: 'Redo',
            ),
          ],
        ),
      ),
    );
  }
}
