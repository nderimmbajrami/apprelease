import 'package:apprelease/src/features/releases/domain/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the allowance from the database', () {
    final usage = ReleaseUsage.fromJson({
      'used': 12,
      'limit': 30,
      'resets_at': '2026-12-01T00:00:00+00:00',
    })!;
    expect(usage.left, 18);
    expect(usage.exhausted, isFalse);
  });

  test('the last release of the month uses it up', () {
    final usage = ReleaseUsage.fromJson({'used': 30, 'limit': 30})!;
    expect(usage.exhausted, isTrue);
    expect(usage.left, 0);
  });

  test('no answer means no allowance shown', () {
    expect(ReleaseUsage.fromJson(null), isNull);
    expect(ReleaseUsage.fromJson({'used': 3}), isNull);
  });
}
