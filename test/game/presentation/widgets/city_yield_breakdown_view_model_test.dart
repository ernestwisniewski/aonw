import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test(
    'CityYieldBreakdownViewModel maps real economy sources and matches total',
    () {
      final (:city, :tileBreakdown, :economy) = _realEconomySourcesFixture();

      final viewModel = CityYieldBreakdownViewModel.from(
        city: city,
        tileBreakdown: tileBreakdown,
        economy: economy,
        currentTurn: 4,
        l10n: l10n,
      );

      expect(viewModel.totalYield, economy.netYield);
      expect(viewModel.rowsMatchTotal, isTrue);
      expect(viewModel.growthLabel, '4/16 food');
      expect(viewModel.growthEta.compactLabel(l10n), '2 turns • T6');
      expect(
        viewModel.rows.map((row) => row.label),
        containsAll([
          'Center',
          'Population fields',
          'Workers',
          'Improvements',
          'Artifact',
          'Buildings',
          'Technologies',
          'Specialization',
          'Gold multiplier',
          'Upkeep',
        ]),
      );
      expect(
        viewModel.rows.singleWhere((row) => row.label == 'Workers').yield,
        const TileYield(food: 3, production: 0, gold: 0, defense: 0),
      );
      expect(
        viewModel.rows.singleWhere((row) => row.label == 'Artifact').yield,
        const TileYield(food: 1, production: 0, gold: 0, defense: 1),
      );
      expect(
        viewModel.rows.singleWhere((row) => row.label == 'Upkeep').yield,
        const TileYield(food: -3, production: 0, gold: 0, defense: 0),
      );
      expect(viewModel.scienceTotal, 7);
      expect(viewModel.scienceRows.map((row) => row.label), [
        'City base',
        'Buildings',
        'Specialization',
        'Technologies',
      ]);
      expect(
        viewModel.scienceRows
            .singleWhere((row) => row.label == 'Buildings')
            .value,
        2,
      );
    },
  );

  test('shows unrest as an exact yield delta and halted growth', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 1,
      center: CityHex(col: 0, row: 0),
    );
    const rawYield = TileYield(food: 2, production: 7, gold: 7, defense: 0);
    const tileBreakdown = CityTileYieldBreakdown(
      center: CityTileYieldContribution(
        kind: CityTileYieldContributionKind.center,
        hex: CityHex(col: 0, row: 0),
        yield: rawYield,
      ),
    );
    const economy = CityEconomyBreakdown(
      city: city,
      tileYield: rawYield,
      buildingYield: TileYield.zero,
      stabilityModifier: StabilityModifier(
        productionMultiplier: 0.75,
        goldMultiplier: 0.75,
        foodBonus: 0,
        haltsGrowth: true,
      ),
      populationUpkeep: 1,
      netFood: 1,
      foodDeposit: 0,
      growthCost: 10,
    );

    final viewModel = CityYieldBreakdownViewModel.from(
      city: city,
      tileBreakdown: tileBreakdown,
      economy: economy,
      currentTurn: 4,
      l10n: l10n,
    );
    final stabilityRow = viewModel.rows.singleWhere(
      (row) => row.label == l10n.stabilityBreakdownBand,
    );

    expect(stabilityRow.detail, l10n.stabilityBandUnrest);
    expect(
      stabilityRow.yield,
      const TileYield(food: 0, production: -2, gold: -2, defense: 0),
    );
    expect(viewModel.totalYield, economy.netYield);
    expect(viewModel.rowsMatchTotal, isTrue);
    expect(viewModel.growthEta.hasTurns, isFalse);
    expect(viewModel.growthEta.blockedLabel, isNotEmpty);
  });

  test('keeps wonder, stability, and multiplier rounding exact', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 1,
      center: CityHex(col: 0, row: 0),
    );
    const rawYield = TileYield(food: 4, production: 9, gold: 7, defense: 1);
    const tileBreakdown = CityTileYieldBreakdown(
      center: CityTileYieldContribution(
        kind: CityTileYieldContributionKind.center,
        hex: CityHex(col: 0, row: 0),
        yield: rawYield,
      ),
    );
    const economy = CityEconomyBreakdown(
      city: city,
      tileYield: rawYield,
      buildingYield: TileYield.zero,
      wonderYield: TileYield(food: 3, production: 2, gold: 2, defense: 1),
      technologyEffects: TechnologyEffectSummary(globalGoldMultiplier: 0.25),
      wonderGoldMultiplier: 0.2,
      wonderProductionMultiplier: 0.1,
      stabilityModifier: StabilityModifier(
        productionMultiplier: 0.75,
        goldMultiplier: 0.75,
        foodBonus: 0,
        haltsGrowth: true,
      ),
      populationUpkeep: 5,
      netFood: 2,
      foodDeposit: 0,
      growthCost: 10,
    );

    final viewModel = CityYieldBreakdownViewModel.from(
      city: city,
      tileBreakdown: tileBreakdown,
      economy: economy,
      l10n: l10n,
    );

    expect(
      viewModel.rows.singleWhere((row) => row.label == 'Wonders').yield,
      const TileYield(food: 3, production: 3, gold: 2, defense: 1),
    );
    expect(
      viewModel.rows.singleWhere((row) => row.label == 'Gold multiplier').yield,
      const TileYield(food: 0, production: 0, gold: 4, defense: 0),
    );
    expect(
      viewModel.rows
          .singleWhere((row) => row.label == l10n.stabilityBreakdownBand)
          .yield,
      const TileYield(food: 0, production: -4, gold: -4, defense: 0),
    );
    expect(
      viewModel.rows.singleWhere((row) => row.label == 'Upkeep').yield,
      const TileYield(food: -5, production: 0, gold: 0, defense: 0),
    );
    expect(
      viewModel.totalYield,
      const TileYield(food: 2, production: 8, gold: 9, defense: 2),
    );
    expect(viewModel.rowsMatchTotal, isTrue);
  });

  test('uses content food bonus in projected growth ETA', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      population: 1,
      center: CityHex(col: 0, row: 0),
    );
    const rawYield = TileYield(food: 4, production: 1, gold: 0, defense: 0);
    const tileBreakdown = CityTileYieldBreakdown(
      center: CityTileYieldContribution(
        kind: CityTileYieldContributionKind.center,
        hex: CityHex(col: 0, row: 0),
        yield: rawYield,
      ),
    );
    const economy = CityEconomyBreakdown(
      city: city,
      tileYield: rawYield,
      buildingYield: TileYield.zero,
      stabilityModifier: StabilityModifier(
        productionMultiplier: 1,
        goldMultiplier: 1,
        foodBonus: 1,
        haltsGrowth: false,
      ),
      populationUpkeep: 1,
      netFood: 3,
      foodDeposit: 4,
      growthCost: 8,
    );

    final viewModel = CityYieldBreakdownViewModel.from(
      city: city,
      tileBreakdown: tileBreakdown,
      economy: economy,
      currentTurn: 2,
      l10n: l10n,
    );

    expect(
      viewModel.rows
          .singleWhere((row) => row.label == l10n.stabilityBreakdownBand)
          .detail,
      l10n.stabilityBandContent,
    );
    expect(viewModel.growthEta.compactLabel(l10n), '2 turns • T4');
    expect(viewModel.rowsMatchTotal, isTrue);
  });

  test('labels every stability modifier band', () {
    final text = CityYieldBreakdownText(l10n);

    expect(
      [
        for (final band in StabilityBand.values)
          text.stabilityDetail(StabilityPolicy.modifierFor(band)),
      ],
      [
        l10n.stabilityBandContent,
        l10n.stabilityBandStable,
        l10n.stabilityBandStrained,
        l10n.stabilityBandUnrest,
      ],
    );
  });
}

