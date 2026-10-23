import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_extension.dart';
import 'empty_state.dart';

/// Renders an [AsyncValue] with consistent loading and error states.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // No cross-fade: a fade showed the spinner and the page at once.
    return switch (value) {
      AsyncValue(hasValue: true, value: final loaded) => data(loaded as T),
      AsyncValue(hasError: true, error: final error) => ErrorView(
        error: error!,
        onRetry: onRetry,
      ),
      _ => const Center(
        child: SizedBox.square(
          dimension: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    };
  }
}

/// Something went wrong, and the one button that might fix it.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: l10n.somethingWentWrong,
      message: '$error',
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
            ),
    );
  }
}
