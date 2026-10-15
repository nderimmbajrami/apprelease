import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase
    show AuthException;

import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import 'auth_repository.dart';

/// Supabase Auth plus the `profiles` row that carries the display name.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    _subscription = _client.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      if (session == null) {
        _emit(null);
        return;
      }
      _emit(await _load(session.user));
    });
  }

  final SupabaseClient _client;
  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<AuthState>? _subscription;
  AppUser? _current;
  var _seeded = false;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    // The first event from onAuthStateChange carries the restored session; a
    // listener that attaches late still has to get *something*, or the
    // router would wait forever.
    if (_seeded) yield _current;
    yield* _controller.stream;
  }

  Future<AppUser> _load(User user) async {
    final row = await _client
        .from('profiles')
        .select('name, team_id')
        .eq('id', user.id)
        .maybeSingle();
    return AppUser(
      id: user.id,
      name:
          (row?['name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          '',
      email: user.email ?? '',
      teamId: row?['team_id'] as String?,
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _load(response.user!);
      _emit(user);
      return user;
    } on supabase.AuthException catch (error) {
      throw AuthException(_map(error), error.message);
    }
  }

  @override
  Future<AppUser?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      final user = response.user;
      if (user == null) throw const AuthException(AuthFailure.unknown);
      // With confirmation on there is no session yet: the code that was
      // mailed has to come back first. A trigger already made the profile
      // and the team.
      if (response.session == null) return null;
      final loaded = await _load(user);
      _emit(loaded);
      return loaded;
    } on supabase.AuthException catch (error) {
      throw AuthException(_map(error), error.message);
    }
  }

  @override
  Future<AppUser> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.signup,
        email: email.trim(),
        token: code.trim(),
      );
      final user = response.user;
      if (user == null) throw const AuthException(AuthFailure.invalidCode);
      final loaded = await _load(user);
      _emit(loaded);
      return loaded;
    } on supabase.AuthException catch (error) {
      throw AuthException(_map(error), error.message);
    }
  }

  @override
  Future<void> resendSignUpCode(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim());
    } on supabase.AuthException catch (error) {
      throw AuthException(_map(error), error.message);
    }
  }

  @override
  Future<void> sendWelcomeMail() async {
    await _client.functions.invoke('notify-signup');
  }

  @override
  Future<void> updateName(String name) async {
    final id = _current?.id;
    if (id == null) return;
    await _client.from('profiles').update({'name': name.trim()}).eq('id', id);
    _emit(_current!.copyWith(name: name.trim()));
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteOwnAccount() async {
    await _client.functions.invoke('delete-account');
    await _client.auth.signOut();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_controller.close());
  }

  void _emit(AppUser? user) {
    _seeded = true;
    _current = user;
    if (!_controller.isClosed) _controller.add(user);
  }

  AuthFailure _map(supabase.AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login')) {
      return AuthFailure.invalidCredentials;
    }
    if (message.contains('already registered')) {
      return AuthFailure.emailAlreadyUsed;
    }
    if (message.contains('expired')) return AuthFailure.expiredCode;
    if (message.contains('token') || message.contains('otp')) {
      return AuthFailure.invalidCode;
    }
    if (message.contains('password')) return AuthFailure.weakPassword;
    if (message.contains('network') || message.contains('socket')) {
      return AuthFailure.network;
    }
    return AuthFailure.unknown;
  }
}
