import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import 'auth_input_validator.dart';
import 'auth_rate_limiter.dart';

/// JWT refresh endpoint used by Serverpod auth clients.
class JwtRefreshEndpoint extends RefreshJwtTokensEndpoint {
  JwtRefreshEndpoint({AuthRequestLimiter? rateLimiter})
    : _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter();

  static const _inputValidator = AuthInputValidator();
  final AuthRequestLimiter _rateLimiter;

  @override
  @unauthenticatedClientCall
  Future<AuthSuccess> refreshAccessToken(
    Session session, {
    required String refreshToken,
  }) async {
    _inputValidator.refreshToken(refreshToken);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.jwtRefresh,
      credential: DatabaseAuthRateLimiter.refreshTokenCredential(refreshToken),
    );
    return super.refreshAccessToken(session, refreshToken: refreshToken);
  }
}
