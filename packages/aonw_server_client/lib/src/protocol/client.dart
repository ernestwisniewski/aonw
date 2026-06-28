/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:aonw_server_client/src/protocol/auth/models/steam_auth_start.dart'
    as _i5;
import 'package:aonw_server_client/src/protocol/auth/models/steam_auth_poll_result.dart'
    as _i6;
import 'package:aonw_core/protocol/wire_match.dart' as _i7;
import 'package:aonw_server_client/src/protocol/multiplayer/models/create_match_request.dart'
    as _i8;
import 'package:aonw_core/protocol/wire_snapshot.dart' as _i9;
import 'package:aonw_core/protocol/wire_event.dart' as _i10;
import 'package:aonw_server_client/src/protocol/multiplayer/models/multiplayer_server_message.dart'
    as _i11;
import 'package:aonw_server_client/src/protocol/multiplayer/models/multiplayer_client_message.dart'
    as _i12;
import 'protocol.dart' as _i13;

/// {@category Endpoint}
class EndpointAppStatus extends _i1.EndpointRef {
  EndpointAppStatus(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'appStatus';

  _i2.Future<String> versionStatus({
    required String platform,
    required int buildNumber,
  }) => caller.callServerEndpoint<String>('appStatus', 'versionStatus', {
    'platform': platform,
    'buildNumber': buildNumber,
  }, authenticated: false);
}

/// Keeps the game account table in sync with Serverpod Auth users.
/// {@category Endpoint}
class EndpointAccountProfile extends _i1.EndpointRef {
  EndpointAccountProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'accountProfile';

  _i2.Future<String> ensureAccount() =>
      caller.callServerEndpoint<String>('accountProfile', 'ensureAccount', {});
}

/// Apple account endpoint backed by Serverpod Auth IDP.
/// {@category Endpoint}
class EndpointAppleIdp extends _i3.EndpointAppleIdpBase {
  EndpointAppleIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'appleIdp';

  /// Signs in a user with their Apple account.
  ///
  /// If no user exists yet linked to the Apple-provided identifier, a new one
  /// will be created (without any `Scope`s). Further their provided name and
  /// email (if any) will be used for the `UserProfile` which will be linked to
  /// their `AuthUser`.
  ///
  /// Returns a session for the user upon successful login.
  @override
  _i2.Future<_i4.AuthSuccess> login({
    required String identityToken,
    required String authorizationCode,
    required bool isNativeApplePlatformSignIn,
    String? firstName,
    String? lastName,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>('appleIdp', 'login', {
    'identityToken': identityToken,
    'authorizationCode': authorizationCode,
    'isNativeApplePlatformSignIn': isNativeApplePlatformSignIn,
    'firstName': firstName,
    'lastName': lastName,
  });

  @override
  _i2.Future<bool> hasAccount() =>
      caller.callServerEndpoint<bool>('appleIdp', 'hasAccount', {});
}

/// Email/password account endpoint backed by Serverpod Auth Core.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointRef {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  _i2.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>('emailIdp', 'login', {
    'email': email,
    'password': password,
  }, authenticated: false);

  _i2.Future<_i4.AuthSuccess> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'createAccount',
    {'email': email, 'password': password, 'displayName': displayName},
    authenticated: false,
  );

  _i2.Future<String> displayName() =>
      caller.callServerEndpoint<String>('emailIdp', 'displayName', {});

  _i2.Future<String> updateDisplayName({required String displayName}) =>
      caller.callServerEndpoint<String>('emailIdp', 'updateDisplayName', {
        'displayName': displayName,
      });

  _i2.Future<bool> hasAccount() =>
      caller.callServerEndpoint<bool>('emailIdp', 'hasAccount', {});
}

/// Google account endpoint backed by Serverpod Auth IDP.
/// {@category Endpoint}
class EndpointGoogleIdp extends _i3.EndpointGoogleIdpBase {
  EndpointGoogleIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'googleIdp';

