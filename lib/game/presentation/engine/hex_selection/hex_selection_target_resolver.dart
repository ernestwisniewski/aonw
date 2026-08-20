import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/artifact_type_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/map_objective_type_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/unit.dart';

/// Builds the presentation-only list of entities a player can intentionally
/// choose on a single visible hex.
abstract final class HexSelectionTargetResolver {
  static List<HexSelectionTarget> resolve({
    required GameClientState state,
    required WorldMap mapData,
    required WorldTile tile,
    AppLocalizations? l10n,
  }) {
    final unit = _visibleUnitAt(state, tile);
    final city = _knownCityAt(state, tile);
    final improvement = _knownImprovementAt(state, tile);
    final artifact = _visibleArtifactAt(state, tile);
    final objective = _knownObjectiveAt(state, mapData, tile);

    return [
      TerrainHexSelectionTarget(
        tile: tile,
        label: l10n?.commonTerrain ?? 'Terrain',
      ),
      if (unit != null)
        UnitHexSelectionTarget(
          unit: unit,
          label: l10n == null
              ? unit.type.name
              : GameDisplayNames.unit(l10n, unit),
          icon: gameIconForUnitType(unit.type),
        ),
      if (city != null)
        CityHexSelectionTarget(
          city: city,
          label: l10n == null ? city.name : GameDisplayNames.city(l10n, city),
        ),
      if (improvement != null)
        FieldImprovementHexSelectionTarget(
          improvement: improvement,
          label: l10n == null
              ? improvement.type.name
              : GameDisplayNames.fieldImprovement(l10n, improvement.type),
        ),
      if (artifact != null)
        ArtifactHexSelectionTarget(
          artifact: artifact,
          icon: gameIconForArtifactType(artifact.type),
          label: l10n == null
              ? artifact.type.name
              : GameDisplayNames.worldArtifact(l10n, artifact.type),
        ),
      if (objective != null)
        ObjectiveHexSelectionTarget(
          progress: objective,
          icon: gameIconForMapObjectiveType(objective.definition.type),
          label: l10n == null
              ? objective.definition.type.name
              : GameDisplayNames.mapObjective(l10n, objective.definition.type),
        ),
    ];
  }

  static GameUnit? _visibleUnitAt(GameClientState state, WorldTile tile) {
    for (final unit in state.unitsVisibleToActivePlayer) {
      if (unit.col == tile.col && unit.row == tile.row) return unit;
    }
    return null;
  }

  static GameCity? _knownCityAt(GameClientState state, WorldTile tile) {
    for (final city in state.citiesKnownToActivePlayer) {
      if (city.occupiesCenter(tile.col, tile.row)) return city;
    }
    return null;
  }

  static FieldImprovement? _knownImprovementAt(
    GameClientState state,
    WorldTile tile,
  ) {
    final visibility = state.activePlayerVisibility;
    if (visibility.isEnabled &&
        !visibility.canRememberStaticAt(tile.col, tile.row)) {
      return null;
    }
    for (final improvement in state.fieldImprovements) {
      if (improvement.occupies(tile.col, tile.row)) return improvement;
    }
    return null;
  }

  static WorldArtifact? _visibleArtifactAt(
    GameClientState state,
    WorldTile tile,
  ) {
    final visibility = state.activePlayerVisibility;
    if (visibility.isEnabled &&
        !visibility.canSeeDynamicAt(tile.col, tile.row)) {
      return null;
    }
    for (final artifact in state.artifacts) {
      final location = artifact.location;
      final onMap =
          location.kind == WorldArtifactLocationKind.map ||
          location.kind == WorldArtifactLocationKind.excavation;
      if (onMap && location.col == tile.col && location.row == tile.row) {
        return artifact;
      }
    }
    return null;
  }

  static MapObjectiveProgress? _knownObjectiveAt(
    GameClientState state,
    WorldMap mapData,
    WorldTile tile,
  ) {
    final visibility = state.activePlayerVisibility;
    if (visibility.isEnabled &&
        !visibility.canRememberStaticAt(tile.col, tile.row)) {
      return null;
    }
    MapObjectiveDefinition? definition;
    for (final candidate in mapData.objectives) {
      if (candidate.hex.col == tile.col && candidate.hex.row == tile.row) {
        definition = candidate;
        break;
      }
    }
    if (definition == null) return null;
    return MapObjectiveRules.snapshot(
      objectives: [definition],
      cities: state.citiesKnownToActivePlayer,
      units: state.unitsVisibleToActivePlayer,
      holdStatesByObjectiveId: state.mapObjectiveHoldStatesByObjectiveId,
    ).entryFor(definition.id);
  }
}
