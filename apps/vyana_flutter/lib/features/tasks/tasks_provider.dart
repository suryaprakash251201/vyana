import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vyana_flutter/core/api_client.dart';

part 'tasks_provider.g.dart';

class TaskList {
  final String id;
  final String title;
  
  TaskList({required this.id, required this.title});
  
  factory TaskList.fromJson(Map<String, dynamic> json) {
    return TaskList(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final bool isCompleted;
  final String? dueDate;
  final String? notes;
  final String? status;
  final String? parent; // For subtasks

  TaskItem({
    required this.id, 
    required this.title, 
    required this.isCompleted, 
    this.dueDate,
    this.notes,
    this.status,
    this.parent,
  });
  
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? json['status'] == 'completed',
      dueDate: json['due'] ?? json['due_date'],
      notes: json['notes'],
      status: json['status'],
      parent: json['parent'],
    );
  }
  
  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    try {
      final due = DateTime.parse(dueDate!);
      return due.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
  
  // Check if due today
  bool get isDueToday {
    if (dueDate == null) return false;
    try {
      final due = DateTime.parse(dueDate!);
      final now = DateTime.now();
      return due.year == now.year && due.month == now.month && due.day == now.day;
    } catch (_) {
      return false;
    }
  }
}

// Provider for task lists
@riverpod
Future<List<TaskList>> taskLists(Ref ref) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final res = await apiClient.get('/tasks/lists');
    if (res != null && res is List) {
      return res.map((e) => TaskList.fromJson(e)).toList();
    }
    return [TaskList(id: '@default', title: 'My Tasks')];
  } catch (e) {
    return [TaskList(id: '@default', title: 'My Tasks')];
  }
}

// Selected task list ID
@Riverpod(keepAlive: true)
class SelectedTaskList extends _$SelectedTaskList {
  @override
  String build() => '@default';
  
  void select(String id) => state = id;
}

// Show completed toggle
@Riverpod(keepAlive: true)
class ShowCompletedTasks extends _$ShowCompletedTasks {
  @override
  bool build() => false;
  
  void toggle() => state = !state;
}

// Sort option
enum TaskSortOption { dueDate, title, none }

@Riverpod(keepAlive: true)
class TaskSortBy extends _$TaskSortBy {
  @override
  TaskSortOption build() => TaskSortOption.dueDate;
  
  void set(TaskSortOption option) => state = option;
}

@Riverpod(keepAlive: true)
class Tasks extends _$Tasks {
  @override
  Future<List<TaskItem>> build() async {
    final taskListId = ref.watch(selectedTaskListProvider);
    final showCompleted = ref.watch(showCompletedTasksProvider);
    return _fetchTasks(taskListId, showCompleted);
  }

  Future<List<TaskItem>> _fetchTasks(String taskListId, bool showCompleted) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.get('/tasks/list?task_list_id=$taskListId&include_completed=$showCompleted');
      if (res != null && res is List) {
        return res.map((e) => TaskItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return []; 
    }
  }

  Future<void> createTask(String title, {String? notes, String? dueDate, String? parent}) async {
    final apiClient = ref.read(apiClientProvider);
    final taskListId = ref.read(selectedTaskListProvider);
    try {
      final body = <String, dynamic>{
        'title': title,
        'task_list_id': taskListId,
      };
      if (notes != null) body['notes'] = notes;
      if (dueDate != null) body['due_date'] = dueDate;
      if (parent != null) body['parent'] = parent;
      await apiClient.post('/tasks/create', body: body);
      ref.invalidateSelf(); 
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeTask(String id) async {
    final apiClient = ref.read(apiClientProvider);
    final taskListId = ref.read(selectedTaskListProvider);
    try {
      await apiClient.post('/tasks/complete', body: {'task_id': id, 'task_list_id': taskListId});
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uncompleteTask(String id) async {
    final apiClient = ref.read(apiClientProvider);
    final taskListId = ref.read(selectedTaskListProvider);
    try {
      await apiClient.post('/tasks/uncomplete', body: {'task_id': id, 'task_list_id': taskListId});
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(String id, {String? title, String? notes, String? dueDate}) async {
    final apiClient = ref.read(apiClientProvider);
    final taskListId = ref.read(selectedTaskListProvider);
    try {
      final body = <String, dynamic>{'task_id': id, 'task_list_id': taskListId};
      if (title != null) body['title'] = title;
      if (notes != null) body['notes'] = notes;
      if (dueDate != null) body['due_date'] = dueDate;
      await apiClient.post('/tasks/update', body: body);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    final apiClient = ref.read(apiClientProvider);
    final taskListId = ref.read(selectedTaskListProvider);
    try {
      await apiClient.post('/tasks/delete', body: {'task_id': id, 'task_list_id': taskListId});
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> clearCompleted() async {
    final apiClient = ref.read(apiClientProvider);
    final taskListId = ref.read(selectedTaskListProvider);
    try {
      await apiClient.post('/tasks/clear-completed?task_list_id=$taskListId', body: {});
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }
}
