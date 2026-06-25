import 'dart:convert';

import 'package:aonw/api/session/auth_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthToken', () {
    test('parses exp from a JWT payload', () {
      final token = AuthToken(_jwt(exp: 1800000000));

      expect(
        token.expiresAt,
        DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000, isUtc: true),
      );
      expect(token.isExpiredAt(DateTime.utc(2026, 1, 1)), isFalse);
      expect(token.isExpiredAt(DateTime.utc(2030, 1, 1)), isTrue);
    });

    test('uses explicit expiry when supplied', () {
      final token = AuthToken(
        'opaque-token',
        expiresAt: DateTime.utc(2026, 4, 26),
      );

      expect(token.expiresAt, DateTime.utc(2026, 4, 26));
      expect(
        token.isExpiredAt(
          DateTime.utc(2026, 4, 25, 23, 59, 40),
          skew: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('opaque tokens do not expire locally', () {
      final token = AuthToken('opaque-token');

      expect(token.expiresAt, isNull);
      expect(token.isExpiredAt(DateTime.utc(2100)), isFalse);
    });

    test('rejects empty token values', () {
      expect(() => AuthToken(''), throwsA(isA<ArgumentError>()));
    });
  });
}

String _jwt({required int exp}) {
  final header = _base64UrlJson({'alg': 'none'});
  final payload = _base64UrlJson({'exp': exp});
  return '$header.$payload.';
}

String _base64UrlJson(Map<String, Object?> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}
