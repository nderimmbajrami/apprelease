import 'package:apprelease_runner/src/pipeline.dart';
import 'package:apprelease_runner/src/steps/publish.dart';
import 'package:apprelease_runner/src/steps/versioning.dart';
import 'package:apprelease_runner/src/stores/app_store_connect.dart';
import 'package:test/test.dart';

void main() {
  test('an approved version says to raise it', () {
    final message = appleUploadError([
      "ERROR: Invalid Pre-Release Train. The train version '1.1.1' is closed "
          'for new build submissions (90186)',
      'This bundle is invalid. The value for key CFBundleShortVersionString '
          '[1.1.1] in the Info.plist file must contain a higher version '
          '(90062)',
    ]);
    expect(message, contains('Version 1.1.1 is already approved'));
    expect(message, contains('1.1.2'));
  });

  test('a missing app record names the fix', () {
    expect(
      appleUploadError(['No suitable application records were found.']),
      contains('Create the app'),
    );
  });

  test('anything else passes on what Apple said', () {
    expect(
      appleUploadError(['   description : Something unusual happened']),
      'App Store Connect: Something unusual happened',
    );
    expect(appleUploadError(['plain noise']), isNull);
  });

  test('versions compare part by part', () {
    expect(compareVersions('1.10.0', '1.9.3'), 1);
    expect(compareVersions('1.1.1', '1.1.1'), 0);
    expect(compareVersions('1.1', '1.1.1'), -1);
  });

  test('the version after an approved one', () {
    expect(nextVersionAfter('1.1.1'), '1.1.2');
    expect(nextVersionAfter('2.0'), '2.0.1');
  });

  test('the release version is written into pubspec.yaml', () {
    const pubspec = 'name: mekauto\nversion: 1.1.1+7\n\nenvironment:\n';
    expect(
      setPubspecVersion(pubspec, '1.1.2', 12),
      'name: mekauto\nversion: 1.1.2+12\n\nenvironment:\n',
    );
    expect(
      setPubspecVersion('name: x\n', '1.0.0', 1),
      'version: 1.0.0+1\nname: x\n',
    );
  });

  test('publishing values expand workflow vars', () {
    final env = {'GOOGLE_PLAY_TRACK': 'internal'};
    expect(expandVars(r'$GOOGLE_PLAY_TRACK', env), 'internal');
    expect(expandVars(r'${GOOGLE_PLAY_TRACK}', env), 'internal');
    expect(expandVars('production', env), 'production');
    expect(expandVars(r'$UNKNOWN', env), r'$UNKNOWN');
  });
}
