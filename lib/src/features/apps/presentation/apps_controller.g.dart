// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apps_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Adds, edits and removes applications.

@ProviderFor(AppsController)
final appsControllerProvider = AppsControllerProvider._();

/// Adds, edits and removes applications.
final class AppsControllerProvider
    extends $AsyncNotifierProvider<AppsController, void> {
  /// Adds, edits and removes applications.
  AppsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appsControllerHash();

  @$internal
  @override
  AppsController create() => AppsController();
}

String _$appsControllerHash() => r'e9be506c8ad9803cf2a1e35abb0773604c303088';

/// Adds, edits and removes applications.

abstract class _$AppsController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
