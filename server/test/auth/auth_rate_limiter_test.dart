import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  test('fingerprints are stable, scoped, and contain no raw credential', () {
    final first = DatabaseAuthRateLimiter.fingerprint(
      'credential:user@example.test',
      pepper: 'test-pepper',
    );
    final second = DatabaseAuthRateLimiter.fingerprint(
      'credential:user@example.test',
      pepper: 'test-pepper',
    );
    final otherScope = DatabaseAuthRateLimiter.fingerprint(
      'ip:user@example.test',
      pepper: 'test-pepper',
    );

    expect(first, second);
    expect(first, isNot(otherScope));
    expect(first, isNot(contains('user@example.test')));
    expect(first.length, 43);
  });

  test('refresh secrets share the public token-id credential bucket', () {
    const id = 'AQIDBAUGBwgJCgsMDQ4PEA==';
    final first = DatabaseAuthRateLimiter.refreshTokenCredential(
      'sajrt:$id:fixed:first-secret',
    );
    final rotated = DatabaseAuthRateLimiter.refreshTokenCredential(
      'sajrt:$id:fixed:rotated-secret',
    );

    expect(first, rotated);
    expect(first, 'refresh-id:$id');
  });

  test('malformed refresh-token ids cannot claim a credential bucket', () {
    const malformed = 'sajrt:not-base64:fixed:rotating-secret';

    expect(
      DatabaseAuthRateLimiter.refreshTokenCredential(malformed),
      'malformed-refresh:$malformed',
    );
  });

  test('policies bound both credential and IP attempts where applicable', () {
    final login = DatabaseAuthRateLimiter.policyFor(
      AuthRateLimitAction.emailLogin,
    );
    final creation = DatabaseAuthRateLimiter.policyFor(
      AuthRateLimitAction.emailCreate,
    );
    final steamStart = DatabaseAuthRateLimiter.policyFor(
      AuthRateLimitAction.steamStart,
    );

    expect(login.maxCredentialAttempts, 10);
    expect(login.maxIpAttempts, 60);
    expect(login.timeframe, const Duration(minutes: 15));
    expect(creation.maxCredentialAttempts, 3);
    expect(creation.timeframe, const Duration(hours: 1));
    expect(steamStart.maxCredentialAttempts, isNull);
    expect(steamStart.maxIpAttempts, 20);
  });
}
