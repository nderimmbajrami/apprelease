import 'package:apprelease_runner/src/config.dart';
import 'package:test/test.dart';

void main() {
  final app = {
    'id': 'app-1',
    'name': 'Shop',
    'android_package_name': 'com.acme.shop',
    'ios_bundle_id': 'com.acme.shop',
    'flutter_version': 'stable',
  };
  Map<String, dynamic> cred(String kind, String name, {String? appId}) => {
    'kind': kind,
    'name': name,
    'app_id': appId,
  };

  test('android: the app\'s own keystore wins over a shared one', () {
    final w = WorkflowConfig.defaults(
      platform: 'android',
      track: 'internal',
      app: app,
      credentials: [
        cred('androidKeystore', 'shared_keystore'),
        cred('androidKeystore', 'shop_keystore', appId: 'app-1'),
        cred('androidKeystore', 'other_keystore', appId: 'app-2'),
        cred('googlePlayServiceAccount', 'google_play'),
      ],
    );
    expect(w.androidSigning, ['shop_keystore']);
    expect(w.groups, ['google_play']);
    expect(w.versioningSource, 'google_play');
    expect(w.publishing['google_play'], {
      'track': 'internal',
      'submit_as_draft': false,
    });
    expect(w.scripts.single.script, contains('flutter build appbundle'));
    expect(w.vars['PACKAGE_NAME'], 'com.acme.shop');
  });

  test('android without Play access builds but does not publish', () {
    final w = WorkflowConfig.defaults(
      platform: 'android',
      track: 'production',
      app: app,
      credentials: [cred('androidKeystore', 'k')],
    );
    expect(w.versioningSource, 'manual');
    expect(w.publishing, isEmpty);
  });

  test('ios: TestFlight or App Store from the track', () {
    final w = WorkflowConfig.defaults(
      platform: 'ios',
      track: 'appStore',
      app: app,
      credentials: [cred('appStoreConnectKey', 'asc')],
    );
    expect(w.iosSigning['bundle_identifier'], 'com.acme.shop');
    expect(w.versioningSource, 'app_store_connect');
    expect(w.publishing['app_store_connect'], {
      'submit_to_testflight': false,
      'submit_to_app_store': true,
    });
    expect(w.artifacts, ['build/ios/ipa/*.ipa']);
  });
}
