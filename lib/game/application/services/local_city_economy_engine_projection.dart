import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

GameState projectLocalCityEconomyEngineResult({
  required GameState currentState,
  required GameEngineAccepted result,
  required DomainCommand command,
  required MapTileLookup mapTiles,
  required GameRuleset ruleset,
  required PaceBalance paceBalance,
}) {
  final domain = result.snapshot.domain;
  final canonicalState = currentState.copyWith(
    playerGold: domain.playerGold,
    units: domain.units,
    cities: domain.cities,
    artifacts: domain.artifacts,
    research: domain.research,
    wonderRegistry: domain.wonderRegistry,
    resourceTradeAgreements: domain.resourceTradeAgreements,
  );
  final interaction = result.snapshot.interaction;
  final state = canonicalState.copyWithInteraction(
    cityFoundingDraft: interaction.cityFoundingDraft,
    pendingAction: interaction.pendingAction,
  );

  if (command is FoundCityCommand) {
    return _refreshUnitSelection(
      state,
      command.founderId,
      mapTiles,
      onlyWhenAlreadySelected: true,
    );
  }
  final cityId = _cityId(command);
  if (cityId != null) {
    return _refreshCitySelection(state, cityId, mapTiles, ruleset, paceBalance);
  }
  final worker = _workerProjection(command);
  if (worker != null) {
    return _refreshUnitSelection(
      worker.clearTransientInteraction
          ? state.copyWithInteraction(
              pendingAction: null,
              moveCommandActive: false,
              movePreview: null,
            )
          : state,
      worker.unitId,
      mapTiles,
    );
  }
  if (_clearsSelection(command)) {
    return state.copyWithInteraction(
      selection: null,
      movePreview: null,
      moveCommandActive: false,
    );
  }
  return state;
}

String? _cityId(DomainCommand command) => switch (command) {
  ToggleWorkedHexCommand(:final cityId) ||
  SelectCityExpansionHexCommand(:final cityId) ||
  StartBuildingCommand(:final cityId) ||
  StartUnitProductionCommand(:final cityId) ||
  StartCityProjectCommand(:final cityId) ||
  StartWonderCommand(:final cityId) ||
  SetCitySpecializationCommand(:final cityId) ||
  RushProductionCommand(:final cityId) => cityId,
  _ => null,
};

({String unitId, bool clearTransientInteraction})? _workerProjection(
  DomainCommand command,
) => switch (command) {
  SelectWorkerImprovementCommand(:final unitId) ||
  ConfirmWorkerImprovementCommand(:final unitId) ||
  AssignWorkerToHexCommand(
    :final unitId,
  ) => (unitId: unitId, clearTransientInteraction: true),
  CancelWorkerJobCommand(:final unitId) ||
  CancelWorkerAssignmentCommand(
    :final unitId,
  ) => (unitId: unitId, clearTransientInteraction: false),
  _ => null,
};

bool _clearsSelection(DomainCommand command) =>
    command is StartArtifactExcavationCommand ||
    command is StoreArtifactInCityCommand ||
    command is TradeArtifactCommand;

GameState _refreshUnitSelection(
  GameState state,
  String unitId,
  MapTileLookup mapTiles, {
  bool onlyWhenAlreadySelected = false,
}) {
  if (onlyWhenAlreadySelected && state.selectedUnitId != unitId) return state;
  final unit = state.units.byId(unitId);
  if (unit == null) return state;
  return state.copyWithInteraction(
    selection: GameSelection.unit(
      unit,
      tile: mapTiles.tileAt(unit.col, unit.row),
    ),
  );
}

GameState _refreshCitySelection(
  GameState state,
  String cityId,
  MapTileLookup mapTiles,
  GameRuleset ruleset,
  PaceBalance paceBalance,
) {
  final selection = state.selection;
  if (selection?.type != GameSelectionType.city ||
      selection?.city?.id != cityId) {
    return state;
  }
  final city = state.cities.byId(cityId);
  if (city == null) return state;
  return state.copyWithInteraction(
    selection: CitySelectionProjector.project(
      state: state,
      city: city,
      mapTiles: mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    ),
  );
}
