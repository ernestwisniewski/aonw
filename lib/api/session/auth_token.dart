import 'dart:convert';

class AuthToken {
  final String value;
  final DateTime? expiresAt;

  AuthToken(this.value, {DateTime? expiresAt})
    : expiresAt = expiresAt ?? _tryReadJwtExpiry(value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Expected a non-empty token');
    }
  }

  bool isExpiredAt(DateTime now, {Duration skew = Duration.zero}) {
    final expiry = expiresAt;
    if (expiry == null) return false;
    return !now.add(skew).isBefore(expiry);
  }

  @override
  bool operator ==(Object other) {
    return other is AuthToken &&
        other.value == value &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(value, expiresAt);

  @override
  String toString() => 'AuthToken(expiresAt: $expiresAt)';

  static DateTime? _tryReadJwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      if (payload is! Map<Object?, Object?>) return null;
      final exp = payload['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          (exp * 1000).round(),
          isUtc: true,
        );
      }
      return null;
    } on FormatException {
      return null;
    }
  }
}
