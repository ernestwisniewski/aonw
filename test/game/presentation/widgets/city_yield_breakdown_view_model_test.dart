import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test(
    'CityYieldBreakdownViewModel maps real economy sources and matches total',
    () {
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
      );
      final economy = CityEconomyBreakdown(
        city: city,
        tileYield: tileBreakdown.total,
        buildingYield: const TileYield(
          food: 0,
          production: 2,
          gold: 1,
          defense: 0,
        ),
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
        netFood: 5,
        foodDeposit: 5,
        growthCost: 16,
      );

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
      expect(viewModel.growthEta.compactLabel(l10n), '3 turns • T7');
      expect(
        viewModel.rows.map((row) => row.label),
        containsAll([
          'Center',
          'Population fields',
          'Workers',
          'Improvements',
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
}
