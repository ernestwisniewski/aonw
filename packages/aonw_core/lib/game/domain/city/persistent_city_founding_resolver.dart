import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class PersistentCityFoundingResult {
  const PersistentCityFoundingResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

class PersistentCityFoundingResolver {
  const PersistentCityFoundingResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentCityFoundingResult foundCity({
    required PersistentGameState state,
    required FoundCityCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final founderIndex = _unitIndexById(state.units, command.founderId);
    if (founderIndex == null) return _reject(state, 'city_founder_not_found');

    final founder = state.units[founderIndex];
    if (founder.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'city_founder_not_controlled');
    }
    if (founder.isWorking) {
      return _reject(state, 'city_founder_busy');
    }

    final mapData = _mapDataFromDefinition(mapDefinition);
    final centerTile = mapData.tileAt(founder.col, founder.row);
    final startFailure = CityFoundingRules.startFailure(
      unit: founder,
      centerTile: centerTile,
      cities: state.cities,
    );
    if (startFailure != null) {
      return _reject(state, _reasonForStartFailure(startFailure));
    }

    final draft = CityFoundingDraft(
      unitId: founder.id,
      ownerPlayerId: founder.ownerPlayerId,
      center: CityHex(col: founder.col, row: founder.row),
      controlledHexes: command.controlledHexes,
    );
    if (CityFoundingRules.confirmFailure(draft) != null) {
      return _reject(state, 'city_controlled_hexes_invalid');
    }
    if (!_controlledHexesAreValid(draft, mapData, state.cities)) {
      return _reject(state, 'city_controlled_hexes_invalid');
    }

    final updatedFounder = founder
        .copyWith(movementPoints: 0)
        .copyWithQueuedPath(null)
        .copyWithCityFoundingJob(
          CityFoundingJob(
            center: draft.center,
            controlledHexes: draft.controlledHexes,
            remainingTurns: 1,
            totalTurns: 1,
          ),
        );
    final updatedUnits = _replaceUnitAt(
      state.units,
      founderIndex,
      updatedFounder,
    );

    return PersistentCityFoundingResult(
      accepted: true,
      state: state.copyWith(
        units: updatedUnits,
        runtimeState: _clearFoundingRuntimeState(
          state.runtimeState,
          founderId: founder.id,
        ),
      ),
    );
  }

  PersistentCityFoundingResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentCityFoundingResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static bool _controlledHexesAreValid(
    CityFoundingDraft draft,
    MapData mapData,
    Iterable<GameCity> cities,
  ) {
    final unique = draft.controlledHexes.toSet();
    if (unique.length != draft.controlledHexes.length) return false;
    for (final hex in draft.controlledHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null) return false;
      if (!CityFoundingRules.isControlledHexCandidate(
        draft: draft,
        tile: tile,
        mapData: mapData,
        cities: cities,
      )) {
        return false;
      }
    }
    return true;
  }

  static String _reasonForStartFailure(CityFoundingFailure failure) {
    return switch (failure) {
      CityFoundingFailure.noCommander => 'city_founder_invalid',
      CityFoundingFailure.noSettlers => 'city_founder_no_settlers',
      CityFoundingFailure.invalidCenter => 'city_site_invalid',
      CityFoundingFailure.cityAlreadyExists => 'city_center_occupied',
      CityFoundingFailure.centerOccupied => 'city_center_claimed',
      CityFoundingFailure.tooCloseToCity => 'city_center_too_close',
      CityFoundingFailure.invalidControlledHexes =>
        'city_controlled_hexes_invalid',
    };
  }

  static GameRuntimeState _clearFoundingRuntimeState(
    GameRuntimeState runtimeState, {
    required String founderId,
  }) {
    final clearDraft = runtimeState.cityFoundingDraft?.unitId == founderId;
    if (!clearDraft) return runtimeState;
    return GameRuntimeState(
      pendingAction: runtimeState.pendingAction,
      submittedPlayerIds: runtimeState.submittedPlayerIds,
      timeoutStreaksByPlayerId: runtimeState.timeoutStreaksByPlayerId,
      afkPlayerIds: runtimeState.afkPlayerIds,
      kickedPlayerIds: runtimeState.kickedPlayerIds,
      intendedAttacks: runtimeState.intendedAttacks,
      diplomacy: runtimeState.diplomacy,
      dominationHoldTurnsByPlayerId: runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          runtimeState.culturalVictoryHoldTurnsByPlayerId,
      turnStartedAt: runtimeState.turnStartedAt,
    );
  }

  static MapData _mapDataFromDefinition(MapDefinition mapDefinition) {
    return MapData(
      cols: mapDefinition.cols,
      rows: mapDefinition.rows,
      mapName: mapDefinition.mapName,
      defaultZoom: mapDefinition.defaultZoom,
      tiles: [
        for (final tile in mapDefinition.tiles)
          TileData(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }

  static List<GameUnit> _replaceUnitAt(
    List<GameUnit> units,
    int index,
    GameUnit updated,
  ) {
    return [...units]..[index] = updated;
  }
}
