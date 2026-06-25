import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;

import '../generated/protocol.dart';

class SteamAuthService {
  static const authMethod = 'steam';
  static const callbackPath = '/auth/steam/callback';

  static const _statusPending = 'pending';
  static const _statusCompleted = 'completed';
  static const _statusConsumed = 'consumed';
  static const _statusFailed = 'failed';
  static const _statusExpired = 'expired';
  static const _statusAuthenticated = 'authenticated';

  static final _steamOpenIdEndpoint = Uri.parse(
    'https://steamcommunity.com/openid/login',
  );
  static final _steamClaimedIdPattern = RegExp(
    r'^https://steamcommunity\.com/openid/id/(\d{17})$',
  );

  Future<SteamAuthStart> start(Session session) async {
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(const Duration(minutes: 10));
    final requestId = _secureRequestId();
    final returnTo = _publicWebUri(callbackPath, {'requestId': requestId});
    final realm = _publicWebOrigin();
    final authUrl = _steamOpenIdEndpoint.replace(
      queryParameters: {
        'openid.ns': 'http://specs.openid.net/auth/2.0',
        'openid.mode': 'checkid_setup',
        'openid.return_to': returnTo.toString(),
        'openid.realm': realm,
        'openid.identity': 'http://specs.openid.net/auth/2.0/identifier_select',
        'openid.claimed_id':
            'http://specs.openid.net/auth/2.0/identifier_select',
      },
    );

    await SteamAuthRequest.db.insertRow(
      session,
      SteamAuthRequest(
        requestId: requestId,
        status: _statusPending,
        createdAt: now,
        expiresAt: expiresAt,
      ),
    );

    return SteamAuthStart(
      requestId: requestId,
      authUrl: authUrl.toString(),
      expiresAt: expiresAt,
    );
  }

