import 'dart:convert';
import 'dart:math';

import 'package:aonw_server/src/auth/auth_rate_limiter.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/providers/apple.dart';
import 'package:serverpod_auth_idp_server/providers/google.dart';

typedef ExternalAuthProviderConfiguration = ({
  String clientId,
  String? clientSecret,
  String redirectUri,
});

typedef ExternalAuthConfigurationResolver =
    ExternalAuthProviderConfiguration Function(String provider);

typedef ExternalAuthProviderAuthenticator =
    Future<auth_core.AuthSuccess> Function(
      Session session,
      String provider,
      Map<String, String> credentials,
    );

typedef ExternalAuthTokenExchange =
    Future<Map<String, dynamic>> Function(Uri uri, Map<String, String> body);

typedef ExternalAuthCallbackResult = ({
  bool success,
  String title,
  String message,
});

enum _ExternalCallbackClaim { claimed, completed, expired, rejected }

/// Browser-based identity-provider handoff for installed desktop builds.
///
/// The provider callback is completed by the server, while the application
/// receives the resulting Serverpod session through short-lived polling. This
/// avoids platform URL schemes and unsupported native Apple entitlements in
/// Developer ID distributions.
class ExternalAuthService {
  ExternalAuthService({
    AuthRequestLimiter? rateLimiter,
    ExternalAuthConfigurationResolver? configurationResolver,
    ExternalAuthProviderAuthenticator? authenticator,
    ExternalAuthTokenExchange? tokenExchange,
  }) : _rateLimiter = rateLimiter ?? DatabaseAuthRateLimiter(),
       _configurationResolver = configurationResolver ?? _defaultConfiguration,
       _authenticator = authenticator ?? _defaultAuthenticator,
       _tokenExchange = tokenExchange ?? _defaultTokenExchange;

  static const appleProvider = 'apple';
  static const googleProvider = 'google';
  static const appleCallbackPath = '/auth/apple/callback';
  static const googleCallbackPath = '/auth/google/callback';
  static const _desktopStatePrefix = 'aonw-desktop.';

  static const _statusPending = 'pending';
  static const _statusProcessing = 'processing';
  static const _statusCompleted = 'completed';
  static const _statusConsumed = 'consumed';
  static const _statusFailed = 'failed';
  static const _statusExpired = 'expired';
  static const _statusAuthenticated = 'authenticated';

  final AuthRequestLimiter _rateLimiter;
  final ExternalAuthConfigurationResolver _configurationResolver;
  final ExternalAuthProviderAuthenticator _authenticator;
  final ExternalAuthTokenExchange _tokenExchange;

  static bool isDesktopState(String? state) =>
      state != null && state.startsWith(_desktopStatePrefix);

  Future<ExternalAuthStart> start(
    Session session, {
    required String provider,
  }) async {
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.externalAuthStart,
    );
    if (provider != appleProvider && provider != googleProvider) {
      throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
    }

