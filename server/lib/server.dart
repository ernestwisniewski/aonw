import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/providers/apple.dart' as apple;
import 'package:serverpod_auth_idp_server/providers/google.dart' as google;

import 'src/auth/steam_auth_route.dart';
import 'src/auth/steam_auth_service.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';

void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());
  final appleConfigured = _appleIdpConfigured(pod);

  pod.initializeAuthServices(
    tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    identityProviderBuilders: [
      if (_hasPassword(pod, 'googleClientSecret'))
        google.GoogleIdpConfigFromPasswords(),
      if (appleConfigured) apple.AppleIdpConfigFromPasswords(),
    ],
  );

  if (appleConfigured) {
    pod.configureAppleIdpRoutes();
  }
  pod.webServer.addRoute(
    SteamAuthCallbackRoute(),
    SteamAuthService.callbackPath,
  );

  await pod.start();
}

bool _appleIdpConfigured(Serverpod pod) {
  return _hasPassword(pod, 'appleServiceIdentifier') &&
      _hasPassword(pod, 'appleBundleIdentifier') &&
      _hasPassword(pod, 'appleRedirectUri') &&
      _hasPassword(pod, 'appleTeamId') &&
      _hasPassword(pod, 'appleKeyId') &&
      _hasPassword(pod, 'appleKey');
}

bool _hasPassword(Serverpod pod, String key) {
  final value = pod.getPassword(key);
  return value != null && value.trim().isNotEmpty;
}
