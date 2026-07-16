import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

abstract final class SelectionReducer {
  /// Selects a tile by coordinates. Clears move/founding state.
  static GameState selectTile(
    GameState state,
    SelectTileCommand command,
    MapTileLookup mapTiles,
  ) {
    final tile = mapTiles.tileAt(command.col, command.row);
    if (tile == null) return state;
    final visibleTile = _visibleTileForActivePlayer(state, tile);

    return _withFreshInteractionSelection(
      state,
      GameSelection.tile(visibleTile),
    );
  }

  /// Selects a unit by ID. Auto-starts move targeting for controllable units.
  static GameState selectUnit(
    GameState state,
    SelectUnitCommand command,
    MapTileLookup mapTiles,
  ) {
    final unit = state.unitById(command.unitId);
    if (unit == null) return state;

    final tile = mapTiles.tileAt(unit.col, unit.row);
    final visibleTile = tile == null
        ? null
        : _visibleTileForActivePlayer(state, tile);

    var next = _withFreshInteractionSelection(
      state,
      GameSelection.unit(unit, tile: visibleTile),
    );

    if (next.canControlUnit(unit) &&
        unit.movementPoints > 0 &&
        !unit.isMerchant &&
        unit.workerJob == null &&
        !unit.isFortified) {
      next = next.copyWithInteraction(moveCommandActive: true);
    } else {
      next = next.copyWithInteraction(moveCommandActive: false);
    }

    return next;
  }

  /// Selects a city by ID. Calculates yield and economy breakdown.
  static GameState selectCity(
    GameState state,
    SelectCityCommand command,
    MapTileLookup mapTiles, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final city = state.cityById(command.cityId);
    if (city == null) return state;

    return _selectCityDirect(
      state,
      city,
      mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    );
  }

  /// Handles a tile tap with full selection cycling logic.
  static GameStateTransition handleTileTapped(
    GameState state,
    TileTappedCommand command,
    MapTileLookup mapTiles, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final tile = mapTiles.tileAt(command.col, command.row);
    if (tile == null) {
      return GameStateTransition(state: state);
    }

    final visibility = state.activePlayerVisibility;

    if (!visibility.canInspectTile(tile)) {
      if (state.moveCommandActive) {
        final selected = state.selectedUnit;
        if (selected != null && state.canControlUnit(selected)) {
          // Hidden targets can still extend a planned move path.
          return GameStateTransition(state: state);
        }
      }
      final next = _withFreshInteractionSelection(state, null);
      return GameStateTransition(state: next);
    }

    if (state.cityFoundingDraft != null) {
      return GameStateTransition(state: state);
    }

    var selectionState = state;
    if (state.moveCommandActive) {
      final selected = state.selectedUnit;
      if (selected != null && state.canControlUnit(selected)) {
        final tappedUnit = visibility.canSeeDynamicAt(tile.col, tile.row)
            ? state.unitAt(tile.col, tile.row)
            : null;
        if (tappedUnit != null && tappedUnit.id != selected.id) {
          return GameStateTransition(
            state: _selectUnitDirect(state, tappedUnit, mapTiles),
          );
        }

        if (tile.col == selected.col && tile.row == selected.row) {
          return GameStateTransition(state: _selectTileDirect(state, tile));
        }

        return GameStateTransition(state: state);
      }
      selectionState = state.copyWithInteraction(
        moveCommandActive: false,
        movePreview: null,
      );
    }

    return GameStateTransition(
      state: _handleStandardSelection(
        selectionState,
        tile,
        visibility,
        mapTiles,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityRuleset: stabilityRuleset,
        wonderRuleset: wonderRuleset,
        paceBalance: paceBalance,
      ),
    );
  }

  static GameState _handleStandardSelection(
    GameState state,
    MapTileView tile,
    FogVisibilityQuery visibility,
    MapTileLookup mapTiles, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final tappedUnit = visibility.canSeeDynamicAt(tile.col, tile.row)
        ? state.unitAt(tile.col, tile.row)
        : null;

    final tappedCity = state.citiesKnownToActivePlayer.cityAt(
      tile.col,
      tile.row,
    );
    final tappedImprovement = _fieldImprovementAt(state, tile, visibility);

    if (tappedCity != null) {
      return handleCityTapped(
        state,
        tappedCity,
        mapTiles,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityRuleset: stabilityRuleset,
        wonderRuleset: wonderRuleset,
        paceBalance: paceBalance,
      );
    }

    if (tappedImprovement != null) {
      return _handleFieldImprovementTapped(
        state,
        tappedImprovement,
        tile,
        tappedUnit,
        mapTiles,
      );
    }

    if (tappedUnit != null) {
      if (_isSelectedUnit(state, tappedUnit)) {
        return _selectTileDirect(state, tile);
      } else {
        return _selectUnitDirect(state, tappedUnit, mapTiles);
      }
    }

    return _selectTileDirect(state, tile);
  }

