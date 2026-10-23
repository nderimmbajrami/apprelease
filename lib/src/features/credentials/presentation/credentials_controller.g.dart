// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CredentialsController)
final credentialsControllerProvider = CredentialsControllerProvider._();

final class CredentialsControllerProvider
    extends $AsyncNotifierProvider<CredentialsController, void> {
  CredentialsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsControllerHash();

  @$internal
  @override
  CredentialsController create() => CredentialsController();
}

String _$credentialsControllerHash() =>
    r'f086f041ef8b2ca8436000f32bd2bd2525467d54';

abstract class _$CredentialsController extends $AsyncNotifier<void> {
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
