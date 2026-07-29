import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class MctsOpponentViewIndex {
  final Map<String, List<GameUnit>> _unitsByOwner;
  final Map<String, List<GameCity>> _citiesByOwner;
  final Map<String, List<WorldArtifact>> _artifactsByOwner;
  final Map<String, List<FieldImprovement>> _improvementsByOwner;

  MctsOpponentViewIndex._({
    required Map<String, List<GameUnit>> unitsByOwner,
    required Map<String, List<GameCity>> citiesByOwner,
    required Map<String, List<WorldArtifact>> artifactsByOwner,
    required Map<String, List<FieldImprovement>> improvementsByOwner,
  }) : _unitsByOwner = _freezeListMap(unitsByOwner),
       _citiesByOwner = _freezeListMap(citiesByOwner),
       _artifactsByOwner = _freezeListMap(artifactsByOwner),
       _improvementsByOwner = _freezeListMap(improvementsByOwner);

  factory MctsOpponentViewIndex.fromState(PersistentGameState state) {
    final unitsByOwner = <String, List<GameUnit>>{};
    final unitOwnersById = <String, String>{};
    for (final unit in state.units) {
      (unitsByOwner[unit.ownerPlayerId] ??= []).add(unit);
      unitOwnersById[unit.id] = unit.ownerPlayerId;
    }

    final citiesByOwner = <String, List<GameCity>>{};
    final cityOwnersById = <String, String>{};
    for (final city in state.cities) {
      (citiesByOwner[city.ownerPlayerId] ??= []).add(city);
      cityOwnersById[city.id] = city.ownerPlayerId;
    }

    return MctsOpponentViewIndex._(
      unitsByOwner: unitsByOwner,
      citiesByOwner: citiesByOwner,
      artifactsByOwner: _buildArtifactsByOwner(
        artifacts: state.artifacts,
        unitOwnersById: unitOwnersById,
        cityOwnersById: cityOwnersById,
      ),
      improvementsByOwner: _buildImprovementsByOwner(
        improvements: state.fieldImprovements,
        cities: state.cities,
        cityOwnersById: cityOwnersById,
      ),
    );
  }

  List<String> knownPlayerIds(String forPlayerId) {
    final ids = {forPlayerId, ...opponentPlayerIds(forPlayerId)};
    return ids.toList()..sort();
  }

  List<String> opponentPlayerIds(String forPlayerId) {
    final ids = <String>{..._unitsByOwner.keys, ..._citiesByOwner.keys}
      ..remove(forPlayerId);
    return ids.toList()..sort();
  }

  GameView viewFor({
    required PersistentGameState state,
    required String opponentId,
    required int turn,
    required MapReadView mapData,
    required GameRuleset ruleset,
    CanonicalGameSnapshot? engineSnapshot,
  }) {
    return GameView(
      forPlayerId: opponentId,
      turn: turn,
      ownUnits: _unitsByOwner[opponentId] ?? const [],
      ownCities: _citiesByOwner[opponentId] ?? const [],
      ownGold: state.playerGold[opponentId] ?? 0,
      ownWarWeariness: state.playerWarWeariness[opponentId] ?? 0,
      ownStabilityNet: state.playerStabilityNet[opponentId] ?? 0,
      ownResearch: state.research.forPlayer(opponentId),
      ownImprovements: _improvementsByOwner[opponentId] ?? const [],
      artifacts: _artifactsByOwner[opponentId] ?? const [],
      diplomacy: state.runtimeState.diplomacy,
      visibleEnemyUnits: _indexedValuesExceptOwner(_unitsByOwner, opponentId),
      rememberedEnemyCities: _indexedValuesExceptOwner(
        _citiesByOwner,
        opponentId,
      ),
      visibility: const FogVisibilityQuery(
        playerId: '',
        state: FogOfWarState.empty,
      ),
      mapData: mapData,
      ruleset: ruleset,
      wonderRegistry: state.wonderRegistry,
      engineSnapshot: engineSnapshot,
    );
  }

  static Map<String, List<T>> _freezeListMap<T>(Map<String, List<T>> source) {
    return Map.unmodifiable(<String, List<T>>{
      for (final entry in source.entries)
        entry.key: List<T>.unmodifiable(entry.value),
    });
  }

  static Iterable<T> _indexedValuesExceptOwner<T>(
    Map<String, List<T>> valuesByOwner,
    String ownerId,
  ) {
    if (valuesByOwner.isEmpty) return const [];
    if (valuesByOwner.length == 1) {
      final entry = valuesByOwner.entries.single;
      return entry.key == ownerId ? const [] : entry.value;
    }
    if (valuesByOwner.length == 2 && valuesByOwner.containsKey(ownerId)) {
      for (final entry in valuesByOwner.entries) {
        if (entry.key != ownerId) return entry.value;
      }
      return const [];
    }
    return _indexedValuesExceptOwnerLazy(valuesByOwner, ownerId);
  }

  static Iterable<T> _indexedValuesExceptOwnerLazy<T>(
    Map<String, List<T>> valuesByOwner,
    String ownerId,
  ) sync* {
    for (final entry in valuesByOwner.entries) {
      if (entry.key != ownerId) yield* entry.value;
    }
  }

  static Map<String, List<FieldImprovement>> _buildImprovementsByOwner({
    required Iterable<FieldImprovement> improvements,
    required List<GameCity> cities,
    required Map<String, String> cityOwnersById,
  }) {
    final byOwner = <String, List<FieldImprovement>>{};
    for (final improvement in improvements) {
      final ownerIds = _improvementOwners(
        improvement,
        cities: cities,
        cityOwnersById: cityOwnersById,
      );
      for (final ownerId in ownerIds) {
        (byOwner[ownerId] ??= []).add(improvement);
      }
    }
    return byOwner;
  }

  static Map<String, List<WorldArtifact>> _buildArtifactsByOwner({
    required Iterable<WorldArtifact> artifacts,
    required Map<String, String> unitOwnersById,
    required Map<String, String> cityOwnersById,
  }) {
    final byOwner = <String, List<WorldArtifact>>{};
    for (final artifact in artifacts) {
      final location = artifact.location;
      final ownerId = switch (location.kind) {
        WorldArtifactLocationKind.carried => unitOwnersById[location.unitId],
        WorldArtifactLocationKind.stored => cityOwnersById[location.cityId],
        WorldArtifactLocationKind.map ||
        WorldArtifactLocationKind.excavation => null,
      };
      if (ownerId != null) (byOwner[ownerId] ??= []).add(artifact);
    }
    return byOwner;
  }

  static Iterable<String> _improvementOwners(
    FieldImprovement improvement, {
    required List<GameCity> cities,
    required Map<String, String> cityOwnersById,
  }) {
    final builtByCityId = improvement.builtByCityId;
    if (builtByCityId != null) {
      final ownerId = cityOwnersById[builtByCityId];
      return ownerId == null ? const [] : [ownerId];
    }
    final ownerIds = <String>{};
    for (final city in cities) {
      if (city.controlsHex(improvement.hex)) {
        ownerIds.add(city.ownerPlayerId);
      }
    }
    return ownerIds;
  }
}
