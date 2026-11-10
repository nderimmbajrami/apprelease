import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../api.dart';
import '../config.dart';
import '../pipeline.dart';

/// Tracks that build for the testers instead of a store: `qa` is an Android
/// APK posted to Slack, `qaTestflight` an iOS build on TestFlight with a
/// note in Slack.
bool isQaTrack(Object? track) => track == 'qa' || track == 'qaTestflight';

/// The last step of a QA build: tell the testers in Slack (with the APK on
/// Android), then move the Jira tickets the last commit names to the
/// "Ready for QA" status.
///
/// Slack comes first: a ticket only moves once the build it promises has
/// reached the channel.
class SendToQa {
  SendToQa({
    required this.api,
    required this.log,
    required this.stepId,
    required this.secretsKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final SupabaseApi api;
  final LogSink log;
  final String stepId;
  final String secretsKey;
  final http.Client _client;

  Future<void> run({
    required Map<String, dynamic> release,
    required Map<String, dynamic> app,
    required Map<String, String> env,
    required List<String> artifacts,
    required String commitMessage,
  }) async {
    final platform = release['platform'] as String;
    final all = await api.credentials(release['team_id'] as String);
    final slackRow = credentialFor(all, 'slack', app['id']);
    final jiraRow = credentialFor(all, 'jira', app['id']);

    final apks = [
      for (final a in artifacts)
        if (a.endsWith('.apk')) a,
    ];
    if (platform == 'android') {
      // Checked before anything is sent: without these the build reaches
      // nobody, and saying so beats a green release QA never saw.
      if (apks.isEmpty) throw StepFailed('No .apk among the artifacts');
      if (slackRow == null) {
        throw StepFailed(
          'The APK has nowhere to go: add a Slack connection under '
          'Credentials (bot token and channel) and run the build again.',
        );
      }
    }

    // ------------------------------------------------------------- tickets
    JiraClient? jira;
    var status = 'Ready for QA';
    var projects = const <String>[];
    if (jiraRow != null) {
      final meta = (jiraRow['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      final secret = await api.readSecret(jiraRow['id'] as String, secretsKey);
      final token = secret.fields['token'] ?? '';
      log.mask(token);
      jira = JiraClient(
        site: '${meta['site'] ?? ''}',
        email: '${meta['email'] ?? ''}',
        token: token,
        client: _client,
      );
      final wanted = '${meta['status'] ?? ''}'.trim();
      if (wanted.isNotEmpty) status = wanted;
      projects = [
        for (final key in '${meta['projects'] ?? ''}'.split(RegExp(r'[,\s]+')))
          if (key.isNotEmpty) key.toUpperCase(),
      ];
    }

    final keys = ticketKeys(
      '${release['branch']}\n$commitMessage',
      projects: projects,
    );
    await log(
      keys.isEmpty
          ? 'No ticket keys (like DAMA-123) in the last commit message'
          : 'Tickets in the last commit: ${keys.join(', ')}',
      stepId: stepId,
    );

    // With Jira connected, only keys that are real tickets are shown: a
    // commit that mentions UTF-8 does not put "UTF-8" in front of QA.
    final tickets = <QaTicket>[];
    for (final key in keys) {
      if (jira == null) {
        tickets.add(QaTicket(key));
        continue;
      }
      try {
        final issue = await jira.issue(key);
        if (issue == null) {
          await log('$key is not a ticket in Jira; left out', stepId: stepId);
          continue;
        }
        tickets.add(
          QaTicket(
            key,
            summary: issue.summary,
            status: issue.status,
            url: jira.browseUrl(key),
          ),
        );
      } on Object catch (error) {
        await log(
          'Could not read $key from Jira: $error',
          stepId: stepId,
          level: 'warning',
        );
        tickets.add(QaTicket(key, url: jira.browseUrl(key)));
      }
    }

    // --------------------------------------------------------------- slack
    SlackClient? slack;
    var channel = '';
    if (slackRow == null) {
      await log(
        'No Slack connection under Credentials: the build is on TestFlight, '
        'but nobody was told',
        stepId: stepId,
        level: 'warning',
      );
    } else {
      final meta = (slackRow['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      final secret = await api.readSecret(slackRow['id'] as String, secretsKey);
      final token = secret.fields['token'] ?? '';
      log.mask(token);
      slack = SlackClient(token: token, client: _client);
      channel = '${meta['channel'] ?? ''}'.trim();
      final text = qaMessage(
        appName: '${app['name']}',
        platform: platform,
        version: '${release['version_name']}',
        build: env['AR_BUILD_NUMBER'] ?? '${release['build_number'] ?? ''}',
        branch: '${release['branch']}',
        commit: env['AR_COMMIT_SHORT'] ?? '${release['commit'] ?? ''}',
        subject: commitMessage.trim().split('\n').first,
        tickets: tickets,
      );
      if (platform == 'android') {
        final base = [
          _slug('${app['name']}'),
          release['version_name'],
          env['AR_BUILD_NUMBER'],
        ].where((part) => part != null && '$part'.isNotEmpty).join('-');
        final files = [
          for (final apk in apks)
            (
              file: File(apk),
              // One APK is named after the app; several keep their own
              // name (the flavor or the ABI is in it).
              name: apks.length == 1
                  ? '$base.apk'
                  : '$base-${p.basenameWithoutExtension(apk)}.apk',
            ),
        ];
        for (final f in files) {
          await log(
            'Uploading ${f.name} to Slack '
            '(${(f.file.lengthSync() / 1048576).toStringAsFixed(1)} MB)',
            stepId: stepId,
          );
        }
        await slack.sendFiles(channel: channel, text: text, files: files);
        await log('APK posted to Slack channel $channel', stepId: stepId);
      } else {
        await slack.post(channel: channel, text: text);
        await log('QA told in Slack channel $channel', stepId: stepId);
      }
    }

    // ---------------------------------------------------------------- jira
    if (jira == null) {
      if (keys.isNotEmpty) {
        await log(
          'No Jira connection under Credentials: tickets stay where they are',
          stepId: stepId,
        );
      }
      return;
    }
    final problems = <String>[];
    for (final ticket in tickets) {
      try {
        final moved = await jira.moveTo(ticket.key, status);
        await log(
          moved
              ? '${ticket.key} moved to "$status"'
              : '${ticket.key} is already "$status"',
          stepId: stepId,
        );
      } on Object catch (error) {
        problems.add('${ticket.key}: $error');
        await log(
          'Could not move ${ticket.key}: $error',
          stepId: stepId,
          level: 'warning',
        );
      }
    }
    // The build went out, so the release stands; QA still has to know
    // which tickets to move by hand.
    if (problems.isNotEmpty && slack != null) {
      try {
        await slack.post(
          channel: channel,
          text:
              ':warning: Could not move to "${slackEscape(status)}" in Jira:\n'
              '${problems.map((line) => '• ${slackEscape(line)}').join('\n')}',
        );
      } on Object catch (error) {
        await log(
          'Could not report that in Slack: $error',
          stepId: stepId,
          level: 'warning',
        );
      }
    }
  }

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// A ticket the commit named, with what Jira knows about it.
class QaTicket {
  const QaTicket(this.key, {this.summary, this.status, this.url});

  final String key;
  final String? summary;
  final String? status;
  final String? url;
}

/// Jira keys (`DAMA-123`) in [text], each once, in the order they appear.
///
/// With [projects] only those projects count, and `dama-123` in a branch
/// name counts too. Without, any upper-case `KEY-123` is a candidate.
List<String> ticketKeys(String text, {List<String> projects = const []}) {
  final wanted = {for (final key in projects) key.toUpperCase()};
  final pattern = RegExp(
    r'(?<![A-Za-z0-9])([A-Za-z][A-Za-z0-9]{1,9})-([1-9][0-9]{0,6})(?![A-Za-z0-9])',
  );
  final found = <String>[];
  for (final match in pattern.allMatches(text)) {
    final project = match[1]!;
    if (wanted.isEmpty) {
      if (project != project.toUpperCase()) continue;
    } else if (!wanted.contains(project.toUpperCase())) {
      continue;
    }
    final key = '${project.toUpperCase()}-${match[2]}';
    if (!found.contains(key)) found.add(key);
  }
  return found;
}

/// The Slack message for a QA build, in Slack's mrkdwn.
String qaMessage({
  required String appName,
  required String platform,
  required String version,
  required String build,
  required String branch,
  required String commit,
  required String subject,
  required List<QaTicket> tickets,
}) {
  final android = platform == 'android';
  final label = build.isEmpty ? version : '$version ($build)';
  final out = StringBuffer()
    ..writeln(
      '*${slackEscape(appName)}* · ${android ? 'Android' : 'iOS'} · '
      '*${slackEscape(label)}* is ready for QA',
    )
    ..writeln(
      android
          ? 'Install the APK attached to this message.'
          : 'On TestFlight: open the TestFlight app and update.',
    )
    ..write('Branch `${slackEscape(branch)}`');
  if (commit.isNotEmpty) out.write(' · commit `${slackEscape(commit)}`');
  if (subject.isNotEmpty) out.write(' · ${slackEscape(subject)}');
  out.writeln();
  if (tickets.isNotEmpty) {
    out.writeln('Tickets:');
    for (final t in tickets) {
      final key = t.url == null ? t.key : '<${t.url}|${t.key}>';
      final summary = t.summary == null || t.summary!.isEmpty
          ? ''
          : ' ${slackEscape(t.summary!)}';
      out.writeln('• $key$summary');
    }
  }
  return out.toString().trimRight();
}

/// The three characters Slack reads as markup.
String slackEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

// ------------------------------------------------------------------- slack

/// The Slack Web API with a bot token: a message, or files with a message.
/// The bot needs the scopes `chat:write` and `files:write`, and has to be
/// a member of the channel.
class SlackClient {
  SlackClient({required this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String token;
  final http.Client _client;

  static const _api = 'https://slack.com/api';

  Future<void> post({required String channel, required String text}) => _call(
    'chat.postMessage',
    json: {
      'channel': channel,
      'text': text,
      'unfurl_links': false,
      'unfurl_media': false,
    },
  );

  /// Uploads [files] and shares them in [channel] as one message with
  /// [text]. Slack's upload is three calls: ask for an upload URL, send the
  /// bytes there, then complete the upload into the channel.
  Future<void> sendFiles({
    required String channel,
    required String text,
    required List<({File file, String name})> files,
  }) async {
    final uploaded = <Map<String, String>>[];
    for (final f in files) {
      final bytes = await f.file.readAsBytes();
      final ticket = await _call(
        'files.getUploadURLExternal',
        form: {'filename': f.name, 'length': '${bytes.length}'},
      );
      final response = await _client.post(
        Uri.parse(ticket['upload_url'] as String),
        headers: {'Content-Type': 'application/octet-stream'},
        body: bytes,
      );
      if (response.statusCode >= 300) {
        throw SlackException(
          'upload',
          'Slack refused the file (${response.statusCode})',
        );
      }
      uploaded.add({'id': ticket['file_id'] as String, 'title': f.name});
    }
    await _call(
      'files.completeUploadExternal',
      json: {'files': uploaded, 'channel_id': channel, 'initial_comment': text},
    );
  }

  Future<Map<String, dynamic>> _call(
    String method, {
    Map<String, Object?>? json,
    Map<String, String>? form,
  }) async {
    final response = await _client.post(
      Uri.parse('$_api/$method'),
      headers: {
        'Authorization': 'Bearer $token',
        if (json != null) 'Content-Type': 'application/json; charset=utf-8',
      },
      body: json != null ? jsonEncode(json) : form,
    );
    final Map<String, dynamic> body;
    try {
      body = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)
          .cast<String, dynamic>();
    } on Object {
      throw SlackException(method, 'Slack answered ${response.statusCode}');
    }
    if (body['ok'] != true) {
      throw SlackException(method, slackError('${body['error']}'));
    }
    return body;
  }
}

/// Slack's error code as what to do about it.
String slackError(String code) => switch (code) {
  'not_in_channel' =>
    'The Slack bot is not in the channel. In the channel, type /invite '
        '@<the bot name>.',
  'channel_not_found' =>
    'Slack has no such channel for this bot. Use the channel ID (starts '
        'with C, under the channel details), and invite the bot to it.',
  'invalid_auth' || 'not_authed' || 'token_revoked' || 'account_inactive' =>
    'Slack refused the bot token. Add the Slack connection again with the '
        'Bot User OAuth Token (xoxb-…).',
  'missing_scope' =>
    'The Slack bot lacks a permission. Give it the scopes chat:write and '
        'files:write, then reinstall it to the workspace.',
  'invalid_arguments' || 'invalid_channel' =>
    'Slack did not accept the channel. Use the channel ID (starts with C).',
  _ => 'Slack: $code',
};

class SlackException implements Exception {
  SlackException(this.method, this.message);

  final String method;
  final String message;

  @override
  String toString() => message;
}

// -------------------------------------------------------------------- jira

/// Jira Cloud's REST API with an account email and an API token.
class JiraClient {
  JiraClient({
    required String site,
    required this.email,
    required this.token,
    http.Client? client,
  }) : site = normaliseSite(site),
       _client = client ?? http.Client();

  /// `https://acme.atlassian.net`, without a trailing slash.
  final String site;
  final String email;
  final String token;
  final http.Client _client;

  /// `acme.atlassian.net/` → `https://acme.atlassian.net`.
  static String normaliseSite(String site) {
    var value = site.trim();
    if (value.isEmpty) return value;
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.parse(value);
    return '${uri.scheme}://${uri.authority}';
  }

  Map<String, String> get _headers => {
    'Authorization': 'Basic ${base64Encode(utf8.encode('$email:$token'))}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  String browseUrl(String key) => '$site/browse/$key';

  /// The ticket's title and status, or null when Jira has no such ticket
  /// (or this account may not see it: Jira answers 404 for both).
  Future<({String summary, String status})?> issue(String key) async {
    final response = await _client.get(
      Uri.parse('$site/rest/api/3/issue/$key?fields=summary,status'),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    _check(response);
    final fields =
        ((jsonDecode(utf8.decode(response.bodyBytes)) as Map)['fields']
            as Map?) ??
        const {};
    return (
      summary: '${fields['summary'] ?? ''}',
      status: '${(fields['status'] as Map?)?['name'] ?? ''}',
    );
  }

  /// Moves [key] to [status] through whichever transition leads there.
  /// Returns false when the ticket is already in that status. Throws
  /// [JiraException] when the workflow has no such transition from where
  /// the ticket is.
  Future<bool> moveTo(String key, String status) async {
    final current = await issue(key);
    if (current == null) throw JiraException('not found in Jira');
    if (_same(current.status, status)) return false;

    final response = await _client.get(
      Uri.parse('$site/rest/api/3/issue/$key/transitions'),
      headers: _headers,
    );
    _check(response);
    final transitions = [
      for (final t
          in ((jsonDecode(utf8.decode(response.bodyBytes))
                      as Map)['transitions']
                  as List?) ??
              const [])
        (t as Map).cast<String, dynamic>(),
    ];
    // The status a transition leads to is what was asked for; its own name
    // ("Send to QA") is the second guess.
    final match =
        transitions
            .where((t) => _same('${(t['to'] as Map?)?['name']}', status))
            .firstOrNull ??
        transitions.where((t) => _same('${t['name']}', status)).firstOrNull;
    if (match == null) {
      final open = [
        for (final t in transitions) '"${(t['to'] as Map?)?['name']}"',
      ].join(', ');
      throw JiraException(
        'the workflow has no step from "${current.status}" to "$status"'
        '${open.isEmpty ? '' : ' (from here it can go to $open)'}',
      );
    }
    final moved = await _client.post(
      Uri.parse('$site/rest/api/3/issue/$key/transitions'),
      headers: _headers,
      body: jsonEncode({
        'transition': {'id': '${match['id']}'},
      }),
    );
    _check(moved);
    return true;
  }

  static bool _same(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  void _check(http.Response response) {
    if (response.statusCode < 300) return;
    throw JiraException(switch (response.statusCode) {
      401 =>
        'Jira refused the email and API token. Add the Jira connection '
            'again with a fresh token.',
      403 => 'this Jira account may not do that (403)',
      _ => 'Jira answered ${response.statusCode}: ${_message(response)}',
    });
  }

  static String _message(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      final messages = [
        for (final m in (body['errorMessages'] as List?) ?? const []) '$m',
        for (final m in ((body['errors'] as Map?) ?? const {}).values) '$m',
      ];
      if (messages.isNotEmpty) return messages.join('; ');
    } on Object {
      // Not JSON: the raw body, shortened, is all there is.
    }
    final text = response.body.trim();
    return text.length > 200 ? '${text.substring(0, 200)}…' : text;
  }
}

class JiraException implements Exception {
  JiraException(this.message);

  final String message;

  @override
  String toString() => message;
}
