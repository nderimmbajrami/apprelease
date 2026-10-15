import 'dart:convert';

import 'package:http/http.dart' as http;

/// The slice of Supabase the runner needs, over plain REST with the service
/// role key. No client library: the runner is a long-lived process and the
/// REST surface is four calls.
class SupabaseApi {
  SupabaseApi({required this.url, required this.serviceRoleKey});

  final String url;
  final String serviceRoleKey;
  final _client = http.Client();

  Map<String, String> get _headers => {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
  };

  /// Atomically claims the oldest queued release this machine can build.
  Future<Map<String, dynamic>?> claimRelease({
    required String runnerId,
    required List<String> platforms,
  }) async {
    final response = await _client.post(
      Uri.parse('$url/rest/v1/rpc/claim_release'),
      headers: _headers,
      body: jsonEncode({'p_runner': runnerId, 'p_platforms': platforms}),
    );
    _check(response);
    final body = jsonDecode(response.body);
    if (body == null || (body is Map && body['id'] == null)) return null;
    return (body as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> app(String appId) async {
    final response = await _client.get(
      Uri.parse('$url/rest/v1/apps?id=eq.$appId&select=*'),
      headers: _headers,
    );
    _check(response);
    return ((jsonDecode(response.body) as List).first as Map)
        .cast<String, dynamic>();
  }

  Future<List<Map<String, dynamic>>> credentials(String teamId) async {
    final response = await _client.get(
      Uri.parse('$url/rest/v1/credentials?team_id=eq.$teamId&select=*'),
      headers: _headers,
    );
    _check(response);
    return [
      for (final row in jsonDecode(response.body) as List)
        (row as Map).cast<String, dynamic>(),
    ];
  }

  /// Decrypts one credential's secret with [secretsKey].
  Future<({String? fileName, List<int>? fileBytes, Map<String, String> fields})>
  readSecret(String credentialId, String secretsKey) async {
    final response = await _client.post(
      Uri.parse('$url/rest/v1/rpc/read_credential_secret'),
      headers: _headers,
      body: jsonEncode({'p_credential_id': credentialId, 'p_key': secretsKey}),
    );
    _check(response);
    final row = ((jsonDecode(response.body) as List).first as Map)
        .cast<String, dynamic>();
    final hex = row['file_bytes'] as String?;
    return (
      fileName: row['file_name'] as String?,
      // PostgREST returns bytea as \x-prefixed hex.
      fileBytes: hex == null ? null : _unhex(hex),
      fields: (jsonDecode(row['fields_json'] as String) as Map)
          .cast<String, String>(),
    );
  }

  Future<void> updateRelease(String id, Map<String, dynamic> patch) async {
    final response = await _client.patch(
      Uri.parse('$url/rest/v1/releases?id=eq.$id'),
      headers: {..._headers, 'Prefer': 'return=minimal'},
      body: jsonEncode(patch),
    );
    _check(response);
  }

  Future<bool> cancelRequested(String id) async {
    final response = await _client.get(
      Uri.parse('$url/rest/v1/releases?id=eq.$id&select=cancel_requested'),
      headers: _headers,
    );
    _check(response);
    final rows = jsonDecode(response.body) as List;
    return rows.isNotEmpty && rows.first['cancel_requested'] == true;
  }

  Future<void> updateStep(String id, Map<String, dynamic> patch) async {
    final response = await _client.patch(
      Uri.parse('$url/rest/v1/release_steps?id=eq.$id'),
      headers: {..._headers, 'Prefer': 'return=minimal'},
      body: jsonEncode(patch),
    );
    _check(response);
  }

  Future<void> appendLog({
    required String releaseId,
    required int seq,
    required String text,
    String? stepId,
    String level = 'info',
  }) async {
    final response = await _client.post(
      Uri.parse('$url/rest/v1/release_logs'),
      headers: {..._headers, 'Prefer': 'return=minimal'},
      body: jsonEncode({
        'release_id': releaseId,
        'seq': seq,
        'step_id': stepId,
        'level': level,
        'text': text,
      }),
    );
    _check(response);
  }

  Future<void> heartbeat({
    required String runnerId,
    required String name,
    required List<String> platforms,
  }) async {
    final response = await _client.post(
      Uri.parse('$url/rest/v1/runners?on_conflict=id'),
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode({
        'id': runnerId,
        'name': name,
        'platforms': platforms,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static List<int> _unhex(String value) {
    final hex = value.startsWith(r'\x') ? value.substring(2) : value;
    return [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.body);

  final int status;
  final String body;

  @override
  String toString() => 'Supabase $status: $body';
}
