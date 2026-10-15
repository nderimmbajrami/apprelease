import 'dart:convert';

import 'package:apprelease_runner/runner.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

// Throwaway keys generated for this test; they sign nothing real.
const _ecPrivate = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg7GHy+CzpesdX38KA
/t2meEjkZYCIBtKuZJa/7pLOdgyhRANCAAS5Z5o54xgeWBCTMhBMBFVU/czPcUyI
UV7LiEnQUkebVkFtpkXcJGrQ5mJxkvewOw6ZQoVK07hwKXgNQYowe8Mc
-----END PRIVATE KEY-----
''';
const _ecPublic = '''
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEuWeaOeMYHlgQkzIQTARVVP3Mz3FM
iFFey4hJ0FJHm1ZBbaZF3CRq0OZicZL3sDsOmUKFStO4cCl4DUGKMHvDHA==
-----END PUBLIC KEY-----
''';
const _rsaPrivate = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDTBtJYjHwevVIi
NSRH1sjw3Qkxk/PXJK+zGrwO9quEknqL5ZSPEJB2UdgZR4Mwy6q1gfogKFE//V9a
H7GYZ0FEM0m0pKeTB+IWgG8IIKxkfY48T36nFMZefUFnUkpcF8DfcIUy1SqbakHr
W15XJPxikb5tlwQpygvT4dummol+o6OlcT33RICn1xWpNKYSV2Sk+df99kMUw5Y1
woF0d+yZemH2Fmzn9NovKNE6sJaKFz66yuCoY7cpgLI0bU4ib2Wv9ZPhGbF/kn5f
FbgzuoqDNWRqioubq0/O6cdmWoMre4ig4XY9k3jh4keqquoxkHfCU42BMBDf7323
aDYl/STXAgMBAAECggEAONoFoUV3yvBGSGD4vUHoMLvb1jd94eBIVYBGWeGqo7Sy
vy3CsChOQxIZnfXeKi80dmHl+PPjr9Ga9rTDK8PlmXIX0UrqunnNNzKytwXWa9xH
jYf9HxZBuwMTs7o/vj/H/mpZ+C/loqklyTp8WA3m0Mdi/jNJM9jzBso6WtAXar49
x0ubQpDzwiQO3hVk4VXzZTfBkEp3gVQ8HilTFUqD052EkfAq5Sb+BvgnxiTua4Tz
rDhwFoh6vc1HQXOjXXkpSxf/zP9YgdWzo3L/9WrVAxAPPZ09nFqNsYOe12I1Bwp8
IbfeoU7FwSlKAyiyRBQWJOKHI4ikXIms1ZSn1uwLQQKBgQD3I3tjXZqqMWflTwhZ
mGEQLp6lBeSRHMADizFFDJO0nv6RxW578uh+lj+ZgyliECoJnR81L7fE/Jh9bAlh
aM2bZFVgm8Mn/rRTnZMe1eb+BfG2b+tSMRrWF/k63NcPj8zhfXY2zUac4BgT2GtL
+pELGv1aTF10zViTDBnBHbuH7QKBgQDal9z+eBR2Brv2cJ08BgroipwOxy1OCt3p
ZT1alaDPQzFXkEhoWr+F9wJKaqvouay56aU6Ro3E2LHY7vl84+eFVTwOFIRGcQCn
bvEXrbTGZrAZ4z35XTj8Yaoily+GCH4BUjkEYV/lZ0yIx+K+ZGAhtQOrZ6GpVj4p
M3ZljZf/UwKBgQDlB8XulS2jcfvl37NOTNAPDhVJu8dR0AIGhrVXV0t/RSWIdB5q
0fcycQ1pt8rfLTm4BRuJz7oP3UN4YGnlExoQWxBgYpmedAYrw0k3d2YFnf6eYuQD
HKzRIhB/w2+u5UYq5nlqWhyJf4fwxEzTcdd/IjkOuNyXRUJDrCAl/ubvFQKBgQCz
6ZImj0an7dr+dqmzIXYQ9ySCtUSAm0kSNBVPXR/B9xfBbitqWGaSKD9maG2dWlTj
n34yfKdqgL/AQNBvDlUb1I9dN123bIKRTCp6xqmnMhV2+SWk/ClO8ENLvQuMUakE
BVyQUmTPNzoyyfHBqnPEymt+xAi2ixkWaBjmdKfJqQKBgFlieEKtdNd80nRdwps5
QaSd7Yk2qEqjmFtczrsGPf1hkGKqsgonkjXkjeMDemzp7+MWMjIrAZUQZZinnYSW
yRKyiChAN0f7YHOPqJfEnRLfdYyt5u+DtYhKYz0vFgfMZcFk3QN5oxPEP/32JZN6
YtZOMRquvvP6fTghvjKoJPq9
-----END PRIVATE KEY-----
''';
const _rsaPublic = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0wbSWIx8Hr1SIjUkR9bI
8N0JMZPz1ySvsxq8DvarhJJ6i+WUjxCQdlHYGUeDMMuqtYH6IChRP/1fWh+xmGdB
RDNJtKSnkwfiFoBvCCCsZH2OPE9+pxTGXn1BZ1JKXBfA33CFMtUqm2pB61teVyT8
YpG+bZcEKcoL0+HbppqJfqOjpXE990SAp9cVqTSmEldkpPnX/fZDFMOWNcKBdHfs
mXph9hZs5/TaLyjROrCWihc+usrgqGO3KYCyNG1OIm9lr/WT4Rmxf5J+XxW4M7qK
gzVkaoqLm6tPzunHZlqDK3uIoOF2PZN44eJHqqrqMZB3wlONgTAQ3+99t2g2Jf0k
1wIDAQAB
-----END PUBLIC KEY-----
''';

Map<String, dynamic> _claims(String token) =>
    (jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Map)
        .cast<String, dynamic>();

void main() {
  test(
    'App Store Connect token is ES256 with the key id in the header and a short life',
    () {
      final client = AppStoreConnectClient(
        issuerId: '57246542-96fe-1a63-e053-0824d011072a',
        keyId: '2X9R4HXF34',
        privateKeyPem: _ecPrivate,
      );
      final token = client.token();
      final header =
          (jsonDecode(
                utf8.decode(
                  base64Url.decode(base64Url.normalize(token.split('.')[0])),
                ),
              )
              as Map);
      expect(header['alg'], 'ES256');
      expect(header['kid'], '2X9R4HXF34');
      final claims = _claims(token);
      expect(claims['iss'], '57246542-96fe-1a63-e053-0824d011072a');
      expect(claims['aud'], 'appstoreconnect-v1');
      expect(
        (claims['exp'] as int) - (claims['iat'] as int),
        lessThanOrEqualTo(20 * 60),
      );
      // Verifies against the public half: the signature is real.
      expect(() => JWT.verify(token, ECPublicKey(_ecPublic)), returnsNormally);
      // Cached until it is near expiry.
      expect(client.token(), token);
    },
  );

  test('Google Play assertion is RS256 with the publisher scope', () {
    final client = GooglePlayClient({
      'client_email': 'publisher@project.iam.gserviceaccount.com',
      'private_key': _rsaPrivate,
      'token_uri': 'https://oauth2.googleapis.com/token',
    });
    final assertion = client.assertion();
    final claims = _claims(assertion);
    expect(claims['iss'], 'publisher@project.iam.gserviceaccount.com');
    expect(claims['scope'], 'https://www.googleapis.com/auth/androidpublisher');
    expect(claims['aud'], 'https://oauth2.googleapis.com/token');
    expect(
      () => JWT.verify(assertion, RSAPublicKey(_rsaPublic)),
      returnsNormally,
    );
  });

  test(
    'workflow selection prefers the platform-track id, then the signing section',
    () {
      const yaml =
          r'''
