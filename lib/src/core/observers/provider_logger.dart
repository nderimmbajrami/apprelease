import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs provider lifecycle. Debug builds only — release keeps it silent.
final class ProviderLogger extends ProviderObserver {
  const ProviderLogger();

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!kDebugMode) return;
    developer.log('${_name(context)} -> $newValue', name: 'riverpod');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      '${_name(context)} failed',
      name: 'riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _name(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();
}
