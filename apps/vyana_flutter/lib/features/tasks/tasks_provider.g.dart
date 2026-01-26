// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskLists)
final taskListsProvider = TaskListsProvider._();

final class TaskListsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TaskList>>,
          List<TaskList>,
          FutureOr<List<TaskList>>
        >
    with $FutureModifier<List<TaskList>>, $FutureProvider<List<TaskList>> {
  TaskListsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskListsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskListsHash();

  @$internal
  @override
  $FutureProviderElement<List<TaskList>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TaskList>> create(Ref ref) {
    return taskLists(ref);
  }
}

String _$taskListsHash() => r'0e194ce0390ceb9bfe6424e6a510c5fe95ff857d';

@ProviderFor(SelectedTaskList)
final selectedTaskListProvider = SelectedTaskListProvider._();

final class SelectedTaskListProvider
    extends $NotifierProvider<SelectedTaskList, String> {
  SelectedTaskListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTaskListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTaskListHash();

  @$internal
  @override
  SelectedTaskList create() => SelectedTaskList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedTaskListHash() => r'ac0128727573715105f23dbe2eeb8942edd86abe';

abstract class _$SelectedTaskList extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ShowCompletedTasks)
final showCompletedTasksProvider = ShowCompletedTasksProvider._();

final class ShowCompletedTasksProvider
    extends $NotifierProvider<ShowCompletedTasks, bool> {
  ShowCompletedTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showCompletedTasksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showCompletedTasksHash();

  @$internal
  @override
  ShowCompletedTasks create() => ShowCompletedTasks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showCompletedTasksHash() =>
    r'88735c452423eb90a27155990c158817c2a2999d';

abstract class _$ShowCompletedTasks extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TaskSortBy)
final taskSortByProvider = TaskSortByProvider._();

final class TaskSortByProvider
    extends $NotifierProvider<TaskSortBy, TaskSortOption> {
  TaskSortByProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskSortByProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskSortByHash();

  @$internal
  @override
  TaskSortBy create() => TaskSortBy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskSortOption value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskSortOption>(value),
    );
  }
}

String _$taskSortByHash() => r'309cdc6804328c9c9645b49a7138ebd63e63a8e8';

abstract class _$TaskSortBy extends $Notifier<TaskSortOption> {
  TaskSortOption build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TaskSortOption, TaskSortOption>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TaskSortOption, TaskSortOption>,
              TaskSortOption,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Tasks)
final tasksProvider = TasksProvider._();

final class TasksProvider
    extends $AsyncNotifierProvider<Tasks, List<TaskItem>> {
  TasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tasksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasksHash();

  @$internal
  @override
  Tasks create() => Tasks();
}

String _$tasksHash() => r'246e7fe734364244a6fac747f075dd104e5da44a';

abstract class _$Tasks extends $AsyncNotifier<List<TaskItem>> {
  FutureOr<List<TaskItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TaskItem>>, List<TaskItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TaskItem>>, List<TaskItem>>,
              AsyncValue<List<TaskItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
