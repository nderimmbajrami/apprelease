// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backend)
final backendProvider = BackendProvider._();

final class BackendProvider
    extends $FunctionalProvider<Backend, Backend, Backend>
    with $Provider<Backend> {
  BackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendHash();

  @$internal
  @override
  $ProviderElement<Backend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Backend create(Ref ref) {
    return backend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Backend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Backend>(value),
    );
  }
}

String _$backendHash() => r'282a7cdfc4ea8db7633823521076f1f2c1d44a07';

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'3db2a4c212c7f24cea9810e376225aa1a6cab012';
