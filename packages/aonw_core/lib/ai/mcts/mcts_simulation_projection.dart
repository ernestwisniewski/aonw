import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class MctsSimulationProjection {
  const MctsSimulationProjection._();

  static PersistentGameState persistentStateFromView(
    GameView view, {
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    required ResearchState research,
  }) {
    return PersistentGameState(
      playerGold: {view.forPlayerId: view.ownGold},
      units: units.toList(growable: false),
      cities: cities.toList(growable: false),
      artifacts: view.artifacts,
      fieldImprovements: view.ownImprovements,
      fogOfWar: view.visibility.state,
      research: research,
      runtimeState: GameRuntimeState(diplomacy: view.diplomacy),
    );
  }

  static MapDefinition mapDefinitionFrom(MapData mapData) {
    return MapDefinition(
      cols: mapData.cols,
      rows: mapData.rows,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
      tiles: [
        for (final tile in mapData.tiles)
          MapTileDefinition(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }
}
