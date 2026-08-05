import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

Object mapServerpodMultiplayerFailure(Object error) {
  if (error is MultiplayerFailure) return error;
  if (error is sp.MultiplayerException) {
    return MultiplayerFailure(
      kind: MultiplayerFailureKind.multiplayer,
      code: error.code,
      message: error.message,
      cause: error,
    );
  }
  if (error is sp.AccountAuthException) {
    return MultiplayerFailure(
      kind: MultiplayerFailureKind.authentication,
      code: error.code,
      message: error.message,
      cause: error,
    );
  }
  if (error is sp_auth.RefreshTokenMalformedException ||
      error is sp_auth.RefreshTokenNotFoundException ||
      error is sp_auth.RefreshTokenExpiredException ||
      error is sp_auth.RefreshTokenInvalidSecretException) {
    return MultiplayerFailure(
      kind: MultiplayerFailureKind.authentication,
      code: 'refresh_rejected',
      cause: error,
      message: error.toString(),
    );
  }
  if (error is sp.MethodStreamException ||
      error is sp.ServerpodClientException) {
    return MultiplayerFailure(
      kind: MultiplayerFailureKind.connection,
      cause: error,
      message: error.toString(),
    );
  }
  return error;
}

bool isRejectedServerpodRefreshError(Object error) {
  final mapped = mapServerpodMultiplayerFailure(error);
  return mapped is MultiplayerFailure &&
      mapped.kind == MultiplayerFailureKind.authentication &&
      mapped.code == 'refresh_rejected';
}

Never throwMappedServerpodMultiplayerFailure(
  Object error,
  StackTrace stackTrace,
) {
  Error.throwWithStackTrace(mapServerpodMultiplayerFailure(error), stackTrace);
}
