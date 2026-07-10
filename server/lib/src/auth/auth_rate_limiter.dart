import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import '../observability/server_operational_event_sink.dart';

enum AuthRateLimitAction {
  emailLogin,
  emailCreate,
  steamStart,
  steamPoll,
  steamCallback,
  jwtRefresh,
  sessionLogout,
}

final class AuthRateLimitPolicy {
  const AuthRateLimitPolicy({
    required this.timeframe,
    required this.maxIpAttempts,
    this.maxCredentialAttempts,
  });

  final Duration timeframe;
  final int maxIpAttempts;
  final int? maxCredentialAttempts;
}

abstract interface class AuthRequestLimiter {
  Future<void> enforce(
    Session session, {
    required AuthRateLimitAction action,
    String? credential,
  });
}

/// Persistent authentication abuse limits shared by every server instance.
final class DatabaseAuthRateLimiter implements AuthRequestLimiter {
  DatabaseAuthRateLimiter({
    ServerOperationalEventSink Function(Session session)? operationalEventsFor,
  }) : _operationalEventsFor =
           operationalEventsFor ?? ServerpodOperationalEventSink.new;

  final Map<String, DatabaseRateLimitedRequestAttemptUtil<String>> _limits = {};
  final ServerOperationalEventSink Function(Session session)
  _operationalEventsFor;

  @override
  Future<void> enforce(
    Session session, {
    required AuthRateLimitAction action,
    String? credential,
  }) async {
    final policy = policyFor(action);
    final pepper = _pepper();
    final remoteIp =
        session.request?.connectionInfo.remote.address.toString() ?? 'unknown';
    final ipLimited = await _hasTooManyAttempts(
      session,
      source: '${action.name}_ip',
      nonce: fingerprint('ip:$remoteIp', pepper: pepper),
      maxAttempts: policy.maxIpAttempts,
      timeframe: policy.timeframe,
    );
    if (ipLimited) {
      _operationalEventsFor(session).authRateLimited(action: action);
      throw _rateLimited();
    }

    final maxCredentialAttempts = policy.maxCredentialAttempts;
    if (credential == null || maxCredentialAttempts == null) return;
    final credentialLimited = await _hasTooManyAttempts(
      session,
      source: '${action.name}_credential',
      nonce: fingerprint('credential:$credential', pepper: pepper),
      maxAttempts: maxCredentialAttempts,
      timeframe: policy.timeframe,
    );
    if (credentialLimited) {
      _operationalEventsFor(session).authRateLimited(action: action);
      throw _rateLimited();
    }
  }

  Future<bool> _hasTooManyAttempts(
    Session session, {
    required String source,
    required String nonce,
    required int maxAttempts,
    required Duration timeframe,
  }) {
    final key = '$source:$maxAttempts:${timeframe.inSeconds}';
    final limiter = _limits.putIfAbsent(
      key,
      () => DatabaseRateLimitedRequestAttemptUtil<String>(
        RateLimitedRequestAttemptConfig<String>(
          domain: 'aonw_auth',
          source: source,
          maxAttempts: maxAttempts,
          timeframe: timeframe,
        ),
      ),
    );
    return limiter.hasTooManyAttempts(session, nonce: nonce);
  }

  String _pepper() {
    const key = 'emailSecretHashPepper';
    final pepper = Serverpod.instance.getPassword(key);
    if (pepper == null || pepper.isEmpty) {
      throw StateError('Missing authentication rate-limit pepper.');
    }
    return pepper;
  }

  static AuthRateLimitPolicy policyFor(AuthRateLimitAction action) {
    return switch (action) {
      AuthRateLimitAction.emailLogin => const AuthRateLimitPolicy(
        timeframe: Duration(minutes: 15),
        maxIpAttempts: 60,
        maxCredentialAttempts: 10,
      ),
      AuthRateLimitAction.emailCreate => const AuthRateLimitPolicy(
        timeframe: Duration(hours: 1),
        maxIpAttempts: 10,
        maxCredentialAttempts: 3,
      ),
      AuthRateLimitAction.steamStart => const AuthRateLimitPolicy(
        timeframe: Duration(minutes: 10),
        maxIpAttempts: 20,
      ),
      AuthRateLimitAction.steamPoll => const AuthRateLimitPolicy(
        timeframe: Duration(minutes: 15),
        maxIpAttempts: 2000,
        maxCredentialAttempts: 700,
      ),
      AuthRateLimitAction.steamCallback => const AuthRateLimitPolicy(
        timeframe: Duration(minutes: 15),
        maxIpAttempts: 60,
        maxCredentialAttempts: 5,
      ),
      AuthRateLimitAction.jwtRefresh => const AuthRateLimitPolicy(
        timeframe: Duration(minutes: 15),
        maxIpAttempts: 120,
        maxCredentialAttempts: 12,
      ),
      AuthRateLimitAction.sessionLogout => const AuthRateLimitPolicy(
        timeframe: Duration(minutes: 15),
        maxIpAttempts: 120,
        maxCredentialAttempts: 6,
      ),
    };
  }

  static String refreshTokenCredential(String refreshToken) {
    final parts = refreshToken.split(':');
    if (parts.length == 4 && parts.first == 'sajrt' && parts[1].isNotEmpty) {
      return 'refresh-id:${parts[1]}';
    }
    return 'malformed-refresh:$refreshToken';
  }

  static String fingerprint(String value, {required String pepper}) {
    final digest = Hmac(
      sha256,
      utf8.encode('aonw-auth-rate-limit:$pepper'),
    ).convert(utf8.encode(value));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  AccountAuthException _rateLimited() {
    return AccountAuthException(
      code: 'rate_limited',
      message: 'Too many authentication attempts. Please try again later.',
    );
  }
}
