import 'dart:convert';
import 'dart:io';

import 'package:apprelease_runner/runner.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// The two calls the QA step makes to Supabase, answered from memory.
class _FakeApi extends SupabaseApi {
  _FakeApi(this.rows) : super(url: 'http://supabase.test', serviceRoleKey: 'k');

  final List<Map<String, dynamic>> rows;
  final lines = <String>[];

  @override
  Future<List<Map<String, dynamic>>> credentials(String teamId) async => rows;

  @override
  Future<({String? fileName, List<int>? fileBytes, Map<String, String> fields})>
  readSecret(String credentialId, String secretsKey) async =>
      (fileName: null, fileBytes: null, fields: {'token': 'tok-$credentialId'});

  @override
  Future<void> appendLogs(List<Map<String, dynamic>> rows) async {
    lines.addAll([for (final r in rows) '${r['text']}']);
  }
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('ticketKeys', () {
    test('finds each key once, in order', () {
      expect(
        ticketKeys(
          "Merge branch 'DAMA-123-login' into ready-for-qa\n\n"
          'DAMA-123 login, DAMA-7: logout, APP-41',
        ),
        ['DAMA-123', 'DAMA-7', 'APP-41'],
      );
    });

    test('without projects, lower case and look-alikes inside words are not '
        'keys', () {
      expect(ticketKeys('ready-for-qa fix-12 xDAMA-1 DAMA-12x v1-2'), isEmpty);
    });

    test('with projects, only those count and case does not matter', () {
      expect(
        ticketKeys(
          'feature/dama-123-login UTF-8 APP-9 Dama-4',
          projects: ['DAMA'],
        ),
        ['DAMA-123', 'DAMA-4'],
      );
    });
  });

  test('qaMessage names the build, the commit and links the tickets', () {
    final text = qaMessage(
      appName: 'Shop & Co',
      platform: 'android',
      version: '1.4.0',
      build: '57',
      branch: 'ready-for-qa',
      commit: 'abc1234',
      subject: 'DAMA-123 <login>',
      tickets: const [
        QaTicket(
          'DAMA-123',
          summary: 'Login',
          url: 'https://acme.atlassian.net/browse/DAMA-123',
        ),
        QaTicket('APP-1'),
      ],
    );
    expect(text, contains('*Shop &amp; Co* · Android · *1.4.0 (57)*'));
    expect(text, contains('`ready-for-qa` · commit `abc1234`'));
    expect(text, contains('DAMA-123 &lt;login&gt;'));
    expect(
      text,
      contains('• <https://acme.atlassian.net/browse/DAMA-123|DAMA-123> Login'),
    );
    expect(text, contains('• APP-1'));
  });

  group('JiraClient.moveTo', () {
    JiraClient jira(MockClientHandler handler) => JiraClient(
      site: 'acme.atlassian.net/',
      email: 'qa@acme.test',
      token: 't',
      client: MockClient(handler),
    );

    test('takes the transition that leads to the status', () async {
      String? posted;
      final client = jira((request) async {
        expect(request.url.host, 'acme.atlassian.net');
        expect(
          request.headers['Authorization'],
          'Basic ${base64Encode(utf8.encode('qa@acme.test:t'))}',
        );
        if (request.method == 'POST') {
          posted = request.body;
          return http.Response('', 204);
        }
        if (request.url.path.endsWith('/transitions')) {
          return _json({
            'transitions': [
              {
                'id': '11',
                'name': 'Start',
                'to': {'name': 'In Progress'},
              },
              {
                'id': '31',
                'name': 'Send to QA',
                'to': {'name': 'READY FOR QA'},
              },
            ],
          });
        }
        return _json({
          'fields': {
            'summary': 'Login',
            'status': {'name': 'In Review'},
          },
        });
      });
      expect(await client.moveTo('DAMA-123', 'Ready for QA'), isTrue);
      expect(jsonDecode(posted!), {
        'transition': {'id': '31'},
      });
    });

    test('leaves a ticket that is already there', () async {
      final client = jira((request) async {
        expect(request.method, 'GET');
        return _json({
          'fields': {
            'summary': 'Login',
            'status': {'name': 'Ready for QA'},
          },
        });
      });
      expect(await client.moveTo('DAMA-123', 'ready for qa'), isFalse);
    });

    test('says where the ticket can go when the workflow has no such '
        'step', () async {
      final client = jira((request) async {
        if (request.url.path.endsWith('/transitions')) {
          return _json({
            'transitions': [
              {
                'id': '11',
                'name': 'Start',
                'to': {'name': 'In Progress'},
              },
            ],
          });
        }
        return _json({
          'fields': {
            'summary': 'Login',
            'status': {'name': 'To Do'},
          },
        });
      });
      await expectLater(
        client.moveTo('DAMA-123', 'Ready for QA'),
        throwsA(
          isA<JiraException>().having(
            (e) => e.message,
            'message',
            allOf(contains('"To Do"'), contains('"In Progress"')),
          ),
        ),
      );
    });
  });

