import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_models.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_improvement_options_view_model_factory.dart';
import 'package:aonw/l10n/generated/app_localizations_pl.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerImprovementOptionsViewModelFactory', () {
    test('uses core worker improvement scoring for option scores', () {
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 1,
      );
      final map = _mapWithWorkerTile(
        const TileData(
          col: 1,
          row: 1,
          terrains: [TerrainType.grassland],
          resources: [],
          height: 0,
        ),
      );
      final options = WorkerImprovementOptionsViewModelFactory.from(
        unit: worker,
        cities: const [_city],
        fieldImprovements: const [],
        mapData: map,
        research: _research({TechnologyId.agriculture}),
        selectionActive: true,
        selectedImprovementType: null,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: AppLocalizationsPl(),
      );

      final farm = options.firstWhere(
        (option) => option.improvementType == FieldImprovementType.farm,
      );

      expect(
        farm.score,
        WorkerImprovementScoring.scoreFor(
          type: FieldImprovementType.farm,
          tile: map.tileAt(1, 1),
        ),
      );
      expect(farm.state, WorkerImprovementOptionState.recommended);
    });
  });
}

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Miasto',
  center: CityHex(col: 0, row: 0),
  controlledHexes: [CityHex(col: 1, row: 1)],
);

MapData _mapWithWorkerTile(TileData workerTile) {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: [
      const TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      workerTile,
    ],
  );
}

ResearchState _research(Set<TechnologyId> unlocked) {
  return ResearchState(
    players: {'player_1': PlayerResearchState(unlockedTechnologyIds: unlocked)},
  );
}
