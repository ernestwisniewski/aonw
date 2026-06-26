import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_units.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class CityFoundingReducer {
  static GameState startCityFounding(
    GameState state,
    MapData mapData, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final unit = state.selectedUnit;
    if (unit == null || !context.canControlUnit(state, unit)) return state;
    if (unit.isWorking) return state;

    final centerTile = mapData.tileAt(unit.col, unit.row);
    if (!CityFoundingRules.canStart(
      unit: unit,
      centerTile: centerTile,
      cities: state.cities,
    )) {
      return state;
    }

    final center = CityHex(col: unit.col, row: unit.row);
    final candidates = CityInitialTerritorySelector.select(
      center: center,
      mapData: mapData,
      cities: state.cities,
      ruleset: cityRuleset,
    );
    if (candidates.length != CityFoundingDraft.requiredControlledHexes) {
      return state;
    }

    final draft = CityFoundingDraft(
      unitId: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      center: center,
    );

    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: draft);
    next = next.copyWith(pendingAction: null);
    return next;
  }

  static GameState cancelCityFounding(GameState state) {
    return state.copyWith(cityFoundingDraft: null);
  }

  static GameState toggleControlledHex(
    GameState state,
    TileTappedCommand command,
    MapData mapData,
  ) {
    final draft = state.cityFoundingDraft;
    if (draft == null) return state;

    final tile = mapData.tileAt(command.col, command.row);
    if (tile == null) return state;

    final target = CityHex(col: command.col, row: command.row);
    if (draft.controlledHexes.contains(target)) {
      return state.copyWith(
        cityFoundingDraft: draft.copyWith(
          controlledHexes: [
            for (final hex in draft.controlledHexes)
              if (hex != target) hex,
          ],
        ),
      );
    }

    if (draft.controlledHexes.length >=
        CityFoundingDraft.requiredControlledHexes) {
      return state;
    }

    if (!CityFoundingRules.isControlledHexCandidate(
      draft: draft,
      tile: tile,
      mapData: mapData,
      cities: state.cities,
    )) {
      return state;
    }

    return state.copyWith(
      cityFoundingDraft: draft.copyWith(
        controlledHexes: [...draft.controlledHexes, target],
      ),
    );
  }

  static GameStateTransition confirmCityFounding(
    GameState state,
    MapData mapData, {
    FoundCityCommand? command,
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
    CityRuleset cityRuleset = CityRulesets.standard,
  }) {
    final founderId = command?.founderId ?? state.cityFoundingDraft?.unitId;
    if (founderId == null) return GameStateTransition(state: state);
    final founder = state.units
        .where((unit) => unit.id == founderId)
        .firstOrNull;
    if (founder == null ||
        !context.canControlUnit(state, founder) ||
        founder.isWorking ||
        !CityFoundingRules.canFoundCityWith(founder)) {
      return GameStateTransition(
        state: state.copyWith(cityFoundingDraft: null),
      );
    }
    final startFailure = CityFoundingRules.startFailure(
      unit: founder,
      centerTile: mapData.tileAt(founder.col, founder.row),
      cities: state.cities,
    );
    if (startFailure != null) {
      return GameStateTransition(
        state: state.copyWith(cityFoundingDraft: null),
      );
    }
    final draft = _foundingDraftFor(state, command, founder);
    if (draft == null || CityFoundingRules.confirmFailure(draft) != null) {
      return GameStateTransition(state: state);
    }
    if (!_controlledHexesAreValid(draft, mapData, state.cities)) {
      return GameStateTransition(state: state);
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
    var next = state.copyWith(
      units: replaceUnit(state.units, updatedFounder),
      moveCommandActive: false,
    );
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    if (state.selectedUnitId == founder.id) {
      final founderTile = mapData.tileAt(
        updatedFounder.col,
        updatedFounder.row,
      );
      next = next.copyWith(
        selection: GameSelection.unit(updatedFounder, tile: founderTile),
      );
    }

    return GameStateTransition(state: next);
  }

  static CityFoundingDraft? _foundingDraftFor(
    GameState state,
    FoundCityCommand? command,
    GameUnit founder,
  ) {
    if (command == null || command.controlledHexes.isEmpty) {
      final draft = state.cityFoundingDraft;
      if (draft == null || draft.unitId != founder.id) return null;
      return draft;
    }
    return CityFoundingDraft(
      unitId: founder.id,
      ownerPlayerId: founder.ownerPlayerId,
      center: CityHex(col: founder.col, row: founder.row),
      controlledHexes: command.controlledHexes,
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
}
