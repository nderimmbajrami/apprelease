import 'package:apprelease_runner/src/steps/publish.dart';
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
}