  group('SendToQa', () {
    late Directory dir;
    late File apk;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('qa-test-');
      apk = File('${dir.path}/app-release.apk')..writeAsBytesSync([1, 2, 3, 4]);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    final app = {'id': 'app-1', 'name': 'Shop'};
    Map<String, dynamic> release(String platform) => {
      'id': 'r1',
      'team_id': 'team',
      'platform': platform,
      'track': platform == 'android' ? 'qa' : 'qaTestflight',
      'version_name': '1.4.0',
      'branch': 'ready-for-qa',
    };
    final slack = {
      'id': 'slack',
      'kind': 'slack',
      'app_id': null,
      'meta': {'channel': 'C123'},
    };
    final jira = {
      'id': 'jira',
      'kind': 'jira',
      'app_id': null,
      'meta': {
        'site': 'https://acme.atlassian.net',
        'email': 'qa@acme.test',
        'status': 'Ready for QA',
      },
    };

    test('android: uploads the APK to Slack, then moves the tickets that '
        'exist', () async {
      final api = _FakeApi([slack, jira]);
      final calls = <String>[];
      Map<String, dynamic>? completed;
      final client = MockClient((request) async {
        final path = request.url.path;
        calls.add('${request.method} ${request.url.host}$path');
        if (request.url.host == 'slack.com') {
          expect(request.headers['Authorization'], 'Bearer tok-slack');
          if (path.endsWith('files.getUploadURLExternal')) {
            expect(request.bodyFields, {
              'filename': 'shop-1.4.0-57.apk',
              'length': '4',
            });
            return _json({
              'ok': true,
              'upload_url': 'https://files.slack.test/up',
              'file_id': 'F1',
            });
          }
          completed = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'ok': true});
        }
        if (request.url.host == 'files.slack.test') {
          expect(request.bodyBytes, [1, 2, 3, 4]);
          return http.Response('OK - 4', 200);
        }
        // Jira: DAMA-123 exists, UTF-8 does not.
        if (path.contains('UTF-8')) return _json({}, 404);
        if (request.method == 'POST') return http.Response('', 204);
        if (path.endsWith('/transitions')) {
          return _json({
            'transitions': [
              {
                'id': '31',
                'name': 'QA',
                'to': {'name': 'Ready for QA'},
              },
            ],
          });
        }
        return _json({
          'fields': {
            'summary': 'Login',
            'status': {'name': 'In Review'},
          },
        });
      });
      final log = LogSink(api, 'r1');
      await SendToQa(
        api: api,
        log: log,
        stepId: 's',
        secretsKey: 'k',
        client: client,
      ).run(
        release: release('android'),
        app: app,
        env: {'AR_BUILD_NUMBER': '57', 'AR_COMMIT_SHORT': 'abc1234'},
        artifacts: [apk.path],
        commitMessage: 'DAMA-123 login in UTF-8',
      );
      await log.flush();

      expect(completed!['channel_id'], 'C123');
      expect(completed!['files'], [
        {'id': 'F1', 'title': 'shop-1.4.0-57.apk'},
      ]);
      expect(
        completed!['initial_comment'],
        allOf(
          contains('*1.4.0 (57)* is ready for QA'),
          contains('|DAMA-123> Login'),
          isNot(contains('UTF-8>')),
        ),
      );
      // The ticket moves only after Slack has the build.
      final done = calls.indexOf(
        'POST slack.com/api/files.completeUploadExternal',
      );
      final moved = calls.indexOf(
        'POST acme.atlassian.net/rest/api/3/issue/DAMA-123/transitions',
      );
      expect(done, greaterThan(-1));
      expect(moved, greaterThan(done));
      expect(api.lines, contains('DAMA-123 moved to "Ready for QA"'));
      expect(api.lines.join('\n'), isNot(contains('tok-')));
    });

