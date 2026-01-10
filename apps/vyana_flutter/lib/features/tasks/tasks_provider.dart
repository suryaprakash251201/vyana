import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vyana_flutter/core/api_client.dart';

part 'tasks_provider.g.dart';

class TaskItem {
  final int id;
  final String title;
  final bool isCompleted;
  final String? dueDate;

  TaskItem({required this.id, required this.title, required this.isCompleted, this.dueDate});
  
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      isCompleted: json['is_completed'],
      dueDate: json['due_date'],
    );
  }
}

@Riverpod(keepAlive: true)
class Tasks extends _$Tasks {
  @override
  Future<List<TaskItem>> build() async {
    return _fetchTasks();
  }

  Future<List<TaskItem>> _fetchTasks() async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.get('/tasks/list');
      if (res != null) {
        final List<dynamic> list = res;
        return list.map((e) => TaskItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // In a real app, handle error state better or rethrow
      return []; 
    }
  }

  Future<void> createTask(String title) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('/tasks/create', body: {'title': title});
      // Invalidate self to refetch
      ref.invalidateSelf(); 
    } catch (e) {
      // Handle error
    }
  }

  Future<void> completeTask(int id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('/tasks/complete', body: {'task_id': id});
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateTask(int id, {String? title, String? dueDate}) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final body = <String, dynamic>{'task_id': id};
      if (title != null) body['title'] = title;
      if (dueDate != null) body['due_date'] = dueDate;
      await apiClient.post('/tasks/update', body: body);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteTask(int id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('/tasks/delete', body: {'task_id': id});
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }
}