  Future<SteamAuthPollResult> poll(
    Session session, {
    required String requestId,
  }) {
    final now = DateTime.now().toUtc();
    return session.db.transaction((transaction) async {
      final request = await SteamAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.requestId.equals(requestId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null) {
        return SteamAuthPollResult(status: _statusFailed, error: 'not_found');
      }

      if (request.expiresAt.isBefore(now) && request.consumedAt == null) {
        await SteamAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusExpired),
          transaction: transaction,
        );
        return SteamAuthPollResult(
          status: _statusExpired,
          error: request.error,
        );
      }

      if (request.status == _statusCompleted &&
          request.authUserId != null &&
          request.consumedAt == null) {
        final auth = await auth_core.AuthServices.instance.tokenManager
            .issueToken(
              session,
              authUserId: request.authUserId!,
              method: authMethod,
              transaction: transaction,
            );
        await SteamAuthRequest.db.updateRow(
          session,
          request.copyWith(status: _statusConsumed, consumedAt: now),
          transaction: transaction,
        );
        return SteamAuthPollResult(status: _statusAuthenticated, auth: auth);
      }

      return SteamAuthPollResult(status: request.status, error: request.error);
    });
  }

  Future<({bool success, String title, String message})> handleCallback(
    Session session,
    Uri uri,
  ) async {
    final query = uri.queryParameters;
    final requestId = query['requestId'];
    if (requestId == null || requestId.isEmpty) {
      return (
        success: false,
        title: 'Steam sign-in failed',
        message: 'Missing authentication request id.',
      );
    }

    final request = await SteamAuthRequest.db.findFirstRow(
      session,
      where: (table) => table.requestId.equals(requestId),
    );
    if (request == null) {
      return (
        success: false,
        title: 'Steam sign-in failed',
        message: 'The authentication request was not found.',
      );
    }
    if (request.status != _statusPending) {
      return (
        success:
            request.status == _statusCompleted ||
            request.status == _statusConsumed,
        title: 'Steam sign-in complete',
        message: 'You can return to Age of New Worlds.',
      );
    }
    if (request.expiresAt.isBefore(DateTime.now().toUtc())) {
      await _failRequest(session, requestId, 'expired');
      return (
        success: false,
        title: 'Steam sign-in expired',
        message: 'Please return to the game and try again.',
      );
    }
    if (query['openid.mode'] != 'id_res') {
      await _failRequest(session, requestId, 'cancelled');
      return (
        success: false,
        title: 'Steam sign-in cancelled',
        message: 'Please return to the game and try again.',
      );
    }
    if (_requestIdFromReturnTo(query['openid.return_to']) != requestId) {
      await _failRequest(session, requestId, 'invalid_return_to');
      return (
        success: false,
        title: 'Steam sign-in failed',
        message: 'Steam returned an invalid sign-in target.',
      );
    }

    final steamId =
        _extractSteamId(query['openid.claimed_id']) ??
        _extractSteamId(query['openid.identity']);
    if (steamId == null) {
      await _failRequest(session, requestId, 'invalid_steam_id');
      return (
        success: false,
        title: 'Steam sign-in failed',
        message: 'Steam did not return a valid Steam ID.',
      );
    }

    final valid = await _validateOpenIdResponse(query);
    if (!valid) {
      await _failRequest(session, requestId, 'invalid_signature');
      return (
        success: false,
        title: 'Steam sign-in failed',
        message: 'Steam could not validate this sign-in response.',
      );
    }

    await session.db.transaction((transaction) async {
      final lockedRequest = await SteamAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.requestId.equals(requestId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (lockedRequest == null ||
          lockedRequest.status != _statusPending ||
          lockedRequest.expiresAt.isBefore(DateTime.now().toUtc())) {
        return;
      }

      final authUserId = await _upsertSteamAccount(
        session,
        steamId: steamId,
        transaction: transaction,
      );
      await SteamAuthRequest.db.updateRow(
        session,
        lockedRequest.copyWith(
          status: _statusCompleted,
          authUserId: authUserId,
          steamId: steamId,
          completedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });

    return (
      success: true,
      title: 'Steam sign-in complete',
      message: 'You can return to Age of New Worlds.',
    );
  }

  Future<void> _failRequest(
    Session session,
    String requestId,
    String error,
  ) async {
    await session.db.transaction((transaction) async {
      final request = await SteamAuthRequest.db.findFirstRow(
        session,
        where: (table) => table.requestId.equals(requestId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (request == null || request.status != _statusPending) return;
      await SteamAuthRequest.db.updateRow(
        session,
        request.copyWith(status: _statusFailed, error: error),
        transaction: transaction,
      );
    });
  }

  Future<UuidValue> _upsertSteamAccount(
    Session session, {
    required String steamId,
    required Transaction transaction,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await SteamAccount.db.findFirstRow(
      session,
      where: (table) => table.steamId.equals(steamId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
      lockBehavior: LockBehavior.wait,
    );
    if (existing != null) {
      await SteamAccount.db.updateRow(
        session,
        existing.copyWith(lastSeenAt: now),
        transaction: transaction,
      );
      return existing.authUserId;
    }

    final authUser = await auth_core.AuthServices.instance.authUsers.create(
      session,
      transaction: transaction,
    );
    final profileName = _profileName(steamId);
    await auth_core.AuthServices.instance.userProfiles.createUserProfile(
      session,
      authUser.id,
      auth_core.UserProfileData(userName: profileName, fullName: profileName),
      transaction: transaction,
    );
    await SteamAccount.db.insertRow(
      session,
      SteamAccount(
        steamId: steamId,
        authUserId: authUser.id,
        createdAt: now,
        lastSeenAt: now,
      ),
      transaction: transaction,
    );
    return authUser.id;
  }

  Future<bool> _validateOpenIdResponse(Map<String, String> query) async {
    final params = <String, String>{};
    for (final entry in query.entries) {
      if (entry.key.startsWith('openid.')) params[entry.key] = entry.value;
    }
    params['openid.mode'] = 'check_authentication';

    final client = HttpClient();
    try {
      final request = await client.postUrl(_steamOpenIdEndpoint);
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      request.write(Uri(queryParameters: params).query);
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      return body.split('\n').any((line) => line.trim() == 'is_valid:true');
    } finally {
      client.close(force: true);
    }
  }

  String? _extractSteamId(String? claimedId) {
    if (claimedId == null) return null;
    return _steamClaimedIdPattern.firstMatch(claimedId)?.group(1);
  }

  String? _requestIdFromReturnTo(String? returnTo) {
    if (returnTo == null) return null;
    return Uri.tryParse(returnTo)?.queryParameters['requestId'];
  }

  String _profileName(String steamId) {
    final suffix = steamId.length > 4
        ? steamId.substring(steamId.length - 4)
        : steamId;
    return 'Steam $suffix';
  }

  Uri _publicWebUri(String path, Map<String, String> queryParameters) {
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
      queryParameters: queryParameters,
    );
  }

  String _publicWebOrigin() {
    final config =
        Serverpod.instance.config.webServer ??
        Serverpod.instance.config.apiServer;
    return Uri(
      scheme: config.publicScheme,
      host: config.publicHost,
      port: _defaultPort(config.publicScheme) == config.publicPort
          ? null
          : config.publicPort,
      path: '/',
    ).toString();
  }

  int _defaultPort(String scheme) => scheme == 'https' ? 443 : 80;

  String _secureRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
