import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class SelectionReducer {
  /// Selects a tile by coordinates. Clears move/founding state.
  static GameState selectTile(
    GameState state,
    SelectTileCommand command,
    MapData mapData,
  ) {
    final tile = mapData.tileAt(command.col, command.row);
    if (tile == null) return state;
    final visibleTile = _visibleTileForActivePlayer(state, tile);

    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(selection: GameSelection.tile(visibleTile));
    return next;
  }

  /// Selects a unit by ID. Auto-starts move targeting for controllable units.
  static GameState selectUnit(
    GameState state,
    SelectUnitCommand command,
    MapData mapData,
  ) {
    final unit = state.units.where((u) => u.id == command.unitId).firstOrNull;
    if (unit == null) return state;

    final tile = mapData.tileAt(unit.col, unit.row);
    final visibleTile = tile == null
        ? null
        : _visibleTileForActivePlayer(state, tile);

    var next = state.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(
      selection: GameSelection.unit(unit, tile: visibleTile),
    );

    if (next.canControlUnit(unit) &&
        unit.movementPoints > 0 &&
        !unit.isMerchant &&
        unit.workerJob == null &&
        !unit.isFortified) {
      next = next.copyWith(moveCommandActive: true);
    } else {
      next = next.copyWith(moveCommandActive: false);
    }

    return next;
  }

  /// Selects a city by ID. Calculates yield and economy breakdown.
  static GameState selectCity(
    GameState state,
    SelectCityCommand command,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final city = state.cities.where((c) => c.id == command.cityId).firstOrNull;
    if (city == null) return state;

    return _selectCityDirect(
      state,
      city,
      mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  /// Handles a tile tap with full selection cycling logic.
  static GameStateTransition handleTileTapped(
    GameState state,
    TileTappedCommand command,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final tileData = mapData.tileAt(command.col, command.row);
    if (tileData == null) {
      return GameStateTransition(state: state);
    }

    final visibility = state.activePlayerVisibility;

    if (!visibility.canInspectTile(tileData)) {
      if (state.moveCommandActive) {
        final selected = state.selectedUnit;
        if (selected != null && state.canControlUnit(selected)) {
          // Hidden targets can still extend a planned move path.
          return GameStateTransition(state: state);
        }
      }
      var next = state.copyWith(moveCommandActive: false);
      next = next.copyWith(movePreview: null);
      next = next.copyWith(cityFoundingDraft: null);
      next = next.copyWith(pendingAction: null);
      next = next.copyWith(selection: null);
      return GameStateTransition(state: next);
    }

    if (state.cityFoundingDraft != null) {
      return GameStateTransition(state: state);
    }

    if (state.moveCommandActive) {
      final selected = state.selectedUnit;
      if (selected != null && state.canControlUnit(selected)) {
        final tappedUnit =
            visibility.canSeeDynamicAt(tileData.col, tileData.row)
            ? state.unitAt(tileData.col, tileData.row)
            : null;
        if (tappedUnit != null && tappedUnit.id != selected.id) {
          return GameStateTransition(
            state: _selectUnitDirect(state, tappedUnit, mapData),
          );
        }

        if (tileData.col == selected.col && tileData.row == selected.row) {
          return GameStateTransition(state: _selectTileDirect(state, tileData));
        }

        return GameStateTransition(state: state);
      }
      var next = state.copyWith(moveCommandActive: false);
      next = next.copyWith(movePreview: null);
      return GameStateTransition(
        state: _handleStandardSelection(
          next,
          tileData,
          visibility,
          mapData,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          paceBalance: paceBalance,
        ),
      );
    }

    return GameStateTransition(
      state: _handleStandardSelection(
        state,
        tileData,
        visibility,
        mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
    );
  }

  static GameState _handleStandardSelection(
    GameState state,
    TileData tileData,
    FogVisibilityQuery visibility,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final tappedUnit = visibility.canSeeDynamicAt(tileData.col, tileData.row)
        ? state.unitAt(tileData.col, tileData.row)
        : null;

    final tappedCity = state.citiesKnownToActivePlayer
        .where(
          (c) => c.center.col == tileData.col && c.center.row == tileData.row,
        )
        .firstOrNull;
    final tappedImprovement = _fieldImprovementAt(state, tileData, visibility);

    if (tappedCity != null) {
      return handleCityTapped(
        state,
        tappedCity,
        mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      );
    }

    if (tappedImprovement != null) {
      return _handleFieldImprovementTapped(
        state,
        tappedImprovement,
        tileData,
        tappedUnit,
        mapData,
      );
    }

    if (tappedUnit != null) {
      if (_isSelectedUnit(state, tappedUnit)) {
        return _selectTileDirect(state, tileData);
      } else {
        return _selectUnitDirect(state, tappedUnit, mapData);
      }
    }

    return _selectTileDirect(state, tileData);
  }

  /// Handles city tapped with selection cycling logic.
  static GameState handleCityTapped(
    GameState state,
    GameCity city,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
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
        return _selectUnitDirect(state, unitOnCity, mapData);
      } else {
        return _selectCityCenterTile(state, city, mapData);
      }
    }

    final current = state.selection;
    final onThisCity =
        current?.type == GameSelectionType.city && current?.city?.id == city.id;
    final onThisTile =
        current?.type == GameSelectionType.tile &&
        current?.tile?.col == city.center.col &&
        current?.tile?.row == city.center.row;
    final onUnitHere =
        current?.type == GameSelectionType.unit &&
        current?.unit?.col == city.center.col &&
        current?.unit?.row == city.center.row;

    if (unitOnCity != null) {
      if (onThisCity) {
        return _selectUnitDirect(state, unitOnCity, mapData);
      } else if (onUnitHere) {
        return _selectCityCenterTile(state, city, mapData);
      } else {
        return _selectCityDirect(
          state,
          city,
          mapData,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          paceBalance: paceBalance,
        );
      }
    } else {
      if (onThisCity) {
        return _selectCityCenterTile(state, city, mapData);
      } else if (onThisTile) {
        return _selectCityDirect(
          state,
          city,
          mapData,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          paceBalance: paceBalance,
        );
      } else {
        return _selectCityDirect(
          state,
          city,
          mapData,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          paceBalance: paceBalance,
        );
      }
    }
  }

  static GameState _handleFieldImprovementTapped(
    GameState state,
    FieldImprovement improvement,
    TileData tileData,
    GameUnit? unitOnTile,
    MapData mapData,
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
        return _selectUnitDirect(state, unitOnTile, mapData);
      }
      if (onUnitHere) {
        return _selectTileDirect(state, tileData);
      }
      return _selectFieldImprovementDirect(state, improvement, tileData);
    }

    if (onThisImprovement) {
      return _selectTileDirect(state, tileData);
    }
    if (onThisTile) {
      return _selectFieldImprovementDirect(state, improvement, tileData);
    }
    return _selectFieldImprovementDirect(state, improvement, tileData);
  }

  static bool _isSelectedUnit(GameState state, GameUnit unit) {
    return state.selection?.type == GameSelectionType.unit &&
        state.selection?.unit?.id == unit.id;
  }

  static GameState _selectTileDirect(GameState state, TileData tileData) {
    final visibleTile = _visibleTileForActivePlayer(state, tileData);
    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(selection: GameSelection.tile(visibleTile));
    return next;
  }

  static GameState _selectUnitDirect(
    GameState state,
    GameUnit unit,
    MapData mapData,
  ) {
    final tile = mapData.tileAt(unit.col, unit.row);
    final visibleTile = tile == null
        ? null
        : _visibleTileForActivePlayer(state, tile);

    var next = state.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(
      selection: GameSelection.unit(unit, tile: visibleTile),
    );

    if (next.canControlUnit(unit) && !unit.isMerchant) {
      next = next.copyWith(moveCommandActive: true);
    } else {
      next = next.copyWith(moveCommandActive: false);
    }

    return next;
  }

  static GameState _selectFieldImprovementDirect(
    GameState state,
    FieldImprovement improvement,
    TileData tileData,
  ) {
    final visibleTile = _visibleTileForActivePlayer(state, tileData);
    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(
      selection: GameSelection.fieldImprovement(improvement, tile: visibleTile),
    );
    return next;
  }

  static GameState _selectCityDirect(
    GameState state,
    GameCity city,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
      technologyEffects: TechnologyEffectSummary.forPlayer(
        playerId: city.ownerPlayerId,
        research: state.research,
        ruleset: technologyRuleset,
      ),
    );

    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(
      selection: GameSelection.city(
        city,
        cityYield: cityYield,
        cityEconomy: cityEconomy,
        playerColor:
            state.colorForPlayer(city.ownerPlayerId) ?? Player.palette.first,
      ),
    );
    return next;
  }

  static GameState _selectCityCenterTile(
    GameState state,
    GameCity city,
    MapData mapData,
  ) {
    final centerTile = mapData.tileAt(city.center.col, city.center.row);
    if (centerTile != null) {
      return _selectTileDirect(
        state,
        _visibleTileForActivePlayer(state, centerTile),
      );
    }
    var next = state.copyWith(moveCommandActive: false);
    next = next.copyWith(movePreview: null);
    next = next.copyWith(cityFoundingDraft: null);
    next = next.copyWith(pendingAction: null);
    next = next.copyWith(selection: null);
    return next;
  }

  static bool _isActivePlayerOwned(GameState state, String ownerPlayerId) {
    return state.activePlayerId.isNotEmpty &&
        state.activePlayerId == ownerPlayerId;
  }

  static TileData _visibleTileForActivePlayer(GameState state, TileData tile) {
    return ResourceVisibilityRules.visibleTile(
      tile: tile,
      playerId: state.activePlayerId,
      research: state.research,
    );
  }

  static FieldImprovement? _fieldImprovementAt(
    GameState state,
    TileData tileData,
    FogVisibilityQuery visibility,
  ) {
    if (!visibility.canRememberStaticAt(tileData.col, tileData.row)) {
      return null;
    }
    for (final improvement in state.fieldImprovements) {
      if (improvement.occupies(tileData.col, tileData.row)) {
        return improvement;
      }
    }
    return null;
  }
}
