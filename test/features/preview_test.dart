import 'dart:typed_data';

import 'package:apprelease/src/features/apps/domain/app_project.dart';
import 'package:apprelease/src/features/preview/presentation/preview_screen.dart';
import 'package:apprelease/src/features/releases/domain/release.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/pump_app.dart';

/// Hands the page a file without a dialog.
class _FakePicker extends FilePicker {
  _FakePicker(this.file);

  final PlatformFile file;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async => FilePickerResult([file]);
}

void main() {
  test('the app is named after the zip', () {
    expect(appNameFromZip('My_Shop.zip'), 'My Shop');
    expect(appNameFromZip('weather-app (2).ZIP'), 'weather app');
  });

  test('a preview has its own six steps and is not a release destination', () {
    final steps = pipelineSteps(
      Platform.android,
      'r1',
      track: ReleaseTrack.preview,
    );
    expect(steps.map((s) => s.name), [
      'Unpack the project',
      'Set up Flutter',
      'Get packages',
      'Build the Android app',
      'Build the web version',
      'Publish the preview',
    ]);
    expect(
      ReleaseTrack.forPlatform(Platform.android),
      isNot(contains(ReleaseTrack.preview)),
    );
  });

  test('the two links come from the published folder and what is in it', () {
    Release release({String? url, List<String> artifacts = const []}) =>
        Release(
          id: 'r1',
          appId: 'a1',
          teamId: 't1',
          number: 1,
          platform: Platform.android,
          track: ReleaseTrack.preview,
          versionName: '1.0.0',
          branch: 'main',
          startedByName: 'Demo',
          createdAt: DateTime(2026),
          previewUrl: url,
          artifacts: artifacts,
        );

    final both = release(
      url: 'https://p.example.com/r1/',
      artifacts: ['my-shop.apk', 'web'],
    );
    expect(both.previewApkUrl, 'https://p.example.com/r1/my-shop.apk');
    expect(both.previewWebUrl, 'https://p.example.com/r1/web/');

    final androidOnly = release(
      url: 'https://p.example.com/r1/',
      artifacts: ['my-shop.apk'],
    );
    expect(androidOnly.previewWebUrl, isNull);
    expect(release(artifacts: ['my-shop.apk']).previewApkUrl, isNull);
  });

  testWidgets('a zip becomes an app with two QR codes', (tester) async {
    useDesktopSurface(tester);
    await pumpApp(tester);
    await signIn(tester);

    await tester.tap(find.text('On my phone'));
    await tester.pumpAndSettle();
    expect(find.text('See your app on your phone'), findsOneWidget);

    // Nothing chosen yet.
    await tester.tap(find.widgetWithText(FilledButton, 'Build my app'));
    await tester.pumpAndSettle();
    expect(find.text('Choose the zip of your project first.'), findsOneWidget);

    // Too large is said before anything is uploaded.
    FilePicker.platform = _FakePicker(
      PlatformFile(name: 'huge.zip', size: 300 * 1024 * 1024),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose the zip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The zip is 300 MB'), findsOneWidget);

    FilePicker.platform = _FakePicker(
      PlatformFile(
        name: 'My_Shop.zip',
        size: 4,
        bytes: Uint8List.fromList([80, 75, 3, 4]),
      ),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Choose the zip'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'My Shop'), findsOneWidget);
    expect(find.textContaining('The zip is'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Build my app'));
    await pumpFrames(tester, const Duration(seconds: 1));

    // On the build's page, with the preview's own steps.
    expect(find.text('Unpack the project'), findsOneWidget);
    expect(find.text('Build the web version'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await pumpFrames(tester, const Duration(seconds: 3));
    expect(find.text('Your app is ready'), findsOneWidget);
    expect(find.byType(QrImageView), findsNWidgets(2));
    expect(find.text('Android'), findsWidgets);
    expect(find.text('iPhone'), findsOneWidget);

    // The next build of an uploaded app starts with a new zip, not with
    // the store dialog.
    await tester.tap(
      find.widgetWithText(FilledButton, 'Upload a new version'),
    );
    await tester.pumpAndSettle();
    expect(find.text('New version of My Shop'), findsOneWidget);
  });
}
