// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apps_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appsRepository)
final appsRepositoryProvider = AppsRepositoryProvider._();

final class AppsRepositoryProvider
    extends $FunctionalProvider<AppsRepository, AppsRepository, AppsRepository>
    with $Provider<AppsRepository> {
  AppsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppsRepository create(Ref ref) {
    return appsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppsRepository>(value),
    );
  }
}

String _$appsRepositoryHash() => r'5e8f7d45f4cb74c540a24fc81fcaaa7a0c02d04e';

/// Every app of the signed-in team, newest first.

@ProviderFor(appsStream)
final appsStreamProvider = AppsStreamProvider._();

/// Every app of the signed-in team, newest first.

final class AppsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppProject>>,
          List<AppProject>,
          Stream<List<AppProject>>
        >
    with $FutureModifier<List<AppProject>>, $StreamProvider<List<AppProject>> {
  /// Every app of the signed-in team, newest first.
  AppsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appsStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<AppProject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<AppProject>> create(Ref ref) {
    return appsStream(ref);
  }
}

String _$appsStreamHash() => r'392afc2ffee1b38d230678928298d899b673e570';

/// One app by id, or null while the list loads or when it is gone.

@ProviderFor(appById)
final appByIdProvider = AppByIdFamily._();

/// One app by id, or null while the list loads or when it is gone.

final class AppByIdProvider
    extends $FunctionalProvider<AppProject?, AppProject?, AppProject?>
    with $Provider<AppProject?> {
  /// One app by id, or null while the list loads or when it is gone.
  AppByIdProvider._({
    required AppByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'appByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appByIdHash();

  @override
  String toString() {
    return r'appByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AppProject?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppProject? create(Ref ref) {
    final argument = this.argument as String;
    return appById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppProject? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppProject?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appByIdHash() => r'f02265a3ffdb151b4a193558792755b1320c80f0';

/// One app by id, or null while the list loads or when it is gone.

final class AppByIdFamily extends $Family
    with $FunctionalFamilyOverride<AppProject?, String> {
  AppByIdFamily._()
    : super(
        retry: null,
        name: r'appByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One app by id, or null while the list loads or when it is gone.

  AppByIdProvider call(String appId) =>
      AppByIdProvider._(argument: appId, from: this);

  @override
  String toString() => r'appByIdProvider';
}
