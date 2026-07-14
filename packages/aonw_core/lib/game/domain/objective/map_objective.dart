import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';

export 'package:aonw_core/domain/map_objective_definition.dart'
    show MapObjectiveDefinition, MapObjectiveType;

class MapObjectiveHoldState {
  final String objectiveId;
  final String playerId;
  final int holdTurns;

  const MapObjectiveHoldState({
    required this.objectiveId,
    required this.playerId,
    required this.holdTurns,
  });

  factory MapObjectiveHoldState.fromJson(Map<String, dynamic> json) {
    return MapObjectiveHoldState(
      objectiveId: json['objectiveId'] as String,
      playerId: json['playerId'] as String,
      holdTurns: (json['holdTurns'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'objectiveId': objectiveId,
    'playerId': playerId,
    'holdTurns': holdTurns,
  };

  @override
  bool operator ==(Object other) {
    return other is MapObjectiveHoldState &&
        other.objectiveId == objectiveId &&
        other.playerId == playerId &&
        other.holdTurns == holdTurns;
  }

  @override
  int get hashCode => Object.hash(objectiveId, playerId, holdTurns);
}

class MapObjectiveProgress {
  final MapObjectiveDefinition definition;
  final String? controllingPlayerId;
  final Set<String> contestingPlayerIds;
  final int holdTurns;

  const MapObjectiveProgress({
    required this.definition,
    required this.controllingPlayerId,
    this.contestingPlayerIds = const {},
    required this.holdTurns,
  });

  bool get controlled => controllingPlayerId != null;
  bool get contested => contestingPlayerIds.length > 1;
  bool get completed => controlled && holdTurns >= definition.requiredHoldTurns;

  int get remainingHoldTurns {
    if (!controlled) return definition.requiredHoldTurns;
    final remaining = definition.requiredHoldTurns - holdTurns;
    return remaining < 0 ? 0 : remaining;
  }
}

class MapObjectiveSnapshot {
  final List<MapObjectiveProgress> entries;

  const MapObjectiveSnapshot({required this.entries});

  MapObjectiveProgress? entryFor(String objectiveId) {
    for (final entry in entries) {
      if (entry.definition.id == objectiveId) return entry;
    }
    return null;
  }

  Map<String, int> victoryPointsByPlayerId() {
    final totals = <String, int>{};
    for (final entry in entries) {
      final playerId = entry.controllingPlayerId;
      if (playerId == null || !entry.completed) continue;
      totals[playerId] =
          (totals[playerId] ?? 0) + entry.definition.victoryPoints;
    }
    return Map.unmodifiable(totals);
  }

  Map<String, int> goldPerTurnByPlayerId() {
    final totals = <String, int>{};
    for (final entry in entries) {
      final playerId = entry.controllingPlayerId;
      if (playerId == null || !entry.completed) continue;
      totals[playerId] = (totals[playerId] ?? 0) + entry.definition.goldPerTurn;
    }
    return Map.unmodifiable(totals);
  }
}

abstract final class MapObjectiveRules {
  static MapObjectiveSnapshot snapshot({
    required Iterable<MapObjectiveDefinition> objectives,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    Map<String, MapObjectiveHoldState> holdStatesByObjectiveId = const {},
  }) {
    final entries = [
      for (final objective in objectives)
        _progressFor(
          objective: objective,
          cities: cities,
          units: units,
          previous: holdStatesByObjectiveId[objective.id],
        ),
    ]..sort((a, b) => a.definition.id.compareTo(b.definition.id));
    return MapObjectiveSnapshot(entries: List.unmodifiable(entries));
  }

  static Map<String, MapObjectiveHoldState> advanceHoldStates({
    required Iterable<MapObjectiveDefinition> objectives,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    Map<String, MapObjectiveHoldState> previousHoldStatesByObjectiveId =
        const {},
  }) {
    final next = <String, MapObjectiveHoldState>{};
    for (final objective in objectives) {
      final controller = _controllerFor(
        objective.hex,
        cities: cities,
        units: units,
      );
      if (controller == null) continue;
      final previous = previousHoldStatesByObjectiveId[objective.id];
      next[objective.id] = MapObjectiveHoldState(
        objectiveId: objective.id,
        playerId: controller,
        holdTurns: previous?.playerId == controller
            ? previous!.holdTurns + 1
            : 1,
      );
    }
    return Map.unmodifiable(next);
  }

  static MapObjectiveProgress _progressFor({
    required MapObjectiveDefinition objective,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required MapObjectiveHoldState? previous,
  }) {
    final contestingPlayerIds = _contestingPlayersFor(
      objective.hex,
      cities: cities,
      units: units,
    );
    final controller = contestingPlayerIds.length == 1
        ? contestingPlayerIds.single
        : null;
    return MapObjectiveProgress(
      definition: objective,
      controllingPlayerId: controller,
      contestingPlayerIds: contestingPlayerIds,
      holdTurns: previous != null && previous.playerId == controller
          ? previous.holdTurns
          : 0,
    );
  }

  static String? _controllerFor(
    HexCoord hex, {
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
  }) {
    final players = _contestingPlayersFor(hex, cities: cities, units: units);
    return players.length == 1 ? players.single : null;
  }

  static Set<String> _contestingPlayersFor(
    HexCoord hex, {
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
  }) {
    final players = <String>{};
    for (final city in cities) {
      if (city.controlsTile(hex.col, hex.row)) {
        players.add(city.ownerPlayerId);
      }
    }
    for (final unit in units) {
      if (unit.occupies(hex.col, hex.row)) players.add(unit.ownerPlayerId);
    }
    return Set.unmodifiable(players);
  }
}
