// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Search query notifier

@ProviderFor(ContactSearchQuery)
final contactSearchQueryProvider = ContactSearchQueryProvider._();

/// Search query notifier
final class ContactSearchQueryProvider
    extends $NotifierProvider<ContactSearchQuery, String> {
  /// Search query notifier
  ContactSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactSearchQueryHash();

  @$internal
  @override
  ContactSearchQuery create() => ContactSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$contactSearchQueryHash() =>
    r'f72fc1d83f47f240675c1e97e7adf832236d4f81';

/// Search query notifier

abstract class _$ContactSearchQuery extends $Notifier<String> {
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

/// Filter - favorites only notifier

@ProviderFor(ContactFavoritesOnly)
final contactFavoritesOnlyProvider = ContactFavoritesOnlyProvider._();

/// Filter - favorites only notifier
final class ContactFavoritesOnlyProvider
    extends $NotifierProvider<ContactFavoritesOnly, bool> {
  /// Filter - favorites only notifier
  ContactFavoritesOnlyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactFavoritesOnlyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactFavoritesOnlyHash();

  @$internal
  @override
  ContactFavoritesOnly create() => ContactFavoritesOnly();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$contactFavoritesOnlyHash() =>
    r'5fc0f7f54a718c9cc80e8c20d86d8734e41d6762';

/// Filter - favorites only notifier

abstract class _$ContactFavoritesOnly extends $Notifier<bool> {
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

@ProviderFor(contacts)
final contactsProvider = ContactsProvider._();

final class ContactsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Contact>>,
          List<Contact>,
          FutureOr<List<Contact>>
        >
    with $FutureModifier<List<Contact>>, $FutureProvider<List<Contact>> {
  ContactsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactsHash();

  @$internal
  @override
  $FutureProviderElement<List<Contact>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Contact>> create(Ref ref) {
    return contacts(ref);
  }
}

String _$contactsHash() => r'33765cb05d57b564b4d3a5eba9e5b5bbdf5426a6';

@ProviderFor(ContactController)
final contactControllerProvider = ContactControllerProvider._();

final class ContactControllerProvider
    extends $NotifierProvider<ContactController, AsyncValue<void>> {
  ContactControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactControllerHash();

  @$internal
  @override
  ContactController create() => ContactController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$contactControllerHash() => r'6108f89d839f812d37c7d8dc761c4b64a3fc1444';

abstract class _$ContactController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
