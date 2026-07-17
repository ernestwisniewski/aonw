import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Calculates domination progress from persistence-free domain collections.
final class DominationProgressResolver {
  const DominationProgressResolver();

  DominationProgressSnapshot snapshot({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapCatalog,
    required VictoryRules victoryRules,
    Map<String, int> holdTurnsByPlayerId = const {},
  }) {
    final players = _cleanPlayerIds(playerIds);
    final validHexes = _validDominationHexes(mapCatalog);
    final controlledByPlayer = {
      for (final playerId in players) playerId: <CityHex>{},
    };
    for (final city in cities) {
      final controlledHexes = controlledByPlayer[city.ownerPlayerId];
      if (controlledHexes == null) continue;
      for (final hex in city.territoryHexes) {
        if (validHexes.contains(hex)) controlledHexes.add(hex);
      }
    }
    return _snapshot(
      players: players,
      controlledByPlayer: controlledByPlayer,
      validTileCount: validHexes.length,
      victoryRules: victoryRules,
      holdTurnsByPlayerId: holdTurnsByPlayerId,
    );
  }

  Map<String, int> advanceHoldTurns({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapCatalog,
    required VictoryRules victoryRules,
    Map<String, int> previousHoldTurnsByPlayerId = const {},
  }) {
    if (!victoryRules.dominationEnabled) return const {};
    final progress = snapshot(
      playerIds: playerIds,
      cities: cities,
      mapCatalog: mapCatalog,
      victoryRules: victoryRules,
      holdTurnsByPlayerId: previousHoldTurnsByPlayerId,
    );
    return Map.unmodifiable({
      for (final entry in progress.entries)
        if (entry.atThreshold) entry.playerId: entry.holdTurns + 1,
    });
  }

  List<DominationThresholdReachedEvent> thresholdReachedEvents({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapCatalog,
    required VictoryRules victoryRules,
    required Map<String, int> previousHoldTurnsByPlayerId,
    required Map<String, int> nextHoldTurnsByPlayerId,
  }) {
    if (!victoryRules.dominationEnabled) return const [];
    final progress = snapshot(
      playerIds: playerIds,
      cities: cities,
      mapCatalog: mapCatalog,
      victoryRules: victoryRules,
      holdTurnsByPlayerId: nextHoldTurnsByPlayerId,
    );
    return List.unmodifiable([
      for (final entry in progress.entries)
        if (_startedHolding(
          entry,
          previousHoldTurnsByPlayerId,
          nextHoldTurnsByPlayerId,
        ))
          DominationThresholdReachedEvent(
            playerId: entry.playerId,
            controlPercent: entry.controlPercent,
            requiredControlPercent: entry.requiredControlPercent,
            holdTurns: entry.holdTurns,
            requiredHoldTurns: entry.requiredHoldTurns,
          ),
    ]);
  }

  DominationProgressSnapshot _snapshot({
    required List<String> players,
    required Map<String, Set<CityHex>> controlledByPlayer,
    required int validTileCount,
    required VictoryRules victoryRules,
    required Map<String, int> holdTurnsByPlayerId,
  }) {
    return DominationProgressSnapshot(
      validTileCount: validTileCount,
      entries: [
        for (final playerId in players)
          _entry(
            playerId: playerId,
            controlledTileCount: controlledByPlayer[playerId]!.length,
            validTileCount: validTileCount,
            victoryRules: victoryRules,
            holdTurns: holdTurnsByPlayerId[playerId] ?? 0,
          ),
      ],
    );
  }

  DominationProgressEntry _entry({
    required String playerId,
    required int controlledTileCount,
    required int validTileCount,
    required VictoryRules victoryRules,
    required int holdTurns,
  }) {
    final controlPercent = validTileCount == 0
        ? 0.0
        : controlledTileCount * 100 / validTileCount;
    return DominationProgressEntry(
      playerId: playerId,
      controlledTileCount: controlledTileCount,
      validTileCount: validTileCount,
      controlPercent: controlPercent,
      requiredControlPercent: victoryRules.dominationControlPercent,
      holdTurns: holdTurns,
      requiredHoldTurns: victoryRules.dominationHoldTurns,
    );
  }

  List<String> _cleanPlayerIds(Iterable<String> playerIds) {
    return {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    }.toList()..sort();
  }

  Set<CityHex> _validDominationHexes(MapTileCatalog mapCatalog) {
    return {
      for (final tile in mapCatalog.tileViews)
        if (UnitMovementCostRules.costToEnterTile(tile).passable)
          CityHex(col: tile.col, row: tile.row),
    };
  }
}

bool _startedHolding(
  DominationProgressEntry entry,
  Map<String, int> previousHoldTurnsByPlayerId,
  Map<String, int> nextHoldTurnsByPlayerId,
) {
  final previousHold = previousHoldTurnsByPlayerId[entry.playerId] ?? 0;
  final nextHold = nextHoldTurnsByPlayerId[entry.playerId] ?? 0;
  return entry.atThreshold && previousHold <= 0 && nextHold > 0;
}
