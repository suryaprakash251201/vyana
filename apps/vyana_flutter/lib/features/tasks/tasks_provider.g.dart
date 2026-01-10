// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$tasksHash() => r'9a8247e31a664f32a3d46d77f7624420d920ea49';

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
