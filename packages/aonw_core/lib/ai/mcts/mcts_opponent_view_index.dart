import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class MctsOpponentViewIndex {
  final List<GameUnit> _units;
  final List<GameCity> _cities;
  final Map<String, List<GameUnit>> _unitsByOwner;
  final Map<String, List<GameCity>> _citiesByOwner;
  final Map<String, List<FieldImprovement>> _improvementsByOwner;

  MctsOpponentViewIndex._({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required Map<String, List<GameUnit>> unitsByOwner,
    required Map<String, List<GameCity>> citiesByOwner,
    required Map<String, List<FieldImprovement>> improvementsByOwner,
  }) : _units = List.unmodifiable(units),
       _cities = List.unmodifiable(cities),
       _unitsByOwner = _freezeListMap(unitsByOwner),
       _citiesByOwner = _freezeListMap(citiesByOwner),
       _improvementsByOwner = _freezeListMap(improvementsByOwner);

  factory MctsOpponentViewIndex.fromState(PersistentGameState state) {
    final unitsByOwner = <String, List<GameUnit>>{};
    for (final unit in state.units) {
      (unitsByOwner[unit.ownerPlayerId] ??= []).add(unit);
    }

    final citiesByOwner = <String, List<GameCity>>{};
    final cityOwnersById = <String, String>{};
    for (final city in state.cities) {
      (citiesByOwner[city.ownerPlayerId] ??= []).add(city);
      cityOwnersById[city.id] = city.ownerPlayerId;
    }

    return MctsOpponentViewIndex._(
      units: state.units,
      cities: state.cities,
      unitsByOwner: unitsByOwner,
      citiesByOwner: citiesByOwner,
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
    required MapData mapData,
    required GameRuleset ruleset,
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
      diplomacy: state.runtimeState.diplomacy,
      visibleEnemyUnits: [
        for (final unit in _units)
          if (unit.ownerPlayerId != opponentId) unit,
      ],
      rememberedEnemyCities: [
        for (final city in _cities)
          if (city.ownerPlayerId != opponentId) city,
      ],
      visibility: const FogVisibilityQuery(
        playerId: '',
        state: FogOfWarState.empty,
      ),
      mapData: mapData,
      ruleset: ruleset,
    );
  }

  static Map<String, List<T>> _freezeListMap<T>(Map<String, List<T>> source) {
    return Map.unmodifiable(<String, List<T>>{
      for (final entry in source.entries)
        entry.key: List<T>.unmodifiable(entry.value),
    });
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