    final configuration = _configurationResolver(provider);
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 10));
    final requestId = _secureToken(32);
    final state = '$_desktopStatePrefix${_secureToken(32)}';
    final codeVerifier = provider == googleProvider ? _secureToken(48) : null;
    final authUrl = switch (provider) {
      appleProvider => _appleAuthorizationUri(configuration, state),
      googleProvider => _googleAuthorizationUri(
        configuration,
        state,
        codeVerifier!,
      ),
      _ => throw StateError('Unsupported external auth provider.'),
    };

    await ExternalAuthRequest.db.insertRow(
      session,
      ExternalAuthRequest(
        requestId: requestId,
        state: state,
        provider: provider,
        status: _statusPending,
        codeVerifier: codeVerifier,
        createdAt: now,
        expiresAt: expiresAt,
      ),
    );

    return ExternalAuthStart(
      requestId: requestId,
      authUrl: authUrl.toString(),
      expiresAt: expiresAt,
    );
  }

  Future<ExternalAuthPollResult> poll(
    Session session, {
    required String requestId,
  }) async {
    final validRequestId = _isValidToken(requestId);
    await _rateLimiter.enforce(
      session,
      action: AuthRateLimitAction.externalAuthPoll,
      credential: validRequestId ? requestId : null,
    );
    if (!validRequestId) {
      return ExternalAuthPollResult(status: _statusFailed, error: 'not_found');
    }

    final now = DateTime.now().toUtc();
    return session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.requestId.equals(requestId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null) {
        return ExternalAuthPollResult(
          status: _statusFailed,
          error: 'not_found',
        );
      }

      if (request.expiresAt.isBefore(now) && request.consumedAt == null) {
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired, error: 'expired'),
          transaction: transaction,
        );
        return ExternalAuthPollResult(status: _statusExpired, error: 'expired');
      }

      if (request.status == _statusCompleted &&
          request.authStrategy != null &&
          request.token != null &&
          request.authUserId != null &&
          request.scopeNames != null &&
          request.consumedAt == null) {
        final auth = auth_core.AuthSuccess(
          authStrategy: request.authStrategy!,
          token: request.token!,
          tokenExpiresAt: request.tokenExpiresAt,
          refreshToken: request.refreshToken,
          authUserId: request.authUserId!,
          scopeNames: request.scopeNames!.toSet(),
        );
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(
            status: _statusConsumed,
            codeVerifier: null,
            token: null,
            refreshToken: null,
            consumedAt: now,
          ),
          transaction: transaction,
        );
        return ExternalAuthPollResult(status: _statusAuthenticated, auth: auth);
      }

      return ExternalAuthPollResult(
        status: request.status,
        error: request.error,
      );
    });
  }

  Future<ExternalAuthCallbackResult> handleAppleCallback(
    Session session,
    Map<String, String> parameters,
  ) async {
    final state = parameters['state'];
    if (!isDesktopState(state)) {
      return _failure('Apple sign-in failed', 'Invalid authentication state.');
    }
    final appleError = parameters['error'];
    if (appleError != null) {
      await _failByState(session, state!, _safeProviderError(appleError));
      return _failure(
        'Apple sign-in cancelled',
        'Please return to Age of New Worlds and try again.',
      );
    }

    final identityToken = parameters['id_token'];
    final authorizationCode = parameters['code'];
    if (identityToken == null || authorizationCode == null) {
      await _failByState(session, state!, 'invalid_response');
      return _failure(
        'Apple sign-in failed',
        'Apple returned an incomplete response.',
      );
    }

    final name = _parseAppleName(parameters['user']);
    return _completeCallback(
      session,
      state: state!,
      provider: appleProvider,
      credentials: {
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        if (name.firstName != null) 'firstName': name.firstName!,
        if (name.lastName != null) 'lastName': name.lastName!,
      },
    );
  }

  Future<ExternalAuthCallbackResult> handleGoogleCallback(
    Session session,
    Map<String, String> parameters,
  ) async {
    final state = parameters['state'];
    if (!isDesktopState(state)) {
      return _failure('Google sign-in failed', 'Invalid authentication state.');
    }
    final googleError = parameters['error'];
    if (googleError != null) {
      await _failByState(session, state!, _safeProviderError(googleError));
      return _failure(
        'Google sign-in cancelled',
        'Please return to Age of New Worlds and try again.',
      );
    }

    final code = parameters['code'];
    if (code == null) {
      await _failByState(session, state!, 'invalid_response');
      return _failure(
        'Google sign-in failed',
        'Google returned an incomplete response.',
      );
    }

    final request = await _requestForState(session, state!);
    if (request == null || request.provider != googleProvider) {
      return _failure(
        'Google sign-in failed',
        'The authentication request was not found.',
      );
    }
    final codeVerifier = request.codeVerifier;
    if (codeVerifier == null) {
      await _failByState(session, state, 'invalid_request');
      return _failure(
        'Google sign-in failed',
        'The authentication request is invalid.',
      );
    }

    final preparation = await _prepareCallback(
      session,
      state: state,
      provider: googleProvider,
    );
    if (!preparation.claimed) return preparation.result!;

    try {
      final configuration = _configurationResolver(googleProvider);
      final tokenResponse =
          await _tokenExchange(Uri.https('oauth2.googleapis.com', '/token'), {
            'client_id': configuration.clientId,
            'client_secret': configuration.clientSecret!,
            'code': code,
            'code_verifier': codeVerifier,
            'grant_type': 'authorization_code',
            'redirect_uri': configuration.redirectUri,
          });
      final idToken = tokenResponse['id_token'] as String?;
      final accessToken = tokenResponse['access_token'] as String?;
      if (idToken == null) throw const FormatException('Missing id_token');
      return _authenticateClaimedCallback(
        session,
        state: state,
        provider: googleProvider,
        credentials: {'idToken': idToken, 'accessToken': ?accessToken},
      );
    } catch (error, stackTrace) {
      session.log(
        'Google desktop token exchange failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      await _failByState(session, state, 'token_exchange_failed');
      return _failure(
        'Google sign-in failed',
        'Google could not validate this sign-in response.',
      );
    }
  }

  Future<ExternalAuthCallbackResult> _completeCallback(
    Session session, {
    required String state,
    required String provider,
    required Map<String, String> credentials,
  }) async {
    final preparation = await _prepareCallback(
      session,
      state: state,
      provider: provider,
    );
    if (!preparation.claimed) return preparation.result!;

    return _authenticateClaimedCallback(
      session,
      state: state,
      provider: provider,
      credentials: credentials,
    );
  }

  Future<({bool claimed, ExternalAuthCallbackResult? result})> _prepareCallback(
    Session session, {
    required String state,
    required String provider,
  }) async {
    try {
      await _rateLimiter.enforce(
        session,
        action: AuthRateLimitAction.externalAuthCallback,
        credential: state,
      );
    } on AccountAuthException catch (error) {
      if (error.code != 'rate_limited') rethrow;
      return (
        claimed: false,
        result: _failure(
          'Too many sign-in attempts',
          'Please wait and try again.',
        ),
      );
    }

    final claim = await _claimCallback(session, state, provider);
    return switch (claim) {
      _ExternalCallbackClaim.claimed => (claimed: true, result: null),
      _ExternalCallbackClaim.completed => (
        claimed: false,
        result: _success(provider),
      ),
      _ExternalCallbackClaim.expired => (
        claimed: false,
        result: _failure(
          '${_providerLabel(provider)} sign-in expired',
          'Please return to Age of New Worlds and try again.',
        ),
      ),
      _ExternalCallbackClaim.rejected => (
        claimed: false,
        result: _failure(
          '${_providerLabel(provider)} sign-in failed',
          'The authentication request could not be completed.',
        ),
      ),
    };
  }

  Future<ExternalAuthCallbackResult> _authenticateClaimedCallback(
    Session session, {
    required String state,
    required String provider,
    required Map<String, String> credentials,
  }) async {
    try {
      final auth = await _authenticator(session, provider, credentials);
      final committed = await _commitAuth(session, state, auth);
      if (!committed) {
        return _failure(
          '${_providerLabel(provider)} sign-in failed',
          'The authentication request could not be completed.',
        );
      }
      return _success(provider);
    } catch (error, stackTrace) {
      session.log(
        '${_providerLabel(provider)} desktop authentication failed.',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      await _failByState(session, state, 'authentication_failed');
      return _failure(
        '${_providerLabel(provider)} sign-in failed',
        '${_providerLabel(provider)} could not validate this sign-in response.',
      );
    }
  }

  Future<_ExternalCallbackClaim> _claimCallback(
    Session session,
    String state,
    String provider,
  ) {
    return session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.state.equals(state),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null || request.provider != provider) {
        return _ExternalCallbackClaim.rejected;
      }
      if (request.status == _statusCompleted ||
          request.status == _statusConsumed) {
        return _ExternalCallbackClaim.completed;
      }
      if (request.status != _statusPending) {
        return _ExternalCallbackClaim.rejected;
      }
      final now = DateTime.now().toUtc();
      if (request.expiresAt.isBefore(now)) {
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired, error: 'expired'),
          transaction: transaction,
        );
        return _ExternalCallbackClaim.expired;
      }
      await ExternalAuthRequest.db.updateRow(
        session,
        request.copyWith(status: _statusProcessing),
        transaction: transaction,
      );
      return _ExternalCallbackClaim.claimed;
    });
  }

  Future<bool> _commitAuth(
    Session session,
    String state,
    auth_core.AuthSuccess auth,
  ) {
    return session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.state.equals(state),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null || request.status != _statusProcessing) return false;
      final now = DateTime.now().toUtc();
      if (request.expiresAt.isBefore(now)) {
        await ExternalAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired, error: 'expired'),
          transaction: transaction,
        );
        return false;
      }
      await ExternalAuthRequest.db.updateRow(
        session,
        request.copyWith(
          status: _statusCompleted,
          codeVerifier: null,
          authStrategy: auth.authStrategy,
          token: auth.token,
          tokenExpiresAt: auth.tokenExpiresAt,
          refreshToken: auth.refreshToken,
          authUserId: auth.authUserId,
          scopeNames: auth.scopeNames.toList(growable: false),
          completedAt: now,
        ),
        transaction: transaction,
      );
      return true;
    });
  }

  Future<void> _failByState(Session session, String state, String error) async {
    await session.db.transaction((transaction) async {
      final request = await ExternalAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.state.equals(state),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null ||
          (request.status != _statusPending &&
              request.status != _statusProcessing)) {
        return;
      }
      await ExternalAuthRequest.db.updateRow(
        session,
        request.copyWith(
          status: _statusFailed,
          codeVerifier: null,
          error: error,
        ),
        transaction: transaction,
      );
    });
  }

  Future<ExternalAuthRequest?> _requestForState(Session session, String state) {
    return ExternalAuthRequest.db.findFirstRow(
      session,
      where: (table) => table.state.equals(state),
    );
  }

  static ExternalAuthProviderConfiguration _defaultConfiguration(
    String provider,
  ) {
    if (provider == appleProvider) {
      final config = auth_core.AuthServices.instance.appleIdp.config;
      return (
        clientId: config.serviceIdentifier,
        clientSecret: null,
        redirectUri: config.redirectUri,
      );
    }
    if (provider == googleProvider) {
      final config = auth_core.AuthServices.instance.googleIdp.config;
      final configuredRedirect = Serverpod.instance.getPassword(
        'googleDesktopRedirectUri',
      );
      final redirectUri = configuredRedirect?.trim().isNotEmpty == true
          ? configuredRedirect!.trim()
          : _publicWebUri(googleCallbackPath).toString();
      if (!config.clientSecret.redirectUris.contains(redirectUri)) {
        throw StateError(
          'Google desktop redirect URI is not present in googleClientSecret: '
          '$redirectUri',
        );
      }
      return (
        clientId: config.clientSecret.clientId,
        clientSecret: config.clientSecret.clientSecret,
        redirectUri: redirectUri,
      );
    }
    throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
  }

  static Future<auth_core.AuthSuccess> _defaultAuthenticator(
    Session session,
    String provider,
    Map<String, String> credentials,
  ) {
    if (provider == appleProvider) {
      return auth_core.AuthServices.instance.appleIdp.login(
        session,
        identityToken: credentials['identityToken']!,
        authorizationCode: credentials['authorizationCode']!,
        isNativeApplePlatformSignIn: false,
        firstName: credentials['firstName'],
        lastName: credentials['lastName'],
      );
    }
    if (provider == googleProvider) {
      return auth_core.AuthServices.instance.googleIdp.login(
        session,
        idToken: credentials['idToken']!,
        accessToken: credentials['accessToken'],
      );
    }
    throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
  }

  static Future<Map<String, dynamic>> _defaultTokenExchange(
    Uri uri,
    Map<String, String> body,
  ) async {
    final response = await http.post(uri, body: body);
    if (response.statusCode != 200) {
      throw StateError('OAuth token exchange failed (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid OAuth token response.');
    }
    return decoded;
  }

  static Uri _appleAuthorizationUri(
    ExternalAuthProviderConfiguration configuration,
    String state,
  ) {
    return Uri.https('appleid.apple.com', '/auth/authorize', {
      'client_id': configuration.clientId,
      'redirect_uri': configuration.redirectUri,
      'response_type': 'code id_token',
      'response_mode': 'form_post',
      'scope': 'name email',
      'state': state,
    });
  }

  static Uri _googleAuthorizationUri(
    ExternalAuthProviderConfiguration configuration,
    String state,
    String codeVerifier,
  ) {
    final challenge = base64UrlEncode(
      sha256.convert(ascii.encode(codeVerifier)).bytes,
    ).replaceAll('=', '');
    return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': configuration.clientId,
      'redirect_uri': configuration.redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
    });
  }

  static ({String? firstName, String? lastName}) _parseAppleName(
    String? serializedUser,
  ) {
    if (serializedUser == null || serializedUser.isEmpty) {
      return (firstName: null, lastName: null);
    }
    try {
      final user = jsonDecode(serializedUser);
      if (user is! Map<String, dynamic>) {
        return (firstName: null, lastName: null);
      }
      final name = user['name'];
      if (name is! Map<String, dynamic>) {
        return (firstName: null, lastName: null);
      }
      return (
        firstName: name['firstName'] as String?,
        lastName: name['lastName'] as String?,
      );
    } catch (_) {
      return (firstName: null, lastName: null);
    }
  }

  static ExternalAuthCallbackResult _success(String provider) => (
    success: true,
    title: '${_providerLabel(provider)} sign-in complete',
    message: 'You can return to Age of New Worlds.',
  );

  static ExternalAuthCallbackResult _failure(String title, String message) =>
      (success: false, title: title, message: message);

  static String _providerLabel(String provider) => switch (provider) {
    appleProvider => 'Apple',
    googleProvider => 'Google',
    _ => 'External',
  };

  static String _safeProviderError(String value) {
    return RegExp(r'^[a-zA-Z0-9_.-]{1,64}$').hasMatch(value)
        ? value
        : 'provider_error';
  }

  static bool _isValidToken(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{40,128}$').hasMatch(value);

  static String _secureToken(int byteCount) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteCount, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Uri _publicWebUri(String path) {
    final config =
        Serverpod.instance.config.webServer ??
        Serverpod.instance.config.apiServer;
    return Uri(
      scheme: config.publicScheme,
      host: config.publicHost,
      port: _defaultPort(config.publicScheme) == config.publicPort
          ? null
          : config.publicPort,
      path: path,
    );
  }

  static int _defaultPort(String scheme) => scheme == 'https' ? 443 : 80;
}
