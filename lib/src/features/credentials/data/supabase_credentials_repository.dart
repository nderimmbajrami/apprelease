import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/supabase_watch.dart';
import '../domain/credential.dart';
import 'credentials_repository.dart';

/// Public facts live in `credentials`; the secret goes through the
/// `store-secret` Edge Function, which encrypts it with a key only the
/// function and the runner hold, and writes it to `credential_secrets` —
/// a table no client policy can select from.
class SupabaseCredentialsRepository implements CredentialsRepository {
  SupabaseCredentialsRepository(this._client);

  static const _table = 'credentials';

  final SupabaseClient _client;
  final _writes = StreamController<void>.broadcast();

  @override
  Stream<List<Credential>> watchCredentials() => watchQuery(
    client: _client,
    tables: const [_table],
    refresh: _writes.stream,
    fetch: () async {
      final rows = await _client.from(_table).select().order('created_at');
      return [
        for (final row in rows)
          Credential(
            id: row['id'] as String,
            teamId: row['team_id'] as String,
            kind: CredentialKind.values.byName(row['kind'] as String),
            name: row['name'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            meta: {
              for (final e in ((row['meta'] as Map?) ?? const {}).entries)
                e.key as String: '${e.value}',
            },
          ),
      ];
    },
  );

  @override
  Future<Credential> addCredential(
    Credential credential,
    CredentialSecret secret,
  ) async {
    await _client.functions.invoke(
      'store-secret',
      body: {
        'id': credential.id,
        'team_id': credential.teamId,
        'kind': credential.kind.name,
        'name': credential.name,
        'meta': credential.meta,
        'secret': {
          'file_name': secret.fileName,
          'file_base64': secret.fileBytes == null
              ? null
              : base64Encode(secret.fileBytes!),
          'fields': secret.fields,
        },
      },
    );
    _touch();
    return credential;
  }

  @override
  Future<void> deleteCredential(String id) async {
    await _client.from(_table).delete().eq('id', id);
    _touch();
  }

  @override
  void dispose() {
    unawaited(_writes.close());
  }

  void _touch() {
    if (!_writes.isClosed) _writes.add(null);
  }
}
