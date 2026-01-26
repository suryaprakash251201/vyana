import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vyana_flutter/core/theme.dart';
import 'package:vyana_flutter/features/tasks/tasks_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      ref.invalidate(tasksProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final taskListsAsync = ref.watch(taskListsProvider);
    final selectedListId = ref.watch(selectedTaskListProvider);
    final showCompleted = ref.watch(showCompletedTasksProvider);
    final sortBy = ref.watch(taskSortByProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accentTeal.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Tasks',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          tasksAsync.when(
                            data: (tasks) {
                              final pending = tasks.where((t) => !t.isCompleted).length;
                              final overdue = tasks.where((t) => t.isOverdue).length;
                              return Row(
                                children: [
                                  Text(
                                    '$pending pending',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                  if (overdue > 0) ...[
                                    const Gap(8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$overdue overdue',
                                        style: TextStyle(color: AppColors.errorRed, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    // Menu button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'refresh') {
                          ref.invalidate(tasksProvider);
                        } else if (value == 'toggle_completed') {
                          ref.read(showCompletedTasksProvider.notifier).toggle();
                        } else if (value == 'clear_completed') {
                          _showClearCompletedConfirmation(context, ref);
                        } else if (value == 'sort_due') {
                          ref.read(taskSortByProvider.notifier).set(TaskSortOption.dueDate);
                        } else if (value == 'sort_title') {
                          ref.read(taskSortByProvider.notifier).set(TaskSortOption.title);
                        } else if (value == 'sort_none') {
                          ref.read(taskSortByProvider.notifier).set(TaskSortOption.none);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'refresh', child: Row(
                          children: [Icon(Icons.refresh, size: 20), Gap(8), Text('Refresh')],
                        )),
                        PopupMenuItem(
                          value: 'toggle_completed',
                          child: Row(
                            children: [
                              Icon(showCompleted ? Icons.visibility_off : Icons.visibility, size: 20),
                              const Gap(8),
                              Text(showCompleted ? 'Hide completed' : 'Show completed'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'sort_due',
                          child: Row(
                            children: [
                              Icon(Icons.sort, size: 20, color: sortBy == TaskSortOption.dueDate ? AppColors.accentTeal : null),
                              const Gap(8),
                              Text('Sort by due date', style: TextStyle(
                                fontWeight: sortBy == TaskSortOption.dueDate ? FontWeight.bold : null,
                              )),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'sort_title',
                          child: Row(
                            children: [
                              Icon(Icons.sort_by_alpha, size: 20, color: sortBy == TaskSortOption.title ? AppColors.accentTeal : null),
                              const Gap(8),
                              Text('Sort by title', style: TextStyle(
                                fontWeight: sortBy == TaskSortOption.title ? FontWeight.bold : null,
                              )),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'clear_completed',
                          child: Row(
                            children: [Icon(Icons.clear_all, size: 20, color: Colors.red), Gap(8), Text('Clear completed', style: TextStyle(color: Colors.red))],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Task List Selector
              taskListsAsync.when(
                data: (lists) {
                  if (lists.length <= 1) return const SizedBox.shrink();
                  return Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];
                        final isSelected = list.id == selectedListId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(list.title),
                            selected: isSelected,
                            onSelected: (_) => ref.read(selectedTaskListProvider.notifier).select(list.id),
                            selectedColor: AppColors.accentTeal.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.accentTeal : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              // Tasks List
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    if (tasks.isEmpty) return _buildEmptyState(theme, showCompleted);
                    
                    // Sort tasks
                    final sortedTasks = _sortTasks(tasks, sortBy);
                    
                    // Separate into parent tasks and subtasks
                    final parentTasks = sortedTasks.where((t) => t.parent == null).toList();
                    final subtasksMap = <String, List<TaskItem>>{};
                    for (final task in sortedTasks.where((t) => t.parent != null)) {
                      subtasksMap.putIfAbsent(task.parent!, () => []).add(task);
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: parentTasks.length,
                      itemBuilder: (context, index) {
                        final task = parentTasks[index];
                        final subtasks = subtasksMap[task.id] ?? [];
                        return _buildTaskItem(context, ref, task, subtasks, theme);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const Gap(16),
                        Text('Error loading tasks', style: theme.textTheme.titleMedium),
                        const Gap(8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text('$e', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                        ),
                        const Gap(16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(tasksProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.secondaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAddTaskDialog(context, ref),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  List<TaskItem> _sortTasks(List<TaskItem> tasks, TaskSortOption sortBy) {
    final sorted = List<TaskItem>.from(tasks);
    switch (sortBy) {
      case TaskSortOption.dueDate:
        sorted.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOption.title:
        sorted.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case TaskSortOption.none:
        sorted.sort((a, b) => a.isCompleted != b.isCompleted ? (a.isCompleted ? 1 : -1) : 0);
        break;
    }
    return sorted;
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, TaskItem task, List<TaskItem> subtasks, ThemeData theme) {
    Color? dueDateColor;
    String? dueDateText;
    IconData dueDateIcon = Icons.calendar_today_outlined;
    
    if (task.dueDate != null && !task.isCompleted) {
      try {
        final due = DateTime.parse(task.dueDate!);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDay = DateTime(due.year, due.month, due.day);
        
        if (dueDay.isBefore(today)) {
          dueDateColor = AppColors.errorRed;
          dueDateIcon = Icons.warning_amber_rounded;
          final diff = today.difference(dueDay).inDays;
          dueDateText = diff == 1 ? 'Yesterday' : '$diff days overdue';
        } else if (dueDay.isAtSameMomentAs(today)) {
          dueDateColor = AppColors.warmOrange;
          dueDateIcon = Icons.today;
          dueDateText = 'Today';
        } else if (dueDay.difference(today).inDays == 1) {
          dueDateColor = AppColors.accentTeal;
          dueDateText = 'Tomorrow';
        } else if (dueDay.difference(today).inDays <= 7) {
          dueDateColor = Colors.blue;
          dueDateText = _formatDueDate(due);
        } else {
          dueDateColor = Colors.grey.shade600;
          dueDateText = _formatDueDate(due);
        }
      } catch (_) {
        dueDateText = task.dueDate;
        dueDateColor = Colors.grey.shade600;
      }
    } else if (task.dueDate != null) {
      dueDateText = _formatDueDate(DateTime.tryParse(task.dueDate!) ?? DateTime.now());
      dueDateColor = Colors.grey.shade400;
    }

    return Dismissible(
      key: Key(task.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(task.isCompleted ? Icons.undo : Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.errorRed, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (task.isCompleted) {
            ref.read(tasksProvider.notifier).uncompleteTask(task.id);
          } else {
            ref.read(tasksProvider.notifier).completeTask(task.id);
          }
          return false;
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Task'),
              content: Text('Delete "${task.title}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
              ],
            ),
          ) ?? false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(tasksProvider.notifier).deleteTask(task.id);
        }
      },
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: subtasks.isEmpty ? 12 : 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: task.isOverdue ? Border.all(color: AppColors.errorRed.withOpacity(0.3), width: 1) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: GestureDetector(
                onTap: () {
                  if (task.isCompleted) {
                    ref.read(tasksProvider.notifier).uncompleteTask(task.id);
                  } else {
                    ref.read(tasksProvider.notifier).completeTask(task.id);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: task.isCompleted ? AppColors.secondaryGradient : null,
                    border: task.isCompleted ? null : Border.all(color: task.isOverdue ? AppColors.errorRed : Colors.grey.shade400, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: task.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              ),
              title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w500, decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: task.isCompleted ? Colors.grey : null)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                    const Gap(4),
                    Text(task.notes!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (dueDateText != null) ...[
                    const Gap(4),
                    Row(children: [
                      Icon(dueDateIcon, size: 14, color: dueDateColor),
                      const Gap(4),
                      Text(dueDateText, style: TextStyle(color: dueDateColor, fontSize: 12, fontWeight: task.isOverdue ? FontWeight.w600 : null)),
                    ]),
                  ],
                  if (subtasks.isNotEmpty) ...[
                    const Gap(4),
                    Row(children: [
                      Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey.shade500),
                      const Gap(4),
                      Text('${subtasks.where((s) => s.isCompleted).length}/${subtasks.length} subtasks', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ]),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade500, size: 20), onPressed: () => _showAddSubtaskDialog(context, ref, task.id), tooltip: 'Add subtask'),
                  IconButton(icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 20), onPressed: () => _showEditTaskDialog(context, ref, task), tooltip: 'Edit task'),
                ],
              ),
              onTap: () => _showTaskDetails(context, ref, task, subtasks),
            ),
          ),
          if (subtasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 12),
              child: Column(children: subtasks.map((subtask) => _buildSubtaskItem(context, ref, subtask, theme)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(BuildContext context, WidgetRef ref, TaskItem subtask, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: theme.colorScheme.surface.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: GestureDetector(
          onTap: () {
            if (subtask.isCompleted) {
              ref.read(tasksProvider.notifier).uncompleteTask(subtask.id);
            } else {
              ref.read(tasksProvider.notifier).completeTask(subtask.id);
            }
          },
          child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              gradient: subtask.isCompleted ? AppColors.secondaryGradient : null,
              border: subtask.isCompleted ? null : Border.all(color: Colors.grey.shade400, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: subtask.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
        ),
        title: Text(subtask.title, style: TextStyle(fontSize: 14, decoration: subtask.isCompleted ? TextDecoration.lineThrough : null, color: subtask.isCompleted ? Colors.grey : null)),
        trailing: IconButton(icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400), onPressed: () => ref.read(tasksProvider.notifier).deleteTask(subtask.id)),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildEmptyState(ThemeData theme, bool showingCompleted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.accentTeal.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.checklist_rtl_rounded, size: 64, color: AppColors.accentTeal)),
            const Gap(24),
            Text(showingCompleted ? 'No tasks found' : 'All caught up!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Gap(8),
            Text('Tap the + button to add a new task', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, WidgetRef ref, TaskItem task, List<TaskItem> subtasks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const Gap(12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const Gap(20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Row(children: [
                      Expanded(child: Text(task.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, decoration: task.isCompleted ? TextDecoration.lineThrough : null))),
                      IconButton(icon: const Icon(Icons.edit), onPressed: () { Navigator.pop(context); _showEditTaskDialog(context, ref, task); }),
                    ]),
                    if (task.notes != null && task.notes!.isNotEmpty) ...[
                      const Gap(16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.notes, size: 20, color: Colors.grey.shade600), const Gap(12), Expanded(child: Text(task.notes!, style: TextStyle(color: Colors.grey.shade800)))]),
                      ),
                    ],
                    if (task.dueDate != null) ...[
                      const Gap(16),
                      Row(children: [
                        Icon(Icons.calendar_today, size: 20, color: task.isOverdue ? AppColors.errorRed : AppColors.accentTeal),
                        const Gap(12),
                        Text('Due: ${_formatDueDate(DateTime.tryParse(task.dueDate!) ?? DateTime.now())}', style: TextStyle(color: task.isOverdue ? AppColors.errorRed : null, fontWeight: task.isOverdue ? FontWeight.w600 : null)),
                        if (task.isOverdue) ...[const Gap(8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text('OVERDUE', style: TextStyle(color: AppColors.errorRed, fontSize: 10, fontWeight: FontWeight.bold)))],
                      ]),
                    ],
                    const Gap(24),
                    Row(children: [
                      Text('Subtasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(onPressed: () { Navigator.pop(context); _showAddSubtaskDialog(context, ref, task.id); }, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
                    ]),
                    if (subtasks.isEmpty)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('No subtasks', style: TextStyle(color: Colors.grey.shade500)))
                    else
                      ...subtasks.map((s) => _buildSubtaskItem(context, ref, s, Theme.of(context))),
                    const Gap(32),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); if (task.isCompleted) { ref.read(tasksProvider.notifier).uncompleteTask(task.id); } else { ref.read(tasksProvider.notifier).completeTask(task.id); } }, icon: Icon(task.isCompleted ? Icons.undo : Icons.check), label: Text(task.isCompleted ? 'Mark incomplete' : 'Mark complete'))),
                      const Gap(12),
                      IconButton(onPressed: () { Navigator.pop(context); _showDeleteConfirmation(context, ref, task); }, icon: const Icon(Icons.delete_outline, color: Colors.red)),
                    ]),
                    const Gap(24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDueDate;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const Gap(20),
              Text('New Task', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(16),
              TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'What needs to be done?', prefixIcon: Icon(Icons.edit_outlined, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), textInputAction: TextInputAction.next),
              const Gap(12),
              TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(hintText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_outlined, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const Gap(12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () async { final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030)); if (date != null) setState(() => selectedDueDate = date); }, icon: const Icon(Icons.calendar_today), label: Text(selectedDueDate != null ? _formatDueDate(selectedDueDate!) : 'Add due date'))),
                if (selectedDueDate != null) ...[const Gap(8), IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => selectedDueDate = null))],
              ]),
              const Gap(20),
              Container(
                decoration: BoxDecoration(gradient: AppColors.secondaryGradient, borderRadius: BorderRadius.circular(16)),
                child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () { if (controller.text.isNotEmpty) { String? dueDateStr; if (selectedDueDate != null) { dueDateStr = '${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}'; } ref.read(tasksProvider.notifier).createTask(controller.text, notes: notesController.text.isNotEmpty ? notesController.text : null, dueDate: dueDateStr); Navigator.pop(context); } }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_rounded, color: Colors.white), Gap(8), Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))])))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubtaskDialog(BuildContext context, WidgetRef ref, String parentId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const Gap(20),
            Text('Add Subtask', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Gap(16),
            TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: 'Subtask title', prefixIcon: Icon(Icons.subdirectory_arrow_right, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onSubmitted: (value) { if (value.isNotEmpty) { ref.read(tasksProvider.notifier).createTask(value, parent: parentId); Navigator.pop(context); } }),
            const Gap(20),
            FilledButton(onPressed: () { if (controller.text.isNotEmpty) { ref.read(tasksProvider.notifier).createTask(controller.text, parent: parentId); Navigator.pop(context); } }, child: const Text('Add Subtask')),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, WidgetRef ref, TaskItem task) {
    final titleController = TextEditingController(text: task.title);
    final notesController = TextEditingController(text: task.notes ?? '');
    DateTime? selectedDueDate;
    if (task.dueDate != null) { try { selectedDueDate = DateTime.parse(task.dueDate!); } catch (_) {} }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const Gap(20),
              Text('Edit Task', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(16),
              TextField(controller: titleController, autofocus: true, decoration: InputDecoration(labelText: 'Task Title', prefixIcon: Icon(Icons.edit_outlined, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const Gap(12),
              TextField(controller: notesController, maxLines: 2, decoration: InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes_outlined, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const Gap(12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () async { final date = await showDatePicker(context: context, initialDate: selectedDueDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030)); if (date != null) setState(() => selectedDueDate = date); }, icon: const Icon(Icons.calendar_today), label: Text(selectedDueDate != null ? _formatDueDate(selectedDueDate!) : 'Add due date'))),
                if (selectedDueDate != null) ...[const Gap(8), IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => selectedDueDate = null))],
              ]),
              const Gap(20),
              Container(
                decoration: BoxDecoration(gradient: AppColors.secondaryGradient, borderRadius: BorderRadius.circular(16)),
                child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () { if (titleController.text.isNotEmpty) { String? dueDateStr; if (selectedDueDate != null) { dueDateStr = '${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}'; } ref.read(tasksProvider.notifier).updateTask(task.id, title: titleController.text, notes: notesController.text.isNotEmpty ? notesController.text : null, dueDate: dueDateStr); Navigator.pop(context); } }, child: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_rounded, color: Colors.white), Gap(8), Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))])))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, TaskItem task) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete Task'),
      content: Text('Are you sure you want to delete "${task.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { ref.read(tasksProvider.notifier).deleteTask(task.id); Navigator.pop(context); }, style: TextButton.styleFrom(foregroundColor: AppColors.errorRed), child: const Text('Delete')),
      ],
    ));
  }

  void _showClearCompletedConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Clear Completed'),
      content: const Text('Remove all completed tasks from this list?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () { ref.read(tasksProvider.notifier).clearCompleted(); Navigator.pop(context); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Clear')),
      ],
    ));
  }
}
