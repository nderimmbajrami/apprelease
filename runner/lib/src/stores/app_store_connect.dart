import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// App Store Connect, spoken to directly: an ES256 token signed with the
/// team's API key, then the App Store Connect API for build numbers,
/// TestFlight groups and App Store submissions.
///
/// The binary itself is uploaded with Apple's own `xcrun altool`, which is
/// part of Xcode; the API has no upload endpoint.
class AppStoreConnectClient {
  AppStoreConnectClient({
    required this.issuerId,
    required this.keyId,
    required this.privateKeyPem,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _api = 'https://api.appstoreconnect.apple.com/v1';

  final String issuerId;
  final String keyId;
  final String privateKeyPem;
  final http.Client _client;
  String? _token;
  DateTime? _tokenExpiry;

  // ------------------------------------------------------------------ auth

  /// A fresh token: issuer id, audience `appstoreconnect-v1`, the key id in
  /// the header, ES256 over the .p8 key. Apple allows at most 20 minutes.
  String token() {
    final cached = _token;
    if (cached != null && _tokenExpiry!.isAfter(DateTime.now())) return cached;
    final jwt = JWT(
      {'iss': issuerId, 'aud': 'appstoreconnect-v1'},
      header: {'kid': keyId, 'typ': 'JWT'},
    );
    _token = jwt.sign(
      ECPrivateKey(privateKeyPem),
      algorithm: JWTAlgorithm.ES256,
      expiresIn: const Duration(minutes: 15),
    );
    _tokenExpiry = DateTime.now().add(const Duration(minutes: 14));
    return _token!;
  }

  // ------------------------------------------------------------------ apps

  Future<String> appId(String bundleId) async {
    final body = await _get('/apps', {
      'filter[bundleId]': bundleId,
      'limit': '1',
    });
    final data = body['data'] as List;
    if (data.isEmpty) {
      throw AppStoreConnectException(
        'apps',
        404,
        'No app with bundle id $bundleId in App Store Connect',
      );
    }
    return (data.first as Map)['id'] as String;
  }

  /// The highest build number uploaded for the app, across TestFlight and
  /// the App Store. 0 when there is none.
  Future<int> latestBuildNumber(String appId) async {
    var highest = 0;
    String? next =
        '$_api/builds?filter[app]=$appId&sort=-uploadedDate&limit=200&fields[builds]=version';
    while (next != null) {
      final body = await _getUrl(next);
      for (final b in (body['data'] as List? ?? const [])) {
        final version = ((b as Map)['attributes'] as Map)['version'] as String?;
        final parsed = int.tryParse(version ?? '') ?? 0;
        if (parsed > highest) highest = parsed;
      }
      next = ((body['links'] as Map?)?['next']) as String?;
    }
    return highest;
  }

  /// Waits until the build with [buildNumber] has been processed. Returns
  /// the build id. Apple usually takes two to ten minutes.
  Future<String> waitForBuild({
    required String appId,
    required String buildNumber,
    Duration timeout = const Duration(minutes: 30),
    Duration every = const Duration(seconds: 30),
    void Function(String line)? onLog,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final body = await _get('/builds', {
        'filter[app]': appId,
        'filter[version]': buildNumber,
        'sort': '-uploadedDate',
        'limit': '1',
        'fields[builds]': 'processingState,version',
      });
      final data = body['data'] as List;
      if (data.isNotEmpty) {
        final build = data.first as Map;
        final state = (build['attributes'] as Map)['processingState'] as String;
        switch (state) {
          case 'VALID':
            return build['id'] as String;
          case 'FAILED':
          case 'INVALID':
            throw AppStoreConnectException(
              'builds',
              422,
              'Apple rejected build $buildNumber ($state)',
            );
          default:
            onLog?.call('Build $buildNumber is $state…');
        }
      } else {
        onLog?.call('Build $buildNumber not visible yet…');
      }
      await Future<void>.delayed(every);
    }
    throw AppStoreConnectException(
      'builds',
      408,
      'Build $buildNumber was not processed within ${timeout.inMinutes} minutes',
    );
  }

  // ------------------------------------------------------------ testflight

  Future<void> setWhatsNew(
    String buildId,
    String text, {
    String locale = 'en-US',
  }) => _post('/betaBuildLocalizations', {
    'data': {
      'type': 'betaBuildLocalizations',
      'attributes': {'whatsNew': text, 'locale': locale},
      'relationships': {
        'build': {
          'data': {'type': 'builds', 'id': buildId},
        },
      },
    },
  });

  /// Adds the build to each named group. An internal group that is set to
  /// receive every build already has it; Apple refuses an explicit
  /// assignment there, so it is reported and skipped.
  Future<void> addToBetaGroups({
    required String appId,
    required String buildId,
    required List<String> groupNames,
    void Function(String line)? onLog,
  }) async {
    for (final name in groupNames) {
      final body = await _get('/betaGroups', {
        'filter[app]': appId,
        'filter[name]': name,
        'limit': '1',
        'fields[betaGroups]': 'name,isInternalGroup,hasAccessToAllBuilds',
      });
      final data = body['data'] as List;
      if (data.isEmpty) {
        throw AppStoreConnectException(
          'betaGroups',
          404,
          'No TestFlight group named "$name"',
        );
      }
      final group = data.first as Map;
      final attributes = (group['attributes'] as Map?) ?? const {};
      final groupId = group['id'] as String;
      if (attributes['isInternalGroup'] == true &&
          attributes['hasAccessToAllBuilds'] == true) {
        onLog?.call(
          'Internal group "$name" receives every build automatically',
        );
        continue;
      }
      try {
        await _post('/betaGroups/$groupId/relationships/builds', {
          'data': [
            {'type': 'builds', 'id': buildId},
          ],
        }, expectBody: false);
        onLog?.call('Added to TestFlight group "$name"');
      } on AppStoreConnectException catch (error) {
        // "Cannot add internal group to a build": it has the build already.
        if (error.status == 422 && error.body.contains('internal group')) {
          onLog?.call('Internal group "$name" already has the build');
          continue;
        }
        rethrow;
      }
    }
  }

  /// Expires every other TestFlight build of the same marketing version.
  Future<void> expireOtherBuilds({
    required String appId,
    required String keepBuildId,
    required String versionName,
  }) async {
    final body = await _get('/builds', {
      'filter[app]': appId,
      'filter[preReleaseVersion.version]': versionName,
      'filter[expired]': 'false',
      'limit': '200',
    });
    for (final b in (body['data'] as List? ?? const [])) {
      final id = (b as Map)['id'] as String;
      if (id == keepBuildId) continue;
      await _patch('/builds/$id', {
        'data': {
          'type': 'builds',
          'id': id,
          'attributes': {'expired': true},
        },
      });
    }
  }

  // ------------------------------------------------------------- app store

  /// Creates (or reuses) the App Store version, attaches the build and
  /// submits it for review.
  Future<void> submitForReview({
    required String appId,
    required String buildId,
    required String versionName,
    String releaseType = 'MANUAL',
    String? copyright,
    void Function(String line)? onLog,
  }) async {
    final existing = await _get('/apps/$appId/appStoreVersions', {
      'filter[versionString]': versionName,
      'filter[platform]': 'IOS',
      'limit': '1',
    });
    String versionId;
    final data = existing['data'] as List;
    if (data.isNotEmpty) {
      versionId = (data.first as Map)['id'] as String;
      onLog?.call('App Store version $versionName exists');
    } else {
      final created = await _post('/appStoreVersions', {
        'data': {
          'type': 'appStoreVersions',
          'attributes': {
            'platform': 'IOS',
            'versionString': versionName,
            'releaseType': releaseType,
            'copyright': ?copyright,
          },
          'relationships': {
            'app': {
              'data': {'type': 'apps', 'id': appId},
            },
          },
        },
      });
      versionId = ((created['data'] as Map)['id']) as String;
      onLog?.call('App Store version $versionName created');
    }

    await _patch('/appStoreVersions/$versionId/relationships/build', {
      'data': {'type': 'builds', 'id': buildId},
    }, expectBody: false);
    onLog?.call('Build attached to version $versionName');

    final submission = await _post('/reviewSubmissions', {
      'data': {
        'type': 'reviewSubmissions',
        'attributes': {'platform': 'IOS'},
        'relationships': {
          'app': {
            'data': {'type': 'apps', 'id': appId},
          },
        },
      },
    });
    final submissionId = ((submission['data'] as Map)['id']) as String;
    await _post('/reviewSubmissionItems', {
      'data': {
        'type': 'reviewSubmissionItems',
        'relationships': {
          'reviewSubmission': {
            'data': {'type': 'reviewSubmissions', 'id': submissionId},
          },
          'appStoreVersion': {
            'data': {'type': 'appStoreVersions', 'id': versionId},
          },
        },
      },
    });
    await _patch('/reviewSubmissions/$submissionId', {
      'data': {
        'type': 'reviewSubmissions',
        'id': submissionId,
        'attributes': {'submitted': true},
      },
    });
    onLog?.call('Submitted for App Store review');
  }

  // ------------------------------------------------------------------ http

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${token()}',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> _get(String path, Map<String, String> query) =>
      _getUrl(
        Uri.parse('$_api$path').replace(queryParameters: query).toString(),
      );

  Future<Map<String, dynamic>> _getUrl(String url) async {
    final response = await _client.get(Uri.parse(url), headers: _headers);
    return _decode('GET $url', response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool expectBody = true,
  }) async {
    final response = await _client.post(
      Uri.parse('$_api$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode('POST $path', response, expectBody: expectBody);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    bool expectBody = true,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_api$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode('PATCH $path', response, expectBody: expectBody);
  }

  Map<String, dynamic> _decode(
    String what,
    http.Response response, {
    bool expectBody = true,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppStoreConnectException(what, response.statusCode, response.body);
    }
    if (!expectBody || response.body.isEmpty) return const {};
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }
}

class AppStoreConnectException implements Exception {
  AppStoreConnectException(this.what, this.status, this.body);

  final String what;
  final int status;
  final String body;

  /// Apple's own detail line, without the JSON around it.
  String get message {
    try {
      final decoded = jsonDecode(body) as Map;
      final errors = decoded['errors'] as List;
      return errors
          .map((e) => '${(e as Map)['title']}: ${e['detail']}')
          .join('; ');
    } catch (_) {
      return body;
    }
  }

  @override
  String toString() => 'App Store Connect $status ($what): $message';
}
