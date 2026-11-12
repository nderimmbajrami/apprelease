import 'package:apprelease_runner/runner.dart';
import 'package:test/test.dart';

const _flutterPlist = '''
	<key>CFBundleShortVersionString</key>
	<string>\$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleVersion</key>
	<string>\$(FLUTTER_BUILD_NUMBER)</string>
''';
const _marketingPlist = '''
	<key>CFBundleShortVersionString</key>
	<string>\$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>\$(CURRENT_PROJECT_VERSION)</string>
''';
const _fixedPbxproj = '''
				CURRENT_PROJECT_VERSION = 75;
				MARKETING_VERSION = 2.4.3;
				PRODUCT_BUNDLE_IDENTIFIER = com.example.app;
				CURRENT_PROJECT_VERSION = 75;
				MARKETING_VERSION = "2.4.3";
				CURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)";
				MARKETING_VERSION = "\$(FLUTTER_BUILD_NAME)";
''';

void main() {
  test('a project as Flutter made it takes its version from pubspec', () {
    expect(
      xcodeFixedVersion(
        pbxproj: 'CURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)";',
        plist: _flutterPlist,
      ),
      isNull,
    );
    // A number left in the project is not used when Info.plist does not
    // point at it.
    expect(
      xcodeFixedVersion(pbxproj: _fixedPbxproj, plist: _flutterPlist),
      isNull,
    );
  });

  test('a version typed into Xcode is found', () {
    expect(
      xcodeFixedVersion(pbxproj: _fixedPbxproj, plist: _marketingPlist),
      '2.4.3',
    );
    expect(
      xcodeFixedVersion(
        plist: _flutterPlist.replaceFirst('\$(FLUTTER_BUILD_NAME)', '2.4.3'),
      ),
      '2.4.3',
    );
  });

  test('the fixed numbers are replaced, Flutter\'s references kept', () {
    final out = setPbxprojVersion(_fixedPbxproj, '2.4.4', 76);
    expect('MARKETING_VERSION = 2.4.4;'.allMatches(out).length, 2);
    expect('CURRENT_PROJECT_VERSION = 76;'.allMatches(out).length, 2);
    expect(out, isNot(contains('2.4.3')));
    expect(out, contains('MARKETING_VERSION = "\$(FLUTTER_BUILD_NAME)";'));
    expect(
      out,
      contains('CURRENT_PROJECT_VERSION = "\$(FLUTTER_BUILD_NUMBER)";'),
    );
    expect(out, contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.app;'));
    expect(xcodeFixedVersion(pbxproj: out, plist: _marketingPlist), '2.4.4');
  });

  test('Info.plist: a number is replaced, a reference is not', () {
    expect(setPlistVersion(_flutterPlist, '2.4.4', 76), _flutterPlist);
    final fixed = _flutterPlist
        .replaceFirst('\$(FLUTTER_BUILD_NAME)', '2.4.3')
        .replaceFirst('\$(FLUTTER_BUILD_NUMBER)', '75');
    final out = setPlistVersion(fixed, '2.4.4', 76);
    expect(out, contains('<string>2.4.4</string>'));
    expect(out, contains('<string>76</string>'));
  });
}
