import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A live query.
///
/// `.stream()` cannot join, and a release always needs its steps next to it.
/// So the query is re-run whenever realtime reports a change on any of
/// [tables], with a short debounce because the runner touches several tables
/// at once. [refresh] re-runs the query on demand — after this client's own
/// writes, so the screen that saved sees its change at once.
Stream<T> watchQuery<T>({
  required SupabaseClient client,
  required List<String> tables,
  required Future<T> Function() fetch,
  Stream<void>? refresh,
  String? filterColumn,
  String? filterValue,
}) {
  late final StreamController<T> controller;
  RealtimeChannel? channel;
  StreamSubscription<void>? refreshes;
  Timer? debounce;
  var isClosed = false;

  Future<void> emit() async {
    if (isClosed) return;
    try {
      final value = await fetch();
      if (!isClosed) controller.add(value);
    } catch (error, stackTrace) {
      if (!isClosed) controller.addError(error, stackTrace);
    }
  }

  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 150), emit);
  }

  controller = StreamController<T>(
    onListen: () {
      emit();
      refreshes = refresh?.listen((_) => schedule());
      channel = client.channel(
        'watch:${tables.join(',')}:${DateTime.now().microsecondsSinceEpoch}',
      );
      for (final table in tables) {
        channel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: filterColumn == null || filterValue == null
              ? null
              : PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: filterColumn,
                  value: filterValue,
                ),
          callback: (_) => schedule(),
        );
      }
      channel!.subscribe();
    },
    onCancel: () async {
      isClosed = true;
      debounce?.cancel();
      await refreshes?.cancel();
      refreshes = null;
      final open = channel;
      channel = null;
      if (open != null) await client.removeChannel(open);
    },
  );

  return controller.stream;
}
