// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'releases_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(releasesRepository)
final releasesRepositoryProvider = ReleasesRepositoryProvider._();

final class ReleasesRepositoryProvider
    extends
        $FunctionalProvider<
          ReleasesRepository,
          ReleasesRepository,
          ReleasesRepository
        >
    with $Provider<ReleasesRepository> {
  ReleasesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'releasesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$releasesRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReleasesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReleasesRepository create(Ref ref) {
    return releasesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReleasesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReleasesRepository>(value),
    );
  }
}

String _$releasesRepositoryHash() =>
    r'323234af0299a6a1157df4570218aa0a1a725182';

@ProviderFor(releasesStream)
final releasesStreamProvider = ReleasesStreamProvider._();

final class ReleasesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Release>>,
          List<Release>,
          Stream<List<Release>>
        >
    with $FutureModifier<List<Release>>, $StreamProvider<List<Release>> {
  ReleasesStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'releasesStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$releasesStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Release>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Release>> create(Ref ref) {
    return releasesStream(ref);
  }
}

String _$releasesStreamHash() => r'52e7a12ea696eb51fed0445261d62dd99e0ef2c2';

/// The releases of one app, newest first.

@ProviderFor(releasesOfApp)
final releasesOfAppProvider = ReleasesOfAppFamily._();

/// The releases of one app, newest first.

final class ReleasesOfAppProvider
    extends $FunctionalProvider<List<Release>, List<Release>, List<Release>>
    with $Provider<List<Release>> {
  /// The releases of one app, newest first.
  ReleasesOfAppProvider._({
    required ReleasesOfAppFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'releasesOfAppProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$releasesOfAppHash();

  @override
  String toString() {
    return r'releasesOfAppProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Release>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Release> create(Ref ref) {
    final argument = this.argument as String;
    return releasesOfApp(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Release> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Release>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReleasesOfAppProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$releasesOfAppHash() => r'a4d25f3163bbcf5e6442e19125a5b3312f9906ec';

/// The releases of one app, newest first.

final class ReleasesOfAppFamily extends $Family
    with $FunctionalFamilyOverride<List<Release>, String> {
  ReleasesOfAppFamily._()
    : super(
        retry: null,
        name: r'releasesOfAppProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The releases of one app, newest first.

  ReleasesOfAppProvider call(String appId) =>
      ReleasesOfAppProvider._(argument: appId, from: this);

  @override
  String toString() => r'releasesOfAppProvider';
}

@ProviderFor(releaseStream)
final releaseStreamProvider = ReleaseStreamFamily._();

final class ReleaseStreamProvider
    extends
        $FunctionalProvider<AsyncValue<Release?>, Release?, Stream<Release?>>
    with $FutureModifier<Release?>, $StreamProvider<Release?> {
  ReleaseStreamProvider._({
    required ReleaseStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'releaseStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$releaseStreamHash();

  @override
  String toString() {
    return r'releaseStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Release?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Release?> create(Ref ref) {
    final argument = this.argument as String;
    return releaseStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReleaseStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$releaseStreamHash() => r'8a3fd0751143451ccb0413897cb3655c70045be2';

final class ReleaseStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Release?>, String> {
  ReleaseStreamFamily._()
    : super(
        retry: null,
        name: r'releaseStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReleaseStreamProvider call(String releaseId) =>
      ReleaseStreamProvider._(argument: releaseId, from: this);

  @override
  String toString() => r'releaseStreamProvider';
}

@ProviderFor(releaseLog)
final releaseLogProvider = ReleaseLogFamily._();

final class ReleaseLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LogLine>>,
          List<LogLine>,
          Stream<List<LogLine>>
        >
    with $FutureModifier<List<LogLine>>, $StreamProvider<List<LogLine>> {
  ReleaseLogProvider._({
    required ReleaseLogFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'releaseLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$releaseLogHash();

  @override
  String toString() {
    return r'releaseLogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LogLine>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LogLine>> create(Ref ref) {
    final argument = this.argument as String;
    return releaseLog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReleaseLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$releaseLogHash() => r'26a2e9de4b6c252d80b7868ba5b9d4f81429a343';

final class ReleaseLogFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LogLine>>, String> {
  ReleaseLogFamily._()
    : super(
        retry: null,
        name: r'releaseLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReleaseLogProvider call(String releaseId) =>
      ReleaseLogProvider._(argument: releaseId, from: this);

  @override
  String toString() => r'releaseLogProvider';
}
