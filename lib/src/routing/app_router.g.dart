// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the app opens. A test can start anywhere.

@ProviderFor(initialLocation)
final initialLocationProvider = InitialLocationProvider._();

/// Where the app opens. A test can start anywhere.

final class InitialLocationProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Where the app opens. A test can start anywhere.
  InitialLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialLocationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialLocationHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return initialLocation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$initialLocationHash() => r'5bf98a5444ad1297ee4513549387954a0854fec2';

/// The app's single [GoRouter].
///
/// Kept alive for the whole app lifetime — rebuilding it would reset the
/// navigation stack. Auth changes reach it through [refreshListenable], so
/// signing in or out re-runs the redirect only.

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// The app's single [GoRouter].
///
/// Kept alive for the whole app lifetime — rebuilding it would reset the
/// navigation stack. Auth changes reach it through [refreshListenable], so
/// signing in or out re-runs the redirect only.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's single [GoRouter].
  ///
  /// Kept alive for the whole app lifetime — rebuilding it would reset the
  /// navigation stack. Auth changes reach it through [refreshListenable], so
  /// signing in or out re-runs the redirect only.
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'7180e762e54fbd2ed3424d1486c80d4c7c01f968';