({
  GameCity city,
  CityTileYieldBreakdown tileBreakdown,
  CityEconomyBreakdown economy,
})
_realEconomySourcesFixture() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    population: 2,
    storedFood: 4,
    center: CityHex(col: 1, row: 1),
    buildings: {CityBuildingType.workshop, CityBuildingType.archive},
    specialization: CitySpecializationType.science,
  );
  const tileBreakdown = CityTileYieldBreakdown(
    center: CityTileYieldContribution(
      kind: CityTileYieldContributionKind.center,
      hex: CityHex(col: 1, row: 1),
      yield: TileYield(food: 2, production: 1, gold: 0, defense: 0),
    ),
    population: [
      CityTileYieldContribution(
        kind: CityTileYieldContributionKind.population,
        hex: CityHex(col: 2, row: 1),
        yield: TileYield(food: 2, production: 2, gold: 0, defense: 0),
      ),
    ],
    workers: [
      CityTileYieldContribution(
        kind: CityTileYieldContributionKind.worker,
        hex: CityHex(col: 2, row: 2),
        yield: TileYield(food: 3, production: 0, gold: 0, defense: 0),
      ),
    ],
    passiveImprovements: [
      CityTileYieldContribution(
        kind: CityTileYieldContributionKind.passiveImprovement,
        hex: CityHex(col: 0, row: 1),
        yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
      ),
    ],
    artifacts: [
      CityTileYieldContribution(
        kind: CityTileYieldContributionKind.artifact,
        hex: CityHex(col: 1, row: 1),
        yield: TileYield(food: 1, production: 0, gold: 0, defense: 1),
      ),
    ],
  );
  final economy = CityEconomyBreakdown(
    city: city,
    tileYield: tileBreakdown.total,
    buildingYield: const TileYield(food: 0, production: 2, gold: 1, defense: 0),
    specializationYield: const TileYield(
      food: 0,
      production: 0,
      gold: 3,
      defense: 0,
    ),
    technologyYield: const TileYield(
      food: 0,
      production: 1,
      gold: 0,
      defense: 1,
    ),
    technologyEffects: const TechnologyEffectSummary(
      globalGoldMultiplier: 0.25,
      cityScienceBonus: 1,
    ),
    populationUpkeep: 3,
    netFood: 6,
    foodDeposit: 6,
    growthCost: 16,
  );
  return (city: city, tileBreakdown: tileBreakdown, economy: economy);
}
