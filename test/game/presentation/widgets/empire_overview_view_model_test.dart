import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/empire/empire_overview_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('filters, sorts and summarizes active player empire data', () {
    final warriorB = GameUnit(
      id: 'unit_b',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Beta',
      col: 0,
      row: 0,
      movementPoints: 0,
    );
    final warriorA = GameUnit(
      id: 'unit_a',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Alpha',
      col: 1,
      row: 0,
      movementPoints: 2,
    );
    final enemy = GameUnit(
      id: 'enemy',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 0,
    );
    const cityB = GameCity(
      id: 'city_b',
      ownerPlayerId: 'player_1',
      name: 'Zeta',
      population: 2,
      center: CityHex(col: 0, row: 0),
    );
    const cityA = GameCity(
      id: 'city_a',
      ownerPlayerId: 'player_1',
      name: 'Alpha',
      population: 3,
      center: CityHex(col: 1, row: 0),
    );
    const enemyCity = GameCity(
      id: 'enemy_city',
      ownerPlayerId: 'player_2',
      name: 'Enemy',
      population: 9,
      center: CityHex(col: 2, row: 0),
    );
    const ownArtifact = WorldArtifact(
      id: 'artifact.hero',
      type: WorldArtifactType.heroSword,
      location: WorldArtifactLocation.stored(cityId: 'city_b'),
    );
    const enemyArtifact = WorldArtifact(
      id: 'artifact.enemy',
      type: WorldArtifactType.queensMirror,
      location: WorldArtifactLocation.stored(cityId: 'enemy_city'),
    );

    final viewModel = EmpireOverviewViewModel.fromState(
      GameState(
        units: [warriorB, enemy, warriorA],
        cities: [cityB, enemyCity, cityA],
        artifacts: [ownArtifact, enemyArtifact],
      ),
      activePlayerId: 'player_1',
    );

    expect(viewModel.units.map((unit) => unit.id), ['unit_a', 'unit_b']);
    expect(viewModel.cities.map((city) => city.id), ['city_a', 'city_b']);
    expect(viewModel.readyUnitCount, 1);
    expect(viewModel.totalPopulation, 5);
    expect(viewModel.cityComparisons.map((city) => city.city.id), [
      'city_a',
      'city_b',
    ]);
    expect(viewModel.subtitle(l10n), '2 cities - 2 units');
    expect(viewModel.storedArtifactCount, 1);
    expect(viewModel.storedArtifactsByCityId['city_b'], ownArtifact);
    expect(
      viewModel.storedArtifactsByCityId.containsKey('enemy_city'),
      isFalse,
    );
    expect(viewModel.unitGroups, hasLength(1));
    expect(viewModel.unitGroups.single.type, GameUnitType.warrior);
    expect(viewModel.unitGroups.single.readyUnitCount, 1);
  });

  test('builds city comparison metrics from map economy when available', () {
    const city = GameCity(
      id: 'city',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      population: 2,
      center: CityHex(col: 0, row: 0),
      controlledHexes: [CityHex(col: 1, row: 0)],
    );
    final viewModel = EmpireOverviewViewModel.fromState(
      const GameState(cities: [city]),
      activePlayerId: 'player_1',
      mapData: _map(),
    );

    final comparison = viewModel.cityComparisons.single;
    expect(comparison.population, 2);
    expect(comparison.production, greaterThan(0));
    expect(comparison.food, greaterThanOrEqualTo(0));
    expect(comparison.territory, 2);
  });

  test('formats empire labels and entity subtitles', () {
    final worker = GameUnit(
      id: 'worker',
      ownerPlayerId: 'player_1',
      type: GameUnitType.worker,
      name: 'Worker',
      col: 0,
      row: 0,
      movementPoints: 0,
    );
    final fortifiedWarrior = GameUnit(
      id: 'warrior',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 0,
      movementPoints: 0,
      posture: UnitPosture.fortified,
    );
    final healingWarrior = fortifiedWarrior.copyWithHitPoints(7);
    final city = GameCity(
      id: 'city',
      ownerPlayerId: 'player_1',
      name: 'Capital',
      population: 4,
      center: const CityHex(col: 0, row: 0),
      controlledHexes: const [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      buildings: {CityBuildingType.workshop},
      productionQueue: CityProductionQueue.unit(
        unitType: GameUnitType.worker,
        investedProduction: 1,
      ),
    );
    const idleCity = GameCity(
      id: 'idle_city',
      ownerPlayerId: 'player_1',
      name: 'Idle',
      population: 1,
      center: CityHex(col: 2, row: 0),
    );

    expect(empireUnitCountLabel(l10n, 0), '0 units');
    expect(empireUnitCountLabel(l10n, 1), '1 unit');
    expect(empireUnitCountLabel(l10n, 3), '3 units');
    expect(empireUnitCountLabel(l10n, 5), '5 units');
    expect(empireCityCountLabel(l10n, 1), '1 city');
    expect(empireCityCountLabel(l10n, 4), '4 cities');
    expect(empireCityCountLabel(l10n, 8), '8 cities');
    expect(empireUnitSubtitle(l10n, worker), 'Movement 0');
    expect(
      empireUnitSubtitle(l10n, fortifiedWarrior),
      'Movement 0 - Fortifying',
    );
    expect(empireUnitSubtitle(l10n, healingWarrior), 'Movement 0 - Healing');
    expect(
      empireCitySubtitle(l10n, city),
      'Population 4 - 3 tiles - 1 bldg. - producing: Worker',
    );
    expect(
      empireCitySubtitle(
        l10n,
        city,
        storedArtifact: const WorldArtifact(
          id: 'artifact.hero',
          type: WorldArtifactType.heroSword,
          location: WorldArtifactLocation.stored(cityId: 'city'),
        ),
      ),
      'Population 4 - 3 tiles - 1 bldg. - producing: Worker - '
      "Artifact: Hero's Sword",
    );
    expect(
      empireCitySubtitle(l10n, idleCity),
      'Population 1 - 1 tiles - 0 bldg. - producing: no production',
    );
    expect(empireCityProductionLabel(l10n, city), 'Worker');
    expect(empireCityGroupSubtitle(l10n, [city]), '1 city - population 4');
  });
}

MapData _map() {
  return MapData(
    cols: 2,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.hills],
        resources: [],
        height: 0,
      ),
    ],
  );
}