  /// Validates a Google ID token and either logs in the associated user or
  /// creates a new user account if the Google account ID is not yet known.
  ///
  /// If a new user is created an associated [UserProfile] is also created.
  @override
  _i2.Future<_i4.AuthSuccess> login({
    required String idToken,
    required String? accessToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>('googleIdp', 'login', {
    'idToken': idToken,
    'accessToken': accessToken,
  });

  @override
  _i2.Future<bool> hasAccount() =>
      caller.callServerEndpoint<bool>('googleIdp', 'hasAccount', {});
}

/// JWT refresh endpoint used by Serverpod auth clients.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i2.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// {@category Endpoint}
class EndpointSteamAuth extends _i1.EndpointRef {
  EndpointSteamAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'steamAuth';

  _i2.Future<_i5.SteamAuthStart> start() =>
      caller.callServerEndpoint<_i5.SteamAuthStart>(
        'steamAuth',
        'start',
        {},
        authenticated: false,
      );

  _i2.Future<_i6.SteamAuthPollResult> poll({required String requestId}) =>
      caller.callServerEndpoint<_i6.SteamAuthPollResult>('steamAuth', 'poll', {
        'requestId': requestId,
      }, authenticated: false);
}

/// {@category Endpoint}
class EndpointMultiplayer extends _i1.EndpointRef {
  EndpointMultiplayer(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'multiplayer';

  _i2.Future<List<_i7.WireMatch>> listMatches() =>
      caller.callServerEndpoint<List<_i7.WireMatch>>(
        'multiplayer',
        'listMatches',
        {},
      );

  _i2.Future<_i7.WireMatch> createMatch(_i8.CreateMatchRequest request) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'createMatch', {
        'request': request,
      });

  _i2.Future<_i7.WireMatch> quickplay(_i8.CreateMatchRequest request) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'quickplay', {
        'request': request,
      });

  _i2.Future<_i7.WireMatch> joinMatch(String matchId, [String? countryId]) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'joinMatch', {
        'matchId': matchId,
        'countryId': countryId,
      });

  _i2.Future<_i7.WireMatch> joinPrivateMatch(
    String inviteCode, [
    String? countryId,
  ]) => caller.callServerEndpoint<_i7.WireMatch>(
    'multiplayer',
    'joinPrivateMatch',
    {'inviteCode': inviteCode, 'countryId': countryId},
  );

  _i2.Future<_i7.WireMatch> loadMatch(String matchId) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'loadMatch', {
        'matchId': matchId,
      });

  _i2.Future<_i9.WireSnapshot> loadSnapshot(String matchId) =>
      caller.callServerEndpoint<_i9.WireSnapshot>(
        'multiplayer',
        'loadSnapshot',
        {'matchId': matchId},
      );

  _i2.Future<List<_i10.WireEvent>> listEvents(
    String matchId,
    int afterOffset,
  ) => caller.callServerEndpoint<List<_i10.WireEvent>>(
    'multiplayer',
    'listEvents',
    {'matchId': matchId, 'afterOffset': afterOffset},
  );

  _i2.Future<_i7.WireMatch> startMatch(String matchId) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'startMatch', {
        'matchId': matchId,
      });

  _i2.Future<_i7.WireMatch> markMapLoaded(String matchId) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'markMapLoaded', {
        'matchId': matchId,
      });

  _i2.Future<_i7.WireMatch> resignMatch(String matchId) =>
      caller.callServerEndpoint<_i7.WireMatch>('multiplayer', 'resignMatch', {
        'matchId': matchId,
      });

  _i2.Future<void> leaveMatch(String matchId) =>
      caller.callServerEndpoint<void>('multiplayer', 'leaveMatch', {
        'matchId': matchId,
      });

  _i2.Stream<_i11.MultiplayerServerMessage> connect(
    String matchId,
    int afterOffset,
    _i2.Stream<_i12.MultiplayerClientMessage> input,
  ) =>
      caller.callStreamingServerEndpoint<
        _i2.Stream<_i11.MultiplayerServerMessage>,
        _i11.MultiplayerServerMessage
      >(
        'multiplayer',
        'connect',
        {'matchId': matchId, 'afterOffset': afterOffset},
        {'input': input},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_core = _i4.Caller(client);
    serverpod_auth_idp = _i3.Caller(client);
  }

  late final _i4.Caller serverpod_auth_core;

  late final _i3.Caller serverpod_auth_idp;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(_i1.MethodCallContext, Object, StackTrace)? onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i13.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    appStatus = EndpointAppStatus(this);
    accountProfile = EndpointAccountProfile(this);
    appleIdp = EndpointAppleIdp(this);
    emailIdp = EndpointEmailIdp(this);
    googleIdp = EndpointGoogleIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    steamAuth = EndpointSteamAuth(this);
    multiplayer = EndpointMultiplayer(this);
    modules = Modules(this);
  }

  late final EndpointAppStatus appStatus;

  late final EndpointAccountProfile accountProfile;

  late final EndpointAppleIdp appleIdp;

  late final EndpointEmailIdp emailIdp;

  late final EndpointGoogleIdp googleIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointSteamAuth steamAuth;

  late final EndpointMultiplayer multiplayer;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'appStatus': appStatus,
    'accountProfile': accountProfile,
    'appleIdp': appleIdp,
    'emailIdp': emailIdp,
    'googleIdp': googleIdp,
    'jwtRefresh': jwtRefresh,
    'steamAuth': steamAuth,
    'multiplayer': multiplayer,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_core': modules.serverpod_auth_core,
    'serverpod_auth_idp': modules.serverpod_auth_idp,
  };
}
