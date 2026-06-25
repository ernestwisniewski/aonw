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
import 'package:serverpod/serverpod.dart' as _i1;
import '../auth/account_profile_endpoint.dart' as _i2;
import '../auth/apple_idp_endpoint.dart' as _i3;
import '../auth/email_idp_endpoint.dart' as _i4;
import '../auth/google_idp_endpoint.dart' as _i5;
import '../auth/jwt_refresh_endpoint.dart' as _i6;
import '../auth/steam_auth_endpoint.dart' as _i7;
import '../multiplayer/multiplayer_endpoint.dart' as _i8;
import 'package:aonw_server/src/generated/multiplayer/models/create_match_request.dart'
    as _i9;
import 'package:aonw_server/src/generated/multiplayer/models/multiplayer_client_message.dart'
    as _i10;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i11;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i12;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'accountProfile': _i2.AccountProfileEndpoint()
        ..initialize(server, 'accountProfile', null),
      'appleIdp': _i3.AppleIdpEndpoint()..initialize(server, 'appleIdp', null),
      'emailIdp': _i4.EmailIdpEndpoint()..initialize(server, 'emailIdp', null),
      'googleIdp': _i5.GoogleIdpEndpoint()
        ..initialize(server, 'googleIdp', null),
      'jwtRefresh': _i6.JwtRefreshEndpoint()
        ..initialize(server, 'jwtRefresh', null),
      'steamAuth': _i7.SteamAuthEndpoint()
        ..initialize(server, 'steamAuth', null),
      'multiplayer': _i8.MultiplayerEndpoint()
        ..initialize(server, 'multiplayer', null),
    };
    connectors['accountProfile'] = _i1.EndpointConnector(
      name: 'accountProfile',
      endpoint: endpoints['accountProfile']!,
      methodConnectors: {
        'ensureAccount': _i1.MethodConnector(
          name: 'ensureAccount',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['accountProfile'] as _i2.AccountProfileEndpoint)
                  .ensureAccount(session),
        ),
      },
    );
    connectors['appleIdp'] = _i1.EndpointConnector(
      name: 'appleIdp',
      endpoint: endpoints['appleIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'identityToken': _i1.ParameterDescription(
              name: 'identityToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'authorizationCode': _i1.ParameterDescription(
              name: 'authorizationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'isNativeApplePlatformSignIn': _i1.ParameterDescription(
              name: 'isNativeApplePlatformSignIn',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'firstName': _i1.ParameterDescription(
              name: 'firstName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'lastName': _i1.ParameterDescription(
              name: 'lastName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['appleIdp'] as _i3.AppleIdpEndpoint).login(
                session,
                identityToken: params['identityToken'],
                authorizationCode: params['authorizationCode'],
                isNativeApplePlatformSignIn:
                    params['isNativeApplePlatformSignIn'],
                firstName: params['firstName'],
                lastName: params['lastName'],
              ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['appleIdp'] as _i3.AppleIdpEndpoint).hasAccount(
                session,
              ),
        ),
      },
    );
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _i4.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'createAccount': _i1.MethodConnector(
          name: 'createAccount',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _i4.EmailIdpEndpoint).createAccount(
                session,
                email: params['email'],
                password: params['password'],
                displayName: params['displayName'],
              ),
        ),
        'displayName': _i1.MethodConnector(
          name: 'displayName',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _i4.EmailIdpEndpoint).displayName(
                session,
              ),
        ),
        'updateDisplayName': _i1.MethodConnector(
          name: 'updateDisplayName',
          params: {
            'displayName': _i1.ParameterDescription(
              name: 'displayName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _i4.EmailIdpEndpoint).updateDisplayName(
                session,
                displayName: params['displayName'],
              ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _i4.EmailIdpEndpoint).hasAccount(
                session,
              ),
        ),
      },
    );
    connectors['googleIdp'] = _i1.EndpointConnector(
      name: 'googleIdp',
      endpoint: endpoints['googleIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'idToken': _i1.ParameterDescription(
              name: 'idToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['googleIdp'] as _i5.GoogleIdpEndpoint).login(
                session,
                idToken: params['idToken'],
                accessToken: params['accessToken'],
              ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['googleIdp'] as _i5.GoogleIdpEndpoint).hasAccount(
                session,
              ),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['jwtRefresh'] as _i6.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['steamAuth'] = _i1.EndpointConnector(
      name: 'steamAuth',
      endpoint: endpoints['steamAuth']!,
      methodConnectors: {
        'start': _i1.MethodConnector(
          name: 'start',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['steamAuth'] as _i7.SteamAuthEndpoint).start(session),
        ),
        'poll': _i1.MethodConnector(
          name: 'poll',
          params: {
            'requestId': _i1.ParameterDescription(
              name: 'requestId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['steamAuth'] as _i7.SteamAuthEndpoint).poll(
                session,
                requestId: params['requestId'],
              ),
        ),
      },
    );
    connectors['multiplayer'] = _i1.EndpointConnector(
      name: 'multiplayer',
      endpoint: endpoints['multiplayer']!,
      methodConnectors: {
        'listMatches': _i1.MethodConnector(
          name: 'listMatches',
          params: {},
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).listMatches(
                session,
              ),
        ),
        'createMatch': _i1.MethodConnector(
          name: 'createMatch',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i9.CreateMatchRequest>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).createMatch(
                session,
                params['request'],
              ),
        ),
        'quickplay': _i1.MethodConnector(
          name: 'quickplay',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i9.CreateMatchRequest>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).quickplay(
                session,
                params['request'],
              ),
        ),
        'joinMatch': _i1.MethodConnector(
          name: 'joinMatch',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'countryId': _i1.ParameterDescription(
              name: 'countryId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).joinMatch(
                session,
                params['matchId'],
                params['countryId'],
              ),
        ),
        'joinPrivateMatch': _i1.MethodConnector(
          name: 'joinPrivateMatch',
          params: {
            'inviteCode': _i1.ParameterDescription(
              name: 'inviteCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'countryId': _i1.ParameterDescription(
              name: 'countryId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint)
                  .joinPrivateMatch(
                    session,
                    params['inviteCode'],
                    params['countryId'],
                  ),
        ),
        'loadMatch': _i1.MethodConnector(
          name: 'loadMatch',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).loadMatch(
                session,
                params['matchId'],
              ),
        ),
        'loadSnapshot': _i1.MethodConnector(
          name: 'loadSnapshot',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint)
                  .loadSnapshot(session, params['matchId']),
        ),
        'listEvents': _i1.MethodConnector(
          name: 'listEvents',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'afterOffset': _i1.ParameterDescription(
              name: 'afterOffset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).listEvents(
                session,
                params['matchId'],
                params['afterOffset'],
              ),
        ),
        'startMatch': _i1.MethodConnector(
          name: 'startMatch',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).startMatch(
                session,
                params['matchId'],
              ),
        ),
        'markMapLoaded': _i1.MethodConnector(
          name: 'markMapLoaded',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint)
                  .markMapLoaded(session, params['matchId']),
        ),
        'resignMatch': _i1.MethodConnector(
          name: 'resignMatch',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).resignMatch(
                session,
                params['matchId'],
              ),
        ),
        'leaveMatch': _i1.MethodConnector(
          name: 'leaveMatch',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (_i1.Session session, Map<String, dynamic> params) async =>
              (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).leaveMatch(
                session,
                params['matchId'],
              ),
        ),
        'connect': _i1.MethodStreamConnector(
          name: 'connect',
          params: {
            'matchId': _i1.ParameterDescription(
              name: 'matchId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'afterOffset': _i1.ParameterDescription(
              name: 'afterOffset',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {
            'input':
                _i1.StreamParameterDescription<_i10.MultiplayerClientMessage>(
                  name: 'input',
                  nullable: false,
                ),
          },
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['multiplayer'] as _i8.MultiplayerEndpoint).connect(
                    session,
                    params['matchId'],
                    params['afterOffset'],
                    streamParams['input']!
                        .cast<_i10.MultiplayerClientMessage>(),
                  ),
        ),
      },
    );
    modules['serverpod_auth_core'] = _i11.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_idp'] = _i12.Endpoints()
      ..initializeEndpoints(server);
  }
}
