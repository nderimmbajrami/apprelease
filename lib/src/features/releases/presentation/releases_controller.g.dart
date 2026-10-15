// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'releases_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReleasesController)
final releasesControllerProvider = ReleasesControllerProvider._();

final class ReleasesControllerProvider
    extends $AsyncNotifierProvider<ReleasesController, void> {
  ReleasesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'releasesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$releasesControllerHash();

  @$internal
  @override
  ReleasesController create() => ReleasesController();
}

String _$releasesControllerHash() =>
    r'9163825433a43a9bd7a6b47b62588c972d0deb9e';

abstract class _$ReleasesController extends $AsyncNotifier<void> {
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
