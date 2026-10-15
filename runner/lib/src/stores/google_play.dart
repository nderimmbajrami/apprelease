import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// Google Play, spoken to directly: a service-account JWT exchanged for an
/// OAuth token, then the Android Publisher API v3 (edits → bundles → tracks
/// → commit). Nothing but this file and the service account JSON.
class GooglePlayClient {
  GooglePlayClient(this.serviceAccountJson, {http.Client? client})
    : _client = client ?? http.Client();

  static const _scope = 'https://www.googleapis.com/auth/androidpublisher';
  static const _api =
      'https://androidpublisher.googleapis.com/androidpublisher/v3';
  static const _upload =
      'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';

  final Map<String, dynamic> serviceAccountJson;
  final http.Client _client;
  String? _token;
  DateTime? _tokenExpiry;

  String get clientEmail => serviceAccountJson['client_email'] as String;

  // ------------------------------------------------------------------ auth

  /// The JWT Google wants in exchange for an access token: the service
  /// account's email as issuer, the scope, the token endpoint as audience,
  /// signed RS256 with the account's private key.
  String assertion({DateTime? now}) {
    final jwt = JWT({
      'iss': clientEmail,
      'scope': _scope,
      'aud': serviceAccountJson['token_uri'] as String,
    });
    return jwt.sign(
      RSAPrivateKey(serviceAccountJson['private_key'] as String),
      algorithm: JWTAlgorithm.RS256,
      expiresIn: const Duration(minutes: 55),
    );
  }

  Future<String> accessToken() async {
    final cached = _token;
    if (cached != null && _tokenExpiry!.isAfter(DateTime.now())) return cached;
    final response = await _client.post(
      Uri.parse(serviceAccountJson['token_uri'] as String),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion(),
      },
    );
    if (response.statusCode != 200) {
      throw GooglePlayException(
        'token exchange',
        response.statusCode,
        response.body,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    _token = body['access_token'] as String;
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: ((body['expires_in'] as num?) ?? 3600).toInt() - 60),
    );
    return _token!;
  }

  // ----------------------------------------------------------------- edits

  Future<String> _createEdit(String package) async {
    final body = await _json('POST', '$_api/applications/$package/edits');
    return body['id'] as String;
  }

  Future<void> _deleteEdit(String package, String editId) => _json(
    'DELETE',
    '$_api/applications/$package/edits/$editId',
    expectBody: false,
  );

  /// The highest version code Google Play knows for the app, across every
  /// track and every bundle ever uploaded. 0 when there is none.
  Future<int> latestBuildNumber(String package) async {
    final edit = await _createEdit(package);
    try {
      var highest = 0;
      final bundles = await _json(
        'GET',
        '$_api/applications/$package/edits/$edit/bundles',
      );
      for (final b in (bundles['bundles'] as List?) ?? const []) {
        highest = _max(highest, (b as Map)['versionCode']);
      }
      final tracks = await _json(
        'GET',
        '$_api/applications/$package/edits/$edit/tracks',
      );
      for (final t in (tracks['tracks'] as List?) ?? const []) {
        for (final r in ((t as Map)['releases'] as List?) ?? const []) {
          for (final code
              in ((r as Map)['versionCodes'] as List?) ?? const []) {
            highest = _max(highest, code);
          }
        }
      }
      return highest;
    } finally {
      await _deleteEdit(package, edit);
    }
  }

  /// Uploads [bundle] and puts it on [track]. Returns the version code Google
  /// read from the bundle.
  Future<int> publishBundle({
    required String package,
    required File bundle,
    required String track,
    bool draft = false,
    double? rolloutFraction,
    int? inAppUpdatePriority,
    bool changesNotSentForReview = false,
    Map<String, String> releaseNotes = const {},
    String? releaseName,
    void Function(String line)? onLog,
  }) async {
    final edit = await _createEdit(package);
    try {
      onLog?.call('Edit $edit opened');
      final uploaded = await _json(
        'POST',
        '$_upload/applications/$package/edits/$edit/bundles?uploadType=media',
        bytes: await bundle.readAsBytes(),
        contentType: 'application/octet-stream',
      );
      final versionCode = (uploaded['versionCode'] as num).toInt();
      onLog?.call('Bundle accepted · version code $versionCode');

      final status = draft
          ? 'draft'
          : rolloutFraction != null
          ? 'inProgress'
          : 'completed';
      await _json(
        'PUT',
        '$_api/applications/$package/edits/$edit/tracks/$track',
        json: {
          'track': track,
          'releases': [
            {
              'name': ?releaseName,
              'versionCodes': ['$versionCode'],
              'status': status,
              'userFraction': ?rolloutFraction,
              'inAppUpdatePriority': ?inAppUpdatePriority,
              if (releaseNotes.isNotEmpty)
                'releaseNotes': [
                  for (final e in releaseNotes.entries)
                    {'language': e.key, 'text': e.value},
                ],
            },
          ],
        },
      );
      onLog?.call('Track $track set to $status');

      await _json(
        'POST',
        '$_api/applications/$package/edits/$edit:commit'
            '${changesNotSentForReview ? '?changesNotSentForReview=true' : ''}',
      );
      onLog?.call('Edit committed');
      return versionCode;
    } catch (_) {
      try {
        await _deleteEdit(package, edit);
      } catch (_) {}
      rethrow;
    }
  }

  // ------------------------------------------------------------------ http

  Future<Map<String, dynamic>> _json(
    String method,
    String url, {
    Map<String, dynamic>? json,
    List<int>? bytes,
    String? contentType,
    bool expectBody = true,
  }) async {
    final request = http.Request(method, Uri.parse(url))
      ..headers['Authorization'] = 'Bearer ${await accessToken()}';
    if (json != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(json);
    } else if (bytes != null) {
      request.headers['Content-Type'] =
          contentType ?? 'application/octet-stream';
      request.bodyBytes = bytes;
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GooglePlayException(
        '$method $url',
        response.statusCode,
        response.body,
      );
    }
    if (!expectBody || response.body.isEmpty) return const {};
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  static int _max(int a, Object? b) {
    final parsed = b is num ? b.toInt() : int.tryParse('$b') ?? 0;
    return parsed > a ? parsed : a;
  }
}

class GooglePlayException implements Exception {
  GooglePlayException(this.what, this.status, this.body);

  final String what;
  final int status;
  final String body;

  /// Google's own message, without the JSON around it.
  String get message {
    try {
      final decoded = jsonDecode(body) as Map;
      return (decoded['error'] as Map)['message'] as String;
    } catch (_) {
      return body;
    }
  }

  @override
  String toString() => 'Google Play $status ($what): $message';
}
