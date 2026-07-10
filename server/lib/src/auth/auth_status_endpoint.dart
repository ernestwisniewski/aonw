import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import 'auth_input_validator.dart';
import 'auth_rate_limiter.dart';

/// Manages the lifecycle of authenticated sessions.
///
/// Serverpod Auth already exposes access-token based sign-out through its
/// status endpoint. This endpoint covers clients that only have a persisted
/// refresh token, or whose short-lived access token expired.
class AuthStatusEndpoint extends Endpoint {
  AuthStatusEndpoint({AuthRequestLimiter? rateLimiter})
    : _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter();

  final AuthRequestLimiter _rateLimiter;

  /// Revokes the session represented by [refreshToken].
  ///
  /// Rotating the token first proves possession of its complete secret. Merely
  /// decoding its public id and deleting that row would allow anyone holding an
  /// old access token to sign another device out.
  @unauthenticatedClientCall
  Future<void> signOutRefreshToken(
    Session session, {
    required String refreshToken,
  }) async {
    const AuthInputValidator().refreshToken(refreshToken);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.sessionLogout,
      credential: DatabaseAuthRateLimiter.refreshTokenCredential(refreshToken),
    );
    final jwt = AuthServices.getTokenManager<JwtTokenManager>().jwt;
    final rotated = await jwt.refreshAccessToken(
      session,
      refreshToken: refreshToken,
    );
    await AuthServices.instance.tokenManager.revokeToken(
      session,
      tokenId: rotated.jwtRefreshTokenId.uuid,
      tokenIssuer: JwtTokenManager.tokenIssuerName,
    );
  }
}
