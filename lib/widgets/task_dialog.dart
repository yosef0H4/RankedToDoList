// widgets/task_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:to_do_9/models/Tasks/rotating_task.dart';
import 'package:to_do_9/models/Tasks/task.dart';
import 'package:to_do_9/models/Tasks/task_base.dart';
import 'package:to_do_9/models/gamefiy/task_rarity.dart';
import 'package:to_do_9/utils/constants.dart';

enum TaskType {
  regular,
  rotating,
}

class TaskDialog extends StatefulWidget {
  final TaskBase? task; // If null, we're adding a new task
  final TaskBase initialParent; // Initial parent suggestion (for new tasks)
  final bool isRootTask; // Whether this is the root task being edited
  final List<TaskBase> allTasks; // All available tasks for parent selection
  final TaskBase rootTask; // The root task of the hierarchy

  const TaskDialog({
    super.key,
    this.task,
    required this.initialParent,
    this.isRootTask = false,
    required this.allTasks,
    required this.rootTask,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _nameController;
  late TaskRarity _selectedRarity;
  late TimeOfDay _selectedTime;
  late TimeOfDay _parentTime;
  late bool _isInheritingDeadline;
  late bool _hasModifiedTime;
  late TaskBase _selectedParent;
  late TaskType _taskType;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeValues();
      _isInitialized = true;
    }
  }

