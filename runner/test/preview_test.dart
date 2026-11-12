import 'dart:io';

import 'package:apprelease_runner/runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../bin/serve_previews.dart' as server;

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('preview_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void pubspec(String folder) => File(p.join(tmp.path, folder, 'pubspec.yaml'))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('name: my_app\n');

  group('findProjectRoot', () {
    test('the zip held the project files themselves', () {
      pubspec('');
      expect(findProjectRoot(tmp)!.path, tmp.path);
    });

    test('the zip held the project folder', () {
      pubspec('My App');
      Directory(
        p.join(tmp.path, '__MACOSX', 'My App'),
      ).createSync(recursive: true);
      expect(findProjectRoot(tmp)!.path, p.join(tmp.path, 'My App'));
    });

    test('the shallowest pubspec wins over a package inside', () {
      pubspec('app');
      pubspec('app/packages/ui');
      expect(findProjectRoot(tmp)!.path, p.join(tmp.path, 'app'));
    });

    test('no pubspec, no project', () {
      Directory(p.join(tmp.path, 'photos')).createSync();
      expect(findProjectRoot(tmp), isNull);
    });
  });

  test('pubspecName reads a valid package name', () {
    expect(pubspecName('name: my_app\nversion: 1.0.0'), 'my_app');
    expect(pubspecName('version: 1.0.0'), isNull);
  });

  test('previewSlug is safe in a link', () {
    expect(previewSlug('My Shop!'), 'my-shop');
    expect(previewSlug('Çka ka'), 'ka-ka');
    expect(previewSlug('!!!'), 'app');
  });

  group('releaseSigningMissing', () {
    void gradle(String text) =>
        File(p.join(tmp.path, 'android', 'app', 'build.gradle.kts'))
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(text);

    test('a fresh project signs with the debug key', () {
      gradle('signingConfig = signingConfigs.getByName("debug")');
      expect(releaseSigningMissing(tmp), isFalse);
    });

    test('key.properties named but not uploaded', () {
      gradle('rootProject.file("key.properties")');
      expect(releaseSigningMissing(tmp), isTrue);
    });

    test('key.properties named and there', () {
      gradle('rootProject.file("key.properties")');
      File(p.join(tmp.path, 'android', 'key.properties')).writeAsStringSync('');
      expect(releaseSigningMissing(tmp), isFalse);
    });
  });

  group('PreviewSettings', () {
    test('missing settings mean no previews on this machine', () {
      expect(PreviewSettings.fromEnv(const {}), isNull);
      expect(
        PreviewSettings.fromEnv(const {'PREVIEW_DIR': 'previews'}),
        isNull,
      );
      expect(
        PreviewSettings.fromEnv(const {
          'PREVIEW_DIR': 'previews',
          'PREVIEW_BASE_URL': 'not a url',
        }),
        isNull,
      );
    });

    test('the address of a release ends with a slash', () {
      final plain = PreviewSettings.fromEnv(const {
        'PREVIEW_DIR': 'previews',
        'PREVIEW_BASE_URL': 'https://preview.example.com',
      })!;
      expect('${plain.urlFor('abc')}', 'https://preview.example.com/abc/');
      final nested = PreviewSettings.fromEnv(const {
        'PREVIEW_DIR': 'previews',
        'PREVIEW_BASE_URL': 'https://example.com/p',
        'PREVIEW_KEEP_DAYS': '3',
      })!;
      expect('${nested.urlFor('abc')}', 'https://example.com/p/abc/');
      expect(nested.urlFor('abc').path, '/p/abc/');
      expect(nested.keepDays, 3);
    });
  });

  group('preview server', () {
    test('a path stays inside the folder', () {
      expect(
        server.resolve('/srv/p', '/abc/web/main.dart.js'),
        '/srv/p/abc/web/main.dart.js',
      );
      expect(server.resolve('/srv/p', '/../etc/passwd'), isNull);
      expect(server.resolve('/srv/p', '/abc/%2e%2e/%2e%2e/etc/passwd'), isNull);
      expect(server.resolve('/srv/p', '/%'), isNull);
    });

    test('an APK downloads as an Android app', () {
      expect(
        server.contentType('a/my-shop.apk'),
        'application/vnd.android.package-archive',
      );
      expect(server.contentType('web/index.html'), startsWith('text/html'));
      expect(server.contentType('web/main.dart.wasm'), 'application/wasm');
    });
  });
}
