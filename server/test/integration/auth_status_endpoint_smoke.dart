import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'AuthStatusEndpoint',
    (sessionBuilder, endpoints) {
      test(
        'revokes only the session represented by the refresh token',
        () async {
          _ensureAuthServices();
          final firstSession = await endpoints.emailIdp.createAccount(
            sessionBuilder,
            email: 'logout@example.test',
            password: 'long-password',
            displayName: 'Logout Tester',
          );
          final secondSession = await endpoints.emailIdp.login(
            sessionBuilder,
            email: 'logout@example.test',
            password: 'long-password',
          );
          expect(firstSession.refreshToken, isNotNull);
          expect(secondSession.refreshToken, isNotNull);
          expect(secondSession.refreshToken, isNot(firstSession.refreshToken));

          await endpoints.authStatus.signOutRefreshToken(
            sessionBuilder,
            refreshToken: firstSession.refreshToken!,
          );

          await expectLater(
            endpoints.jwtRefresh.refreshAccessToken(
              sessionBuilder,
              refreshToken: firstSession.refreshToken!,
            ),
            throwsA(isA<auth_core.RefreshTokenNotFoundException>()),
          );
          final rotatedSecondSession = await endpoints.jwtRefresh
              .refreshAccessToken(
                sessionBuilder,
                refreshToken: secondSession.refreshToken!,
              );
          expect(rotatedSecondSession.authUserId, firstSession.authUserId);
        },
      );
    },
    rollbackDatabase: RollbackDatabase.afterEach,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

void _ensureAuthServices() {
  try {
    auth_core.AuthServices.instance;
  } on StateError {
    auth_core.AuthServices.set(
      tokenManagerBuilders: [auth_core.JwtConfigFromPasswords()],
    );
  }
}
