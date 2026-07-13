import 'package:aonw_server/src/auth/auth_maintenance_future_call.dart';
import 'package:aonw_server/src/auth/steam_auth_route.dart';
import 'package:aonw_server/src/auth/steam_auth_service.dart';
import 'package:aonw_server/src/generated/endpoints.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_turn_timeout_future_call.dart';
import 'package:aonw_server/src/public_stats/public_multiplayer_stats_route.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/providers/apple.dart' as apple;
import 'package:serverpod_auth_idp_server/providers/google.dart' as google;

Future<void> run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());
  final turnTimeoutSweepRegistered = _registerTurnTimeoutSweep(pod);
  final authMaintenanceRegistered = _registerAuthMaintenance(pod);
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
  pod.webServer.addRoute(PublicMultiplayerStatsRoute(), '/api/stats');

  await pod.start();
  if (turnTimeoutSweepRegistered) {
    final turnTimeoutReconciler = MultiplayerTurnTimeoutScheduleReconciler(pod);
    await turnTimeoutReconciler.start();
    pod.experimental.shutdownTasks.addTask(
      multiplayerTurnTimeoutReconcilerShutdownTaskId,
      turnTimeoutReconciler.close,
    );
  }
  if (authMaintenanceRegistered) {
    final authMaintenanceReconciler = AuthMaintenanceScheduleReconciler(pod);
    await authMaintenanceReconciler.start();
    pod.experimental.shutdownTasks.addTask(
      authMaintenanceReconcilerShutdownTaskId,
      authMaintenanceReconciler.close,
    );
  }
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

bool _registerTurnTimeoutSweep(Serverpod pod) {
  try {
    pod.registerFutureCall(
      MultiplayerTurnTimeoutSweepCall(hub: multiplayerHub),
      multiplayerTurnTimeoutSweepCallName,
    );
    return true;
  } on StateError {
    // Future calls can be disabled for maintenance/test roles; turn timeout
    // enforcement still runs on direct command handling in those modes.
    return false;
  }
}

bool _registerAuthMaintenance(Serverpod pod) {
  try {
    pod.registerFutureCall(
      AuthMaintenanceFutureCall(),
      authMaintenanceFutureCallName,
    );
    return true;
  } on StateError {
    // Future calls can be disabled for maintenance/test roles.
    return false;
  }
}
