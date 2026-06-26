import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lobby_match_action_coordinator.freezed.dart';

typedef LobbyMatchSessionEnsurer = Future<NetworkSession> Function();
typedef LobbyMatchMapValidator = Future<MapValidationResult> Function();
typedef LobbyQuickplayRequester =
    Future<WireMatch> Function({
      required AuthToken token,
      required QuickplayMatchRequest request,
    });
typedef LobbyPrivateMatchCreator =
    Future<WireMatch> Function({
      required AuthToken token,
      required CreatePrivateMatchRequest request,
    });
typedef LobbyPrivateMatchJoiner =
    Future<WireMatch> Function({
      required AuthToken token,
      required JoinPrivateMatchRequest request,
    });
typedef LobbyMatchStarter =
    Future<WireMatch> Function({
      required AuthToken token,
      required String matchId,
    });
typedef LobbyMatchLoader =
    Future<WireMatch> Function({
      required AuthToken token,
      required String matchId,
    });
typedef LobbyMatchLeaver =
    Future<void> Function({required AuthToken token, required String matchId});
typedef LobbyMatchRememberer =
    void Function({required NetworkSession session, required WireMatch match});
typedef LobbyMatchWatcher =
    void Function({required NetworkSession session, required WireMatch match});
typedef LobbyMatchClearer = void Function(NetworkSession session);
typedef LobbyMatchEnterer =
    void Function({required NetworkSession session, required WireMatch match});
typedef LobbyAutoStartScheduler = void Function(WireMatch match);
typedef LobbyUpdateStopper = void Function();
typedef LobbyContinuation = bool Function();

@freezed
abstract class LobbyMatchActionConfig with _$LobbyMatchActionConfig {
  const LobbyMatchActionConfig._();

  const factory LobbyMatchActionConfig({
    required String mapName,
    required String displayName,
    required PlayerCountry country,
    required String mapNotReadyMessage,
    @Default(MatchRules.standard) MatchRules matchRules,
  }) = _LobbyMatchActionConfig;
}

final class LobbyMatchActionCoordinator {
  final LobbyMatchSessionEnsurer ensureSession;
  final LobbyMatchMapValidator validateMap;
  final LobbyQuickplayRequester quickplay;
  final LobbyPrivateMatchCreator createPrivateMatch;
  final LobbyPrivateMatchJoiner joinPrivateMatch;
  final LobbyMatchStarter startMatch;
  final LobbyMatchLoader loadMatch;
  final LobbyMatchLeaver leaveMatch;
  final LobbyMatchRememberer rememberMatch;
  final LobbyMatchWatcher watchMatch;
  final LobbyMatchClearer clearMatch;
  final LobbyMatchEnterer enterMatch;
  final LobbyAutoStartScheduler scheduleAutoStartRefresh;
  final LobbyUpdateStopper stopLobbyUpdates;
  final LobbyContinuation canContinue;

  const LobbyMatchActionCoordinator({
    required this.ensureSession,
    required this.validateMap,
    required this.quickplay,
    required this.createPrivateMatch,
    required this.joinPrivateMatch,
    required this.startMatch,
    required this.loadMatch,
    required this.leaveMatch,
    required this.rememberMatch,
    required this.watchMatch,
    required this.clearMatch,
    required this.enterMatch,
    required this.scheduleAutoStartRefresh,
    required this.stopLobbyUpdates,
    required this.canContinue,
  });

  Future<void> joinQuickplay(LobbyMatchActionConfig config) async {
    await _validateMapOrThrow(config.mapNotReadyMessage);
    final session = await ensureSession();
    final match = await quickplay(
      token: session.token,
      request: QuickplayMatchRequest(
        mapName: config.mapName,
        displayName: config.displayName,
        country: config.country,
        matchRules: config.matchRules,
      ),
    );
    _rememberAndWatch(session: session, match: match);
    if (!canContinue()) return;
    _enterOrSchedule(session: session, match: match);
  }

  Future<void> cancelQuickplay({required WireMatch? activeMatch}) async {
    stopLobbyUpdates();
    final session = await ensureSession();
    if (activeMatch != null && activeMatch.state == 'open') {
      await leaveMatch(token: session.token, matchId: activeMatch.id);
    }
    clearMatch(session);
  }

  Future<void> createPrivate(LobbyMatchActionConfig config) async {
    await _validateMapOrThrow(config.mapNotReadyMessage);
    final session = await ensureSession();
    final match = await createPrivateMatch(
      token: session.token,
      request: CreatePrivateMatchRequest(
        mapName: config.mapName,
        displayName: config.displayName,
        country: config.country,
        matchRules: config.matchRules,
      ),
    );
    _rememberAndWatch(session: session, match: match);
  }

  Future<void> joinPrivate({
    required String inviteCode,
    required String inviteCodeRequiredMessage,
    required LobbyMatchActionConfig config,
  }) async {
    final code = inviteCode.trim();
    if (code.isEmpty) throw StateError(inviteCodeRequiredMessage);
    final session = await ensureSession();
    final match = await joinPrivateMatch(
      token: session.token,
      request: JoinPrivateMatchRequest(
        inviteCode: code,
        displayName: config.displayName,
        country: config.country,
      ),
    );
    _rememberAndWatch(session: session, match: match);
  }

  Future<void> startPrivate({required WireMatch? activeMatch}) async {
    final match = activeMatch;
    if (match == null || match.state != 'open') return;
    final session = await ensureSession();
    final started = await startMatch(token: session.token, matchId: match.id);
    rememberMatch(session: session, match: started);
    if (!canContinue()) return;
    if (LobbyMatchStatusRules.canEnter(started)) {
      stopLobbyUpdates();
      enterMatch(session: session, match: started);
    }
  }

  Future<void> refreshActiveMatch({required String? matchId}) async {
    if (matchId == null) return;
    final session = await ensureSession();
    final match = await loadMatch(token: session.token, matchId: matchId);
    rememberMatch(session: session, match: match);
    if (!canContinue()) return;
    _enterOrSchedule(session: session, match: match);
  }

  Future<void> _validateMapOrThrow(String message) async {
    final validation = await validateMap();
    if (validation.errors.isNotEmpty) throw StateError(message);
  }

  void _rememberAndWatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    rememberMatch(session: session, match: match);
    watchMatch(session: session, match: match);
  }

  void _enterOrSchedule({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (LobbyMatchStatusRules.canEnter(match)) {
      stopLobbyUpdates();
      enterMatch(session: session, match: match);
      return;
    }
    scheduleAutoStartRefresh(match);
  }
}