workflows:
  ios-testflight:
    name: iOS
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.example.app
    scripts:
      - name: Build
        script: flutter build ipa
  android-production:
    name: Android
    environment:
      android_signing: [upload_keystore]
      groups: [google_play]
      vars:
        PACKAGE_NAME: com.example.app
    versioning:
      source: google_play
    scripts:
      - name: Build
        script: flutter build appbundle
    publishing:
      google_play:
        credentials: $GOOGLE_PLAY_SERVICE_ACCOUNT
        track: internal
''';
      final android = WorkflowConfig.select(
        yaml,
        platform: 'android',
        track: 'production',
      )!;
      expect(android.id, 'android-production');
      expect(android.androidSigning, ['upload_keystore']);
      expect(android.versioningSource, 'google_play');
      expect(android.vars['PACKAGE_NAME'], 'com.example.app');
      expect(android.publishing['google_play']['track'], 'internal');

      final ios = WorkflowConfig.select(
        yaml,
        platform: 'ios',
        track: 'appStore',
      )!;
      expect(ios.id, 'ios-testflight');
      expect(ios.iosSigning['bundle_identifier'], 'com.example.app');
    },
  );

  test('artifact globs match the Flutter output paths', () {
    final aab = r'build/app/outputs/bundle/release/app-release.aab';
    final ipa = r'build/ios/ipa/Runner.ipa';
    expect(
      globToRegExpForTest('build/**/outputs/**/*.aab').hasMatch(aab),
      isTrue,
    );
    expect(globToRegExpForTest('build/ios/ipa/*.ipa').hasMatch(ipa), isTrue);
    expect(globToRegExpForTest('build/ios/ipa/*.ipa').hasMatch(aab), isFalse);
  });
}
