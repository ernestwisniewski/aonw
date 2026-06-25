import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_breakdown.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/city_worked_hex_selector.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class CityYieldCalculator {
  static const int passiveImprovementYieldNumerator = 1;
  static const int passiveImprovementYieldDenominator = 2;

  static TileYield totalFor(
    GameCity city,
    MapData mapData, {
    Iterable<FieldImprovement> fieldImprovements = const [],
    Iterable<GameUnit> units = const [],
    Iterable<WorldArtifact> artifacts = const [],
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    return breakdownFor(
      city,
      mapData,
      fieldImprovements: fieldImprovements,
      units: units,
      artifacts: artifacts,
      ruleset: ruleset,
    ).total;
  }

  static CityTileYieldBreakdown breakdownFor(
    GameCity city,
    MapData mapData, {
    Iterable<FieldImprovement> fieldImprovements = const [],
    Iterable<GameUnit> units = const [],
    Iterable<WorldArtifact> artifacts = const [],
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final assignedWorkerHexes = _assignedWorkerHexes(
      city: city,
      units: units,
      fieldImprovements: fieldImprovements,
    );
    final workedHexes = CityWorkedHexSelector.effectiveWorkedHexes(
      city: city,
      mapData: mapData,
      fieldImprovements: fieldImprovements,
      ruleset: ruleset,
    ).toSet();
    final fullYieldHexes = {...workedHexes, ...assignedWorkerHexes};
    final passiveImprovedHexes = _passiveImprovedHexes(
      city: city,
      fieldImprovements: fieldImprovements,
      fullYieldHexes: fullYieldHexes,
    );

    final centerTile = mapData.tileAt(city.center.col, city.center.row);
    final centerYield = CityTileYieldRules.forCityHex(
      city: city,
      hex: city.center,
      tile: centerTile,
      fieldImprovements: fieldImprovements,
      ruleset: ruleset,
    );
    final populationContributions = <CityTileYieldContribution>[];
    for (final hex in workedHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      final tileYield = CityTileYieldRules.forCityHex(
        city: city,
        hex: hex,
        tile: tile,
        fieldImprovements: fieldImprovements,
        ruleset: ruleset,
      );
      populationContributions.add(
        CityTileYieldContribution(
          kind: CityTileYieldContributionKind.population,
          hex: hex,
          yield: tileYield,
        ),
      );
    }

    final workerContributions = <CityTileYieldContribution>[];
    for (final hex in assignedWorkerHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      final tileYield = CityTileYieldRules.forCityHex(
        city: city,
        hex: hex,
        tile: tile,
        fieldImprovements: fieldImprovements,
        ruleset: ruleset,
      );
      final workerFullYield = workedHexes.contains(hex)
          ? TileYield.zero
          : tileYield;
      final workerBonus = _workerAssignmentBonus(tileYield);
      final workerYield = workerFullYield + workerBonus;
      if (!_isZero(workerYield)) {
        workerContributions.add(
          CityTileYieldContribution(
            kind: CityTileYieldContributionKind.worker,
            hex: hex,
            yield: workerYield,
          ),
        );
      }
    }

    final passiveContributions = <CityTileYieldContribution>[];
    for (final improvement in passiveImprovedHexes) {
      final passiveYield = passiveImprovementYieldFor(
        improvement.type,
        ruleset: ruleset,
      );
      if (!_isZero(passiveYield)) {
        passiveContributions.add(
          CityTileYieldContribution(
            kind: CityTileYieldContributionKind.passiveImprovement,
            hex: improvement.hex,
            yield: passiveYield,
          ),
        );
      }
    }

    final artifactYield = WorldArtifactBonuses.cityYieldFor(
      cityId: city.id,
      artifacts: artifacts,
    );
    final artifactContributions = _isZero(artifactYield)
        ? const <CityTileYieldContribution>[]
        : [
            CityTileYieldContribution(
              kind: CityTileYieldContributionKind.artifact,
              hex: city.center,
              yield: artifactYield,
            ),
          ];

    return CityTileYieldBreakdown(
      center: CityTileYieldContribution(
        kind: CityTileYieldContributionKind.center,
        hex: city.center,
        yield: centerYield,
      ),
      population: List.unmodifiable(populationContributions),
      workers: List.unmodifiable(workerContributions),
      passiveImprovements: List.unmodifiable(passiveContributions),
      artifacts: List.unmodifiable(artifactContributions),
    );
  }

  static List<FieldImprovement> _passiveImprovedHexes({
    required GameCity city,
    required Iterable<FieldImprovement> fieldImprovements,
    required Set<CityHex> fullYieldHexes,
  }) {
    return [
      for (final improvement in fieldImprovements)
        if (improvement.hex != city.center &&
            city.controlsHex(improvement.hex) &&
            !fullYieldHexes.contains(improvement.hex))
          improvement,
    ];
  }

  static Set<CityHex> _assignedWorkerHexes({
    required GameCity city,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
  }) {
    final improvedHexes = {
      for (final improvement in fieldImprovements) improvement.hex,
    };
    return {
      for (final unit in units)
        if (unit.ownerPlayerId == city.ownerPlayerId)
          if (unit.workerAssignment case final assignment?)
            if (unit.occupies(
                  assignment.targetHex.col,
                  assignment.targetHex.row,
                ) &&
                assignment.targetHex != city.center &&
                city.controlsHex(assignment.targetHex) &&
                improvedHexes.contains(assignment.targetHex))
              assignment.targetHex,
    };
  }

  static TileYield _workerAssignmentBonus(TileYield base) {
    return workerAssignmentBonusFor(base);
  }

  static TileYield workerAssignmentBonusFor(TileYield base) {
    return TileYield(
      food: _halfRoundedUp(base.food),
      production: _halfRoundedUp(base.production),
      gold: _halfRoundedUp(base.gold),
      defense: 0,
    );
  }

  static TileYield passiveImprovementYieldFor(
    FieldImprovementType improvement, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final base = CityTileYieldRules.improvementYield(
      improvement,
      ruleset: ruleset,
    );
    return TileYield(
      food: _scaledRoundedUp(
        base.food,
        passiveImprovementYieldNumerator,
        passiveImprovementYieldDenominator,
      ),
      production: _scaledRoundedUp(
        base.production,
        passiveImprovementYieldNumerator,
        passiveImprovementYieldDenominator,
      ),
      gold: _scaledRoundedUp(
        base.gold,
        passiveImprovementYieldNumerator,
        passiveImprovementYieldDenominator,
      ),
      defense: _scaledRoundedUp(
        base.defense,
        passiveImprovementYieldNumerator,
        passiveImprovementYieldDenominator,
      ),
    );
  }

  static int _halfRoundedUp(int value) {
    return _scaledRoundedUp(value, 1, 2);
  }

  static int _scaledRoundedUp(int value, int numerator, int denominator) {
    if (value <= 0) return 0;
    return (value * numerator + denominator - 1) ~/ denominator;
  }

  static bool _isZero(TileYield yield) {
    return yield.food == 0 &&
        yield.production == 0 &&
        yield.gold == 0 &&
        yield.defense == 0;
  }
}
