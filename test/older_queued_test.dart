import 'package:apprelease/src/features/releases/domain/release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Release r(
    int number,
    ReleaseTrack track,
    String branch, {
    ReleaseStatus status = ReleaseStatus.queued,
  }) => Release(
    id: '$number',
    appId: 'app',
    teamId: 'team',
    number: number,
    platform: track.platform,
    track: track,
    versionName: Release.autoVersion,
    branch: branch,
    startedByName: 'GitHub push',
    createdAt: DateTime(2026, 10, 28, 12, number),
    status: status,
  );

  test('keeps the newest waiting release of each platform and branch', () {
    final older = olderQueued([
      r(48, ReleaseTrack.appStore, 'main'),
      r(47, ReleaseTrack.production, 'main'),
      r(46, ReleaseTrack.testflight, 'develop'),
      r(45, ReleaseTrack.internal, 'develop'),
      r(44, ReleaseTrack.testflight, 'develop'),
      r(43, ReleaseTrack.internal, 'develop'),
      r(42, ReleaseTrack.appStore, 'main'),
      r(41, ReleaseTrack.production, 'main'),
    ]);
    expect([for (final x in older) x.number], [44, 43, 42, 41]);
  });

  test('a running or finished release is never counted', () {
    final older = olderQueued([
      r(3, ReleaseTrack.internal, 'develop'),
      r(2, ReleaseTrack.internal, 'develop', status: ReleaseStatus.running),
      r(1, ReleaseTrack.internal, 'develop', status: ReleaseStatus.failed),
    ]);
    expect(older, isEmpty);
  });

  test('the same branch on two platforms keeps one of each', () {
    final older = olderQueued([
      r(2, ReleaseTrack.internal, 'main'),
      r(1, ReleaseTrack.testflight, 'main'),
    ]);
    expect(older, isEmpty);
  });
}
