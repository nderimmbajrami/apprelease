// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credentials_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(credentialsRepository)
final credentialsRepositoryProvider = CredentialsRepositoryProvider._();

final class CredentialsRepositoryProvider
    extends
        $FunctionalProvider<
          CredentialsRepository,
          CredentialsRepository,
          CredentialsRepository
        >
    with $Provider<CredentialsRepository> {
  CredentialsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CredentialsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CredentialsRepository create(Ref ref) {
    return credentialsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CredentialsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CredentialsRepository>(value),
    );
  }
}

String _$credentialsRepositoryHash() =>
    r'cfcbccd239bb30c67bc049cb2390de332ff285d2';

@ProviderFor(credentialsStream)
final credentialsStreamProvider = CredentialsStreamProvider._();

final class CredentialsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Credential>>,
          List<Credential>,
          Stream<List<Credential>>
        >
    with $FutureModifier<List<Credential>>, $StreamProvider<List<Credential>> {
  CredentialsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialsStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Credential>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Credential>> create(Ref ref) {
    return credentialsStream(ref);
  }
}

String _$credentialsStreamHash() => r'eb4f26e074e530918c4bcabe7ee9a9fece2b7925';

/// The credentials of one kind, for the yaml generator and the forms.

@ProviderFor(credentialsOfKind)
final credentialsOfKindProvider = CredentialsOfKindFamily._();

/// The credentials of one kind, for the yaml generator and the forms.

final class CredentialsOfKindProvider
    extends
        $FunctionalProvider<
          List<Credential>,
          List<Credential>,
          List<Credential>
        >
    with $Provider<List<Credential>> {
  /// The credentials of one kind, for the yaml generator and the forms.
  CredentialsOfKindProvider._({
    required CredentialsOfKindFamily super.from,
    required CredentialKind super.argument,
  }) : super(
         retry: null,
         name: r'credentialsOfKindProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$credentialsOfKindHash();

  @override
  String toString() {
    return r'credentialsOfKindProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Credential>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Credential> create(Ref ref) {
    final argument = this.argument as CredentialKind;
    return credentialsOfKind(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Credential> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Credential>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CredentialsOfKindProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$credentialsOfKindHash() => r'd9d456027eac8716ff96139bf57086e5bfd5144e';

/// The credentials of one kind, for the yaml generator and the forms.

final class CredentialsOfKindFamily extends $Family
    with $FunctionalFamilyOverride<List<Credential>, CredentialKind> {
  CredentialsOfKindFamily._()
    : super(
        retry: null,
        name: r'credentialsOfKindProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The credentials of one kind, for the yaml generator and the forms.

  CredentialsOfKindProvider call(CredentialKind kind) =>
      CredentialsOfKindProvider._(argument: kind, from: this);

  @override
  String toString() => r'credentialsOfKindProvider';
}