  void _initializeValues() {
    if (widget.task != null) {
      // EDITING MODE
      _nameController = TextEditingController(text: widget.task!.name);
      _selectedRarity = widget.task!.rarity;

      // Determine task type
      _taskType =
          widget.task is RotatingTask ? TaskType.rotating : TaskType.regular;

      if (widget.isRootTask) {
        // Root task has no parent to select
        _selectedParent = widget.task!;
        _isInheritingDeadline = false;

        if (widget.task!.deadLine != null) {
          _selectedTime = TimeOfDay.fromDateTime(widget.task!.deadLine!);
        } else {
          _selectedTime = TimeOfDay.now();
        }

        // Set parent time to the root's time for consistency
        _parentTime = _selectedTime;
      } else {
        // Regular task - get ACTUAL parent from task object
        _selectedParent = (widget.task as Task).parent;
        _isInheritingDeadline = (widget.task as Task).isDeadLineInherited;

        // Get parent deadline for inheritance
        if (_selectedParent.deadLine != null) {
          _parentTime = TimeOfDay.fromDateTime(_selectedParent.deadLine!);
        } else {
          _parentTime = TimeOfDay.now();
        }

        // Set time based on inheritance or existing value
        if (_isInheritingDeadline) {
          _selectedTime = _parentTime;
        } else if (widget.task!.deadLine != null) {
          _selectedTime = TimeOfDay.fromDateTime(widget.task!.deadLine!);
        } else {
          _selectedTime = TimeOfDay.now();
        }
      }
    } else {
      // ADDING MODE
      _nameController = TextEditingController();
      _selectedRarity = TaskRarity.common;
      _selectedParent = widget.initialParent;
      _taskType = TaskType.regular; // Default to regular task

      // Get parent deadline
      if (_selectedParent.deadLine != null) {
        _parentTime = TimeOfDay.fromDateTime(_selectedParent.deadLine!);
      } else {
        _parentTime = TimeOfDay.now();
      }

      // Default to inheriting deadline for new tasks
      _isInheritingDeadline = !widget.isRootTask;
      _selectedTime = _isInheritingDeadline ? _parentTime : TimeOfDay.now();
    }

    _hasModifiedTime = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setTimeToNow() {
    setState(() {
      _selectedTime = TimeOfDay.now();
      _isInheritingDeadline = false;
      _hasModifiedTime = true;
    });
  }

  void _inheritDeadlineFromParent() {
    setState(() {
      if (_selectedParent.deadLine != null) {
        _parentTime = TimeOfDay.fromDateTime(_selectedParent.deadLine!);
      } else {
        _parentTime = TimeOfDay.now();
      }
      _selectedTime = _parentTime;
      _isInheritingDeadline = true;
      _hasModifiedTime = false;
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null && mounted) {
      setState(() {
        if (picked != _parentTime) {
          _selectedTime = picked;
          _isInheritingDeadline = false;
          _hasModifiedTime = true;
        } else {
          // User selected the same time as parent
          _selectedTime = picked;
          _isInheritingDeadline = true;
          _hasModifiedTime = false;
        }
      });
    }
  }

  DateTime _getDateTime() {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If time is earlier than current time, set it for tomorrow
    if (dateTime.isBefore(now)) {
      return dateTime.add(const Duration(days: 1));
    }

    return dateTime;
  }

  // Check if a task can be a valid parent (prevents circular relationships)
  bool _isValidParent(TaskBase potentialParent) {
    if (widget.task == null) {
      // When adding new task, any task can be a parent
      return true;
    }

    // Can't parent to itself
    if (potentialParent == widget.task) {
      return false;
    }

    // Check if the potential parent is a descendant of the current task
    // to prevent circular references
    bool isDescendant = false;
    void checkDescendants(TaskBase task) {
      for (var subtask in task.subTasks) {
        if (subtask == potentialParent) {
          isDescendant = true;
          return;
        }
        checkDescendants(subtask);
      }
    }

    checkDescendants(widget.task!);
    return !isDescendant;
  }

  // Build the dropdown items with proper indentation to show hierarchy
  List<DropdownMenuItem<TaskBase>> _buildParentDropdownItems() {
    List<DropdownMenuItem<TaskBase>> items = [];

    void addTaskWithIndentation(TaskBase task, int depth) {
      // Skip if not a valid parent
      if (!_isValidParent(task)) {
        return;
      }

      items.add(
        DropdownMenuItem<TaskBase>(
          value: task,
          child: Padding(
            padding: EdgeInsets.only(left: (depth * 10.0).w),
            child: Text(
              task.name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyText,
            ),
          ),
        ),
      );

      // Add subtasks with increased indentation
      for (var subtask in task.subTasks) {
        addTaskWithIndentation(subtask, depth + 1);
      }
    }

    // Start with the root task - direct reference
    addTaskWithIndentation(widget.rootTask, 0);

    return items;
  }

  void _updateSelectedParent(TaskBase? newParent) {
    if (newParent != null && newParent != _selectedParent) {
      setState(() {
        _selectedParent = newParent;

        // Update parent time
        if (_selectedParent.deadLine != null) {
          _parentTime = TimeOfDay.fromDateTime(_selectedParent.deadLine!);
        } else {
          _parentTime = TimeOfDay.now();
        }

        // If inheriting deadline, update the selected time
        if (_isInheritingDeadline) {
          _selectedTime = _parentTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final dialogTitle = isEditing ? AppStrings.editTask : AppStrings.addTask;

    // Better labeling for parent selection
    final parentSelectorLabel = isEditing ? "Move To" : "Subtask of";

    // Check if selected time is the same as parent time
    final bool isUsingParentTime = _selectedTime.hour == _parentTime.hour &&
        _selectedTime.minute == _parentTime.minute;

    // For non-root tasks, if time matches parent and we haven't explicitly modified it,
    // we're inheriting
    if (!widget.isRootTask && isUsingParentTime && !_hasModifiedTime) {
      _isInheritingDeadline = true;
    }

    return AlertDialog(
      title: Text(dialogTitle, style: AppTextStyles.dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task/Parent Selection Dropdown (not shown for root task)
            if (!widget.isRootTask) ...[
              Text(parentSelectorLabel, style: AppTextStyles.taskSubtitle),
              SizedBox(height: 6.h),
              DropdownButtonFormField<TaskBase>(
                value: _selectedParent,
                style: AppTextStyles.bodyText,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                ),
                items: _buildParentDropdownItems(),
                onChanged: _updateSelectedParent,
              ),
              SizedBox(height: 14.h),
            ],

            // Task type selection (not shown for root task)
            if (!widget.isRootTask && (!isEditing || widget.task is Task)) ...[
              Text("Task Type", style: AppTextStyles.taskSubtitle),
              SizedBox(height: 6.h),
              DropdownButtonFormField<TaskType>(
                value: _taskType,
                style: AppTextStyles.bodyText,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: TaskType.regular,
                    child: Text("Regular Task", style: AppTextStyles.bodyText),
                  ),
                  DropdownMenuItem(
                    value: TaskType.rotating,
                    child: Text("Rotating Task", style: AppTextStyles.bodyText),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _taskType = value;
                    });
                  }
                },
              ),
              SizedBox(height: 14.h),
            ],

            TextField(
              controller: _nameController,
              style: AppTextStyles.bodyText,
              decoration: InputDecoration(
                labelText: AppStrings.taskName,
                labelStyle: AppTextStyles.bodyText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 14.h),

            Text(AppStrings.taskRarity, style: AppTextStyles.taskSubtitle),
            SizedBox(height: 6.h),
            DropdownButtonFormField<TaskRarity>(
              value: _selectedRarity,
              style: AppTextStyles.bodyText,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
              ),
              items: TaskRarity.values.map((rarity) {
                final properties =
                    RarityProperties.getPropertiesForRarity(rarity);
                return DropdownMenuItem<TaskRarity>(
                  value: rarity,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: properties.color, size: 14.r),
                      SizedBox(width: 6.w),
                      Text(
                        properties.label,
                        style: AppTextStyles.bodyText,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRarity = value;
                  });
                }
              },
            ),
            SizedBox(height: 14.h),

            Text(AppStrings.taskDeadline, style: AppTextStyles.taskSubtitle),
            SizedBox(height: 6.h),

            // Time selector with buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isInheritingDeadline && !widget.isRootTask
                                ? "Inherited: ${_selectedTime.format(context)}"
                                : _selectedTime.format(context),
                            style: AppTextStyles.bodyText.copyWith(
                              color: _isInheritingDeadline && !widget.isRootTask
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          Icon(Icons.access_time, size: 16.r),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            // Time action buttons
            Row(
              children: [
                // "Inherit" button shown for non-root tasks when appropriate
                if (!widget.isRootTask &&
                    (_hasModifiedTime || !_isInheritingDeadline))
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _inheritDeadlineFromParent,
                      icon: Icon(Icons.account_tree, size: 14.r),
                      label: Text('Inherit', style: AppTextStyles.bodyText),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                      ),
                    ),
                  ),
                if (!widget.isRootTask &&
                    (_hasModifiedTime || !_isInheritingDeadline))
                  SizedBox(width: 4.w),

                // "Now" button always shown
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _setTimeToNow,
                    icon: Icon(Icons.schedule, size: 14.r),
                    label: Text('Now', style: AppTextStyles.bodyText),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel, style: AppTextStyles.bodyText),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task name cannot be empty',
                      style: AppTextStyles.bodyText),
                ),
              );
              return;
            }

            final taskName = _nameController.text.trim();
            final DateTime? taskDeadline =
                _isInheritingDeadline && !widget.isRootTask
                    ? null // null indicates inheriting from parent
                    : _getDateTime();

            Navigator.of(context).pop({
              'name': taskName,
              'rarity': _selectedRarity,
              'deadline': taskDeadline,
              'inheritDeadline': _isInheritingDeadline,
              'parent': _selectedParent, // Return the selected parent
              'taskType': _taskType, // Return the selected task type
            });
          },
          child: Text(AppStrings.save, style: AppTextStyles.bodyText),
        ),
      ],
    );
  }
}
