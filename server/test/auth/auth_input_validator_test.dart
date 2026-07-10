import 'package:aonw_server/src/auth/auth_input_validator.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  const validator = AuthInputValidator();

  test('normalizes practical email addresses', () {
    expect(
      validator.newAccountEmail(' Player+test@Example.COM '),
      'player+test@example.com',
    );
  });

  test('rejects malformed and oversized account email addresses', () {
    for (final email in [
      'missing-at.example.com',
      'two@@example.com',
      '.leading@example.com',
      'double..dot@example.com',
      'user@localhost',
      'user@-example.com',
      '${List.filled(245, 'x').join()}@example.com',
    ]) {
      expect(
        () => validator.newAccountEmail(email),
        throwsA(_error('invalid_email')),
      );
    }
  });

  test('uses generic credential errors for malformed login input', () {
    expect(
      () => validator.loginEmail('invalid'),
      throwsA(_error('invalid_credentials')),
    );
    expect(
      () => validator.loginPassword(''),
      throwsA(_error('invalid_credentials')),
    );
    expect(
      () => validator.loginPassword(
        List.filled(AuthInputValidator.maxPasswordLength + 1, 'x').join(),
      ),
      throwsA(_error('invalid_credentials')),
    );
  });

  test('bounds new passwords before Argon2 work', () {
    validator.newAccountPassword('correct horse battery staple');

    for (final password in [
      'short',
      List.filled(AuthInputValidator.maxPasswordLength + 1, 'x').join(),
    ]) {
      expect(
        () => validator.newAccountPassword(password),
        throwsA(_error('weak_password')),
      );
    }
  });

  test('bounds refresh tokens before cryptographic work', () {
    expect(
      () => validator.refreshToken('bounded-refresh-token'),
      returnsNormally,
    );
    expect(
      () => validator.refreshToken(''),
      throwsA(_error('invalid_session')),
    );
    expect(
      () => validator.refreshToken(
        List.filled(AuthInputValidator.maxRefreshTokenLength + 1, 'x').join(),
      ),
      throwsA(_error('invalid_session')),
    );
  });

  test('normalizes and bounds display names before database work', () {
    expect(validator.displayName('  Player   One  '), 'Player One');
    expect(
      () => validator.displayName(List.filled(65, 'x').join()),
      throwsA(_error('invalid_display_name')),
    );
    expect(
      () => validator.displayName('bad<script>'),
      throwsA(_error('invalid_display_name')),
    );
  });

  test('accepts only server-generated Steam request id shapes', () {
    final valid = List.filled(
      AuthInputValidator.steamRequestIdLength,
      'A',
    ).join();

    expect(validator.isValidSteamRequestId(valid), isTrue);
    expect(validator.isValidSteamRequestId('short'), isFalse);
    expect(validator.isValidSteamRequestId('${valid.substring(1)}!'), isFalse);
  });
}

Matcher _error(String code) {
  return isA<AccountAuthException>().having(
    (error) => error.code,
    'code',
    code,
  );
}