    test('ios: a message, no file; a ticket that cannot move is reported in '
        'Slack and does not fail the build', () async {
      final api = _FakeApi([slack, jira]);
      final messages = <String>[];
      final client = MockClient((request) async {
        if (request.url.host == 'slack.com') {
          expect(request.url.path, endsWith('chat.postMessage'));
          messages.add('${(jsonDecode(request.body) as Map)['text']}');
          return _json({'ok': true});
        }
        if (request.url.path.endsWith('/transitions')) {
          return _json({'transitions': []});
        }
        return _json({
          'fields': {
            'summary': 'Login',
            'status': {'name': 'Done'},
          },
        });
      });
      final log = LogSink(api, 'r1');
      await SendToQa(
        api: api,
        log: log,
        stepId: 's',
        secretsKey: 'k',
        client: client,
      ).run(
        release: release('ios'),
        app: app,
        env: {'AR_BUILD_NUMBER': '12'},
        artifacts: const ['Runner.ipa'],
        commitMessage: 'DAMA-123 login',
      );
      expect(messages, hasLength(2));
      expect(messages.first, contains('iOS · *1.4.0 (12)*'));
      expect(messages.first, contains('TestFlight'));
      expect(messages.last, contains('DAMA-123'));
      expect(messages.last, contains('"Done"'));
    });

    test('android without a Slack connection fails before anything is '
        'sent', () async {
      final api = _FakeApi([jira]);
      final client = MockClient((request) async => fail('${request.url}'));
      await expectLater(
        SendToQa(
          api: api,
          log: LogSink(api, 'r1'),
          stepId: 's',
          secretsKey: 'k',
          client: client,
        ).run(
          release: release('android'),
          app: app,
          env: const {},
          artifacts: [apk.path],
          commitMessage: 'DAMA-123',
        ),
        throwsA(isA<StepFailed>()),
      );
    });

    test('a Slack connection linked to another app is not used', () async {
      final api = _FakeApi([
        {...slack, 'app_id': 'app-2'},
      ]);
      await expectLater(
        SendToQa(
          api: api,
          log: LogSink(api, 'r1'),
          stepId: 's',
          secretsKey: 'k',
          client: MockClient((request) async => fail('${request.url}')),
        ).run(
          release: release('android'),
          app: app,
          env: const {},
          artifacts: [apk.path],
          commitMessage: '',
        ),
        throwsA(isA<StepFailed>()),
      );
    });

    test('Slack errors say what to do', () async {
      final api = _FakeApi([slack]);
      final client = MockClient(
        (request) async => _json({'ok': false, 'error': 'not_in_channel'}),
      );
      await expectLater(
        SendToQa(
          api: api,
          log: LogSink(api, 'r1'),
          stepId: 's',
          secretsKey: 'k',
          client: client,
        ).run(
          release: release('ios'),
          app: app,
          env: const {},
          artifacts: const [],
          commitMessage: '',
        ),
        throwsA(
          isA<SlackException>().having(
            (e) => e.message,
            'message',
            contains('/invite'),
          ),
        ),
      );
    });
  });

  group('workflow for a QA build', () {
    final app = {
      'id': 'app-1',
      'name': 'Shop',
      'android_package_name': 'com.acme.shop',
      'ios_bundle_id': 'com.acme.shop',
    };

    test('android: an APK, signed, and nothing published', () {
      final w = WorkflowConfig.defaults(
        platform: 'android',
        track: 'qa',
        app: app,
        credentials: [
          {'kind': 'androidKeystore', 'name': 'k', 'app_id': null},
          {'kind': 'googlePlayServiceAccount', 'name': 'play', 'app_id': null},
        ],
      );
      expect(w.scripts.single.script, contains('flutter build apk --release'));
      expect(w.artifacts.single, endsWith('*.apk'));
      expect(w.androidSigning, ['k']);
      expect(w.versioningSource, 'google_play');
      expect(w.publishing, isEmpty);
    });

    test('ios: TestFlight, never App Store review', () {
      final w = WorkflowConfig.defaults(
        platform: 'ios',
        track: 'qaTestflight',
        app: app,
        credentials: [
          {'kind': 'appStoreConnectKey', 'name': 'asc', 'app_id': null},
        ],
      );
      expect(w.publishing['app_store_connect'], {
        'submit_to_testflight': true,
        'submit_to_app_store': false,
      });
    });

    const yaml = '''
workflows:
  android-production:
    environment:
      android_signing: [k]
    scripts:
      - name: bundle
        script: flutter build appbundle
  ios-testflight:
    environment:
      ios_signing:
        distribution_type: app_store
''';

    test('apprelease.yaml: android QA takes only android-qa', () {
      expect(
        WorkflowConfig.select(yaml, platform: 'android', track: 'qa'),
        isNull,
      );
      final w = WorkflowConfig.select(
        '$yaml  android-qa:\n    scripts:\n      - name: apk\n'
        '        script: flutter build apk --flavor qa\n',
        platform: 'android',
        track: 'qa',
      );
      expect(w!.id, 'android-qa');
    });

    test('apprelease.yaml: ios QA borrows the TestFlight workflow', () {
      final w = WorkflowConfig.select(
        yaml,
        platform: 'ios',
        track: 'qaTestflight',
      );
      expect(w!.id, 'ios-testflight');
    });
  });
}
