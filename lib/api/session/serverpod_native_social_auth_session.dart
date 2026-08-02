import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/game/application/ports/native_social_auth.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

final class ServerpodNativeSocialAuthSession
    implements NativeSocialAuthSession {
  final sp.Client _client;

  ServerpodNativeSocialAuthSession(String serverpodHost)
    : _client = createServerpodClient(serverpodHost) {
    FlutterAuthSessionManagerExtension(_client).authSessionManager =
        FlutterAuthSessionManager(storage: _EphemeralAuthSuccessStorage());
  }

  @override
  Object get clientHandle => _client;

  @override
  Object? get authSuccess =>
      FlutterAuthSessionManagerExtension(_client).auth.authInfo;

  @override
  Future<void> initializeGoogle({String? clientId, String? serverClientId}) {
    final auth = FlutterAuthSessionManagerExtension(_client).auth;
    return auth.initializeGoogleSignIn(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  @override
  Future<void> initializeApple({
    String? serviceIdentifier,
    String? redirectUri,
  }) {
    final auth = FlutterAuthSessionManagerExtension(_client).auth;
    return auth.initializeAppleSignIn(
      serviceIdentifier: serviceIdentifier,
      redirectUri: redirectUri,
    );
  }

  @override
  void close() => _client.close();
}

final class _EphemeralAuthSuccessStorage implements ClientAuthSuccessStorage {
  sp_auth.AuthSuccess? _auth;

  @override
  Future<sp_auth.AuthSuccess?> get() async => _auth;

  @override
  Future<void> set(sp_auth.AuthSuccess? data) async {
    _auth = data;
  }
}
