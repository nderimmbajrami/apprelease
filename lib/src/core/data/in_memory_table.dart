import 'dart:async';

/// A tiny observable list that stands in for a remote table.
///
/// The public surface (a broadcast [watch] stream plus future-returning
/// mutations) is deliberately the same shape Supabase exposes, so repositories
/// can swap their storage without touching controllers or UI.
class InMemoryTable<T> {
  InMemoryTable([List<T> seed = const []]) : _rows = [...seed];

  final List<T> _rows;
  final _controller = StreamController<List<T>>.broadcast();

  List<T> get rows => List.unmodifiable(_rows);

  Stream<List<T>> watch() async* {
    yield rows;
    yield* _controller.stream;
  }

  T? find(bool Function(T row) test) {
    for (final row in _rows) {
      if (test(row)) return row;
    }
    return null;
  }

  void insert(T row) {
    _rows.add(row);
    _emit();
  }

  /// Replaces the first row matching [test], or appends [row] if none matches.
  void upsert(bool Function(T row) test, T row) {
    final index = _rows.indexWhere(test);
    if (index == -1) {
      _rows.add(row);
    } else {
      _rows[index] = row;
    }
    _emit();
  }

  void delete(bool Function(T row) test) {
    _rows.removeWhere(test);
    _emit();
  }

  void dispose() => _controller.close();

  void _emit() => _controller.add(rows);
}
