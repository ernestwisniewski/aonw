import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/server_command_dispatcher.dart';
import 'package:aonw_server/src/multiplayer/server_command_outcome_projector.dart';
import 'package:aonw_server/src/multiplayer/server_map_cache.dart';
import 'package:aonw_server/src/multiplayer/server_turn_policy.dart';

export 'server_command_outcome_projector.dart' show ServerCommandReduction;

const defaultMultiplayerTurnTimeout = Duration(seconds: 115);
const _matchLifecycleStateAdapter = MatchLifecycleStateAdapter();

DomainCommand? _decodePlayerDomainCommand(Map<String, dynamic> rawCommand) {
  try {
    return DomainCommandCodec.fromJson(rawCommand);
  } on ArgumentError {
    return null;
  }
}

/// Validates wire commands and coordinates reducer capabilities.
class ServerCommandReducer {
  ServerCommandReducer({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
    Duration turnTimeout = defaultMultiplayerTurnTimeout,
  }) {
    _mapCache = ServerMapCache(mapCatalog);
    _turnPolicy = ServerTurnPolicy(turnTimeout);
    _dispatcher = ServerCommandDispatcher(turnPolicy: _turnPolicy);
  }

  late final ServerMapCache _mapCache;
  late final ServerTurnPolicy _turnPolicy;
  late final ServerCommandDispatcher _dispatcher;
  final ServerCommandOutcomeProjector _outcomes =
      const ServerCommandOutcomeProjector();

  bool hasTurnTimedOut({
    required CanonicalGameSnapshot snapshot,
    required DateTime now,
  }) => _turnPolicy.hasTimedOut(snapshot, now);

  Future<ServerCommandReduction> reduce({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required WireCommand wireCommand,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    final rejection = _validateCommand(
      match: match,
      snapshot: snapshot,
      wireCommand: wireCommand,
      actorPlayerId: actorPlayerId,
    );
    if (rejection != null) return _outcomes.reject(rejection);

    final command = _decodePlayerDomainCommand(wireCommand.command)!;
    final loadedMap = await _mapCache.load(snapshot.metadata.world.name);
    final application = _dispatcher.apply(
      snapshot: snapshot,
      match: match,
      command: command,
      commandTick: wireCommand.tick,
      actorPlayerId: actorPlayerId,
      now: now.toUtc(),
      mapView: loadedMap.mapView,
      ruleset: _ruleset(snapshot),
    );
    if (!application.accepted) {
      return _outcomes.reject(application.reason ?? 'command_rejected');
    }
    return _outcomes.accepted(
      match: match,
      application: application.withSnapshot(
        _withSavedAt(application.snapshot, now.toUtc()),
      ),
      mapView: loadedMap.mapView,
    );
  }

  Future<ServerCommandReduction> reduceTimedOutTurn({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    final rejection = _validateTimedOutTurn(
      match: match,
      snapshot: snapshot,
      actorPlayerId: actorPlayerId,
      now: now,
    );
    if (rejection != null) return _outcomes.reject(rejection);

    final nowUtc = now.toUtc();
    final loadedMap = await _mapCache.load(snapshot.metadata.world.name);
    final application = _dispatcher.finalizeTimedOutTurn(
      snapshot: snapshot,
      actorPlayerId: actorPlayerId,
      now: nowUtc,
      mapView: loadedMap.mapView,
      ruleset: _ruleset(snapshot),
    );
    return _outcomes.accepted(
      match: match,
      application: application.withSnapshot(
        _withSavedAt(application.snapshot, nowUtc),
      ),
      mapView: loadedMap.mapView,
    );
  }

  String? _validateCommand({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required WireCommand wireCommand,
    required String actorPlayerId,
  }) {
    if (!_matchLifecycleStateAdapter.isRunningWireMatch(match)) {
      return 'match_not_running';
    }
    final command = _decodePlayerDomainCommand(wireCommand.command);
    if (command == null) return 'invalid_command_payload';
    if (wireCommand.turn != null && wireCommand.turn != snapshot.domain.turn) {
      return 'stale_turn';
    }
    if (snapshot.domain.isKicked(actorPlayerId)) return 'player_eliminated';
    if (command is! SubmitTurnCommand &&
        command is! EndTurnCommand &&
        snapshot.domain.hasSubmitted(actorPlayerId)) {
      return 'player_already_submitted';
    }
    return null;
  }

  String? _validateTimedOutTurn({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required String actorPlayerId,
    required DateTime now,
  }) {
    if (!_matchLifecycleStateAdapter.isRunningWireMatch(match)) {
      return 'match_not_running';
    }
    if (!_turnPolicy.hasTimedOut(snapshot, now.toUtc())) {
      return 'turn_not_timed_out';
    }
    if (snapshot.domain.isKicked(actorPlayerId)) return 'player_eliminated';
    final playerIds = _turnPolicy.playerIds(snapshot);
    if (playerIds.isEmpty || !playerIds.contains(actorPlayerId)) {
      return 'turn_player_not_active';
    }
    return null;
  }

  GameRuleset _ruleset(CanonicalGameSnapshot snapshot) {
    return GameRuleset.standard().copyWith(
      paceBalance: snapshot.domain.matchRules.paceBalance,
    );
  }
}

CanonicalGameSnapshot _withSavedAt(
  CanonicalGameSnapshot snapshot,
  DateTime savedAtUtc,
) {
  if (snapshot.metadata.savedAtUtc == savedAtUtc) return snapshot;
  return snapshot.copyWith(
    metadata: snapshot.metadata.copyWith(savedAtUtc: savedAtUtc),
  );
}
