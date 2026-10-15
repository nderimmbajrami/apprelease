// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Drives the sign-in / sign-up forms. State is the in-flight request, not the
  /// session — the session lives in [authStateChangesProvider].
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'2c5f9b0f26b4ac17fd65961d725dcd232b3bc9ee';

/// Drives the sign-in / sign-up forms. State is the in-flight request, not the
/// session — the session lives in [authStateChangesProvider].

abstract class _$AuthController extends $AsyncNotifier<void> {
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
