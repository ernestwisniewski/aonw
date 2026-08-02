import 'package:aonw/game/presentation/widgets/city/city_production_dialog_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('CityProductionDialogViewModel uses map-scaled unit supply limit', () {
    final cities = [
      for (var i = 0; i < 5; i++)
        GameCity(
          id: 'city_$i',
          ownerPlayerId: 'player_1',
          name: 'Miasto $i',
          population: 3,
          center: const CityHex(col: 1, row: 1),
          controlledHexes: const [
            CityHex(col: 1, row: 0),
            CityHex(col: 0, row: 1),
          ],
        ),
    ];
    final units = [
      for (var i = 0; i < CityUnitSupplyRules.minimumMapCapacity; i++)
        GameUnit(
          id: 'warrior_$i',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: i % 3,
          row: i ~/ 3,
        ),
    ];

    final viewModel = CityProductionDialogViewModel.from(
      cities.first,
      l10n: l10n,
      cityRuleset: CityRulesets.standard,
      research: ResearchState.empty,
      technologyRuleset: TechnologyRulesets.standard,
      mapData: _map3x3(),
      cities: cities,
      units: units,
      fieldImprovements: const [],
      productionPerTurn: 4,
    );

    final warrior = viewModel.itemForUnit(GameUnitType.warrior);

    expect(warrior, isNotNull);
    expect(warrior!.locked, isTrue);
    expect(
      warrior.requirementLabel,
      l10n.cityProductionUnitSupplyLimit(
        CityUnitSupplyRules.minimumMapCapacity,
        CityUnitSupplyRules.minimumMapCapacity,
      ),
    );
    expect(
      warrior.metaLabels,
      contains(
        l10n.cityProductionUnitSupplyUsed(
          CityUnitSupplyRules.minimumMapCapacity,
          CityUnitSupplyRules.minimumMapCapacity,
        ),
      ),
    );
  });

  test(
    'CityProductionDialogViewModel includes stored artifact food in unit supply',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Miasto',
        population: 3,
        center: CityHex(col: 1, row: 1),
        buildings: {CityBuildingType.granary},
      );
      final units = [
        for (var i = 0; i < 4; i++)
          GameUnit(
            id: 'warrior_$i',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: GameUnitType.warrior.defaultNameToken,
            col: i % 3,
            row: i ~/ 3,
          ),
      ];
      final mapData = _map3x3();

      final baseline = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: ResearchState.empty,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: mapData,
        cities: const [city],
        units: units,
        fieldImprovements: const [],
        productionPerTurn: 4,
      );
      final withChronicle = CityProductionDialogViewModel.from(
        city,
        l10n: l10n,
        cityRuleset: CityRulesets.standard,
        research: ResearchState.empty,
        technologyRuleset: TechnologyRulesets.standard,
        mapData: mapData,
        cities: const [city],
        units: units,
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.firstPeoplesChronicle,
            location: WorldArtifactLocation.stored(cityId: 'city_1'),
          ),
        ],
        fieldImprovements: const [],
        productionPerTurn: 4,
      );

      final baselineWarrior = baseline.itemForUnit(GameUnitType.warrior);
      final artifactWarrior = withChronicle.itemForUnit(GameUnitType.warrior);

      expect(baselineWarrior, isNotNull);
      expect(baselineWarrior!.locked, isTrue);
      expect(
        baselineWarrior.requirementLabel,
        l10n.cityProductionUnitSupplyLimit(4, 4),
      );
      expect(
        baselineWarrior.metaLabels,
        contains(l10n.cityProductionUnitSupplyUsed(4, 4)),
      );
      expect(baseline.currentCityYield?.food, 1);

      expect(artifactWarrior, isNotNull);
      expect(artifactWarrior!.locked, isFalse);
      expect(artifactWarrior.requirementLabel, isNull);
      expect(
        artifactWarrior.metaLabels,
        contains(l10n.cityProductionUnitSupplyUsed(4, 5)),
      );
      expect(withChronicle.currentCityYield?.food, 2);
    },
  );
}

WorldMap _map3x3() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);
