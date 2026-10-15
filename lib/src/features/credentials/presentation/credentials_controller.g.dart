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
    r'408fa5c69de923ce4e75ed39282fb6ea8988e924';

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