  /// Handles city tapped with selection cycling logic.
  static GameState handleCityTapped(
    GameState state,
    GameCity city,
    MapTileLookup mapTiles, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (state.cityFoundingDraft != null) return state;

    final visibility = state.activePlayerVisibility;
    if (!visibility.canRememberStaticAt(city.center.col, city.center.row)) {
      return state;
    }

    final unitOnCity =
        visibility.canSeeDynamicAt(city.center.col, city.center.row)
        ? state.unitAt(city.center.col, city.center.row)
        : null;

    if (!state.canControlCity(city) &&
        !_isActivePlayerOwned(state, city.ownerPlayerId)) {
      final current = state.selection;
      final onThisTile =
          current?.tile?.col == city.center.col &&
          current?.tile?.row == city.center.row;
      if (unitOnCity != null && onThisTile) {
        return _selectUnitDirect(state, unitOnCity, mapTiles);
      } else {
        return _selectCityCenterTile(state, city, mapTiles);
      }
    }

    final current = state.selection;
    final onThisCity =
        current?.type == GameSelectionType.city && current?.city?.id == city.id;
    final onUnitHere =
        current?.type == GameSelectionType.unit &&
        current?.unit?.col == city.center.col &&
        current?.unit?.row == city.center.row;

    if (unitOnCity != null) {
      if (onThisCity) {
        return _selectUnitDirect(state, unitOnCity, mapTiles);
      }
      if (onUnitHere) {
        return _selectCityCenterTile(state, city, mapTiles);
      }
    } else if (onThisCity) {
      return _selectCityCenterTile(state, city, mapTiles);
    }

    return _selectCityDirect(
      state,
      city,
      mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityRuleset: stabilityRuleset,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    );
  }

  static GameState _handleFieldImprovementTapped(
    GameState state,
    FieldImprovement improvement,
    MapTileView tile,
    GameUnit? unitOnTile,
    MapTileLookup mapTiles,
  ) {
    final current = state.selection;
    final onThisImprovement =
        current?.type == GameSelectionType.fieldImprovement &&
        current?.fieldImprovement?.hex == improvement.hex;
    final onUnitHere =
        current?.type == GameSelectionType.unit &&
        current?.unit?.col == improvement.hex.col &&
        current?.unit?.row == improvement.hex.row;
    final onThisTile =
        current?.type == GameSelectionType.tile &&
        current?.tile?.col == improvement.hex.col &&
        current?.tile?.row == improvement.hex.row;

    if (unitOnTile != null) {
      if (onThisImprovement) {
        return _selectUnitDirect(state, unitOnTile, mapTiles);
      }
      if (onUnitHere) {
        return _selectTileDirect(state, tile);
      }
      return _selectFieldImprovementDirect(state, improvement, tile);
    }

    if (onThisImprovement) {
      return _selectTileDirect(state, tile);
    }
    if (onThisTile) {
      return _selectFieldImprovementDirect(state, improvement, tile);
    }
    return _selectFieldImprovementDirect(state, improvement, tile);
  }

  static bool _isSelectedUnit(GameState state, GameUnit unit) {
    return state.selection?.type == GameSelectionType.unit &&
        state.selection?.unit?.id == unit.id;
  }

  static GameState _selectTileDirect(GameState state, MapTileView tile) {
    final visibleTile = _visibleTileForActivePlayer(state, tile);
    return _withFreshInteractionSelection(
      state,
      GameSelection.tile(visibleTile),
    );
  }

  static GameState _selectUnitDirect(
    GameState state,
    GameUnit unit,
    MapTileLookup mapTiles,
  ) {
    final tile = mapTiles.tileAt(unit.col, unit.row);
    final visibleTile = tile == null
        ? null
        : _visibleTileForActivePlayer(state, tile);

    var next = _withFreshInteractionSelection(
      state,
      GameSelection.unit(unit, tile: visibleTile),
    );

    if (next.canControlUnit(unit) && !unit.isMerchant) {
      next = next.copyWithInteraction(moveCommandActive: true);
    } else {
      next = next.copyWithInteraction(moveCommandActive: false);
    }

    return next;
  }

  static GameState _selectFieldImprovementDirect(
    GameState state,
    FieldImprovement improvement,
    MapTileView tile,
  ) {
    final visibleTile = _visibleTileForActivePlayer(state, tile);
    return _withFreshInteractionSelection(
      state,
      GameSelection.fieldImprovement(improvement, tile: visibleTile),
    );
  }

  static GameState _selectCityDirect(
    GameState state,
    GameCity city,
    MapTileLookup mapTiles, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    WonderRuleset wonderRuleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return _withFreshInteractionSelection(
      state,
      CitySelectionProjector.project(
        state: state,
        city: city,
        mapTiles: mapTiles,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityRuleset: stabilityRuleset,
        wonderRuleset: wonderRuleset,
        paceBalance: paceBalance,
      ),
    );
  }

  static GameState _selectCityCenterTile(
    GameState state,
    GameCity city,
    MapTileLookup mapTiles,
  ) {
    final centerTile = mapTiles.tileAt(city.center.col, city.center.row);
    if (centerTile != null) {
      return _selectTileDirect(state, centerTile);
    }
    return _withFreshInteractionSelection(state, null);
  }

  static bool _isActivePlayerOwned(GameState state, String ownerPlayerId) {
    return state.activePlayerId.isNotEmpty &&
        state.activePlayerId == ownerPlayerId;
  }

  static SelectedTile _visibleTileForActivePlayer(
    GameState state,
    MapTileView tile,
  ) {
    final snapshot = SelectedTile.fromMapTileView(tile);
    return snapshot.withResources(
      ResourceVisibilityRules.visibleResources(
        resources: snapshot.resources,
        playerId: state.activePlayerId,
        research: state.research,
      ),
    );
  }

  static FieldImprovement? _fieldImprovementAt(
    GameState state,
    MapTileView tile,
    FogVisibilityQuery visibility,
  ) {
    if (!visibility.canRememberStaticAt(tile.col, tile.row)) {
      return null;
    }
    for (final improvement in state.fieldImprovements) {
      if (improvement.occupies(tile.col, tile.row)) {
        return improvement;
      }
    }
    return null;
  }
}

GameState _withFreshInteractionSelection(
  GameState state,
  GameSelection? selection,
) {
  return state.copyWith(
    interaction: state.interaction
        .clearMapState(clearPendingAction: true)
        .copyWith(selection: selection),
  );
}
