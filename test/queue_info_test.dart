import 'package:apprelease/src/features/releases/domain/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  QueueInfo q(int ahead, int running, int online) => QueueInfo(
    ahead: ahead,
    running: running,
    runnersOnline: online,
    averageBuild: const Duration(minutes: 10),
  );

  test('a free machine starts the release right away', () {
    expect(q(0, 0, 1).estimatedWait, Duration.zero);
  });

  test('a build in progress counts as half done', () {
    expect(q(0, 1, 1).estimatedWait, const Duration(minutes: 5));
  });

  test('two machines share the line', () {
    expect(q(2, 1, 1).estimatedWait, const Duration(minutes: 25));
    expect(q(2, 1, 2).estimatedWait, const Duration(seconds: 750));
  });

  test('no machine online is said, not estimated', () {
    expect(q(3, 0, 0).machinesOffline, isTrue);
    expect(q(3, 0, 0).estimatedWait, Duration.zero);
  });

  test('reads the database answer', () {
    final info = QueueInfo.fromJson({
      'ahead': 2,
      'running': 1,
      'runners_online': 1,
      'avg_seconds': 660,
    })!;
    expect(info.ahead, 2);
    expect(info.averageBuild, const Duration(minutes: 11));
  });
}
