import '../stores/app_store_connect.dart';

/// Flutter hands the version from pubspec.yaml to Xcode as
/// `$(FLUTTER_BUILD_NAME)`. A project where someone typed the version into
/// Xcode instead (General → Identity → Version) has a number fixed in
/// `project.pbxproj` or `Info.plist`, and the build ignores pubspec.yaml:
/// the ipa keeps the old version whatever the release says. These read
/// and rewrite that fixed number in the checkout.

final _number = RegExp(r'^\d+(?:\.\d+)*$');

RegExp _plistKey(String key) =>
    RegExp('(<key>$key</key>\\s*<string>)([^<]*)(</string>)');

RegExp _setting(String name) => RegExp('($name = )"?([^;"]*)"?;');

/// The version fixed in the Xcode project, or null when the project takes
/// it from pubspec.yaml as Flutter set it up.
String? xcodeFixedVersion({String? pbxproj, String? plist}) {
  final inPlist = plist == null
      ? null
      : _plistKey('CFBundleShortVersionString').firstMatch(plist)?.group(2);
  if (inPlist != null && _number.hasMatch(inPlist.trim())) {
    return inPlist.trim();
  }
  // Info.plist points elsewhere. Only MARKETING_VERSION is a place where a
  // number can be fixed; $(FLUTTER_BUILD_NAME) is pubspec.yaml.
  if (inPlist != null && !inPlist.contains('MARKETING_VERSION')) return null;
  String? highest;
  for (final m in _setting('MARKETING_VERSION').allMatches(pbxproj ?? '')) {
    final value = m.group(2)!.trim();
    if (!_number.hasMatch(value)) continue;
    if (highest == null || compareVersions(value, highest) > 0) highest = value;
  }
  return highest;
}

/// [pbxproj] with every fixed version and build number replaced. Settings
/// that refer to Flutter's own values are left as they are.
String setPbxprojVersion(String pbxproj, String version, int build) {
  String replace(String text, String name, String value) =>
      text.replaceAllMapped(
        _setting(name),
        (m) => _number.hasMatch(m.group(2)!.trim())
            ? '${m.group(1)}$value;'
            : m.group(0)!,
      );
  return replace(
    replace(pbxproj, 'MARKETING_VERSION', version),
    'CURRENT_PROJECT_VERSION',
    '$build',
  );
}

/// [plist] with a fixed version and build number replaced; references such
/// as `$(FLUTTER_BUILD_NAME)` are left as they are.
String setPlistVersion(String plist, String version, int build) {
  String replace(String text, String key, String value) =>
      text.replaceFirstMapped(
        _plistKey(key),
        (m) => _number.hasMatch(m.group(2)!.trim())
            ? '${m.group(1)}$value${m.group(3)}'
            : m.group(0)!,
      );
  return replace(
    replace(plist, 'CFBundleShortVersionString', version),
    'CFBundleVersion',
    '$build',
  );
}
