import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

abstract final class SelectionResourceValueCardFactory {
  static List<SelectionResourceValueCard> fromTile({
    required TileData tile,
    required HexAssessment assessment,
    required GameState? gameState,
    required AppLocalizations l10n,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required String Function(ResourceType type) resourceName,
    required String Function(GameCity city) cityName,
  }) {
    return [
      for (final resource in tile.resources)
        _cardFor(
          resource: resource,
          tile: tile,
          tileYield: assessment.yield,
          gameState: gameState,
          l10n: l10n,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          improvementName: improvementName,
          technologyName: technologyName,
          resourceName: resourceName,
          cityName: cityName,
        ),
    ];
  }

  static SelectionResourceValueCard _cardFor({
    required ResourceType resource,
    required TileData tile,
    required TileYield tileYield,
    required GameState? gameState,
    required AppLocalizations l10n,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required String Function(ResourceType type) resourceName,
    required String Function(GameCity city) cityName,
  }) {
    final resourceYield = ResourceYieldRules.yieldFor(
      resource,
      ruleset: cityRuleset,
    );
    final improvementType = _preferredImprovementForResource(
      resource: resource,
      tile: tile,
      ruleset: cityRuleset,
    );
    final improvementYield = improvementType == null
        ? TileYield.zero
        : FieldImprovementRules.yieldFor(improvementType, ruleset: cityRuleset);
    final requiredTechnology = improvementType == null
        ? null
        : TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
            improvementType: improvementType,
            ruleset: technologyRuleset,
          );
    final technologyUnlocked = requiredTechnology == null
        ? true
        : _hasTechnologyUnlocked(gameState, requiredTechnology.id);
    final cityStatus = _cityStatusFor(
      tile: tile,
      gameState: gameState,
      l10n: l10n,
      cityName: cityName,
    );
    final category = _categoryFor(resource);
    final resourceLabel = resourceName(resource);
    final improvementLabel = improvementType == null
        ? l10n.resourceValueNoMatchingImprovement
        : improvementName(improvementType);
    final improvementStatus = _improvementStatus(
      improvementType: improvementType,
      requiredTechnology: requiredTechnology,
      technologyUnlocked: technologyUnlocked,
      technologyName: technologyName,
      l10n: l10n,
      cityStatus: cityStatus,
    );

    return SelectionResourceValueCard(
      title: resourceLabel,
      categoryLabel: _categoryLabel(l10n, category),
      currentSummary: _currentResourceSummary(
        l10n: l10n,
        resourceYield: resourceYield,
        tileYield: tileYield,
      ),
      currentYield: _nonZeroYieldItems(l10n, tileYield),
      improvementTitle: improvementLabel,
      improvementStatus: improvementStatus.label,
      improvementStatusKind: improvementStatus.kind,
      requiredTechnologyName: improvementStatus.requiredTechnologyName,
      improvementYield: _nonZeroYieldItems(l10n, improvementYield),
      futureLines: _futureLinesFor(
        resource: resource,
        category: category,
        improvementType: improvementType,
        requiredTechnology: requiredTechnology,
        technologyUnlocked: technologyUnlocked,
        technologyRuleset: technologyRuleset,
        improvementName: improvementName,
        technologyName: technologyName,
        l10n: l10n,
      ),
      expansionReason: _expansionReasonFor(
        l10n: l10n,
        resource: resource,
        category: category,
        tileYield: tileYield,
        improvementYield: improvementYield,
      ),
      accentColor: category.color,
    );
  }

  static FieldImprovementType? _preferredImprovementForResource({
    required ResourceType resource,
    required TileData tile,
    required CityRuleset ruleset,
  }) {
    final specialistTypes = <FieldImprovementType>{
      for (final definition in ruleset.improvements.values)
        if (definition.resourceSpecialist &&
            definition.requirements.whereType<RequiresAnyResource>().any(
              (requirement) => requirement.resources.contains(resource),
            ))
          definition.type,
    };
    final specialist = FieldImprovementRules.preferredFor(
      tile,
      ruleset: ruleset,
      allowedTypes: specialistTypes,
    );
    if (specialist != null) return specialist;
    return FieldImprovementRules.preferredFor(tile, ruleset: ruleset);
  }

  static _TileCityStatus _cityStatusFor({
    required TileData tile,
    required GameState? gameState,
    required AppLocalizations l10n,
    required String Function(GameCity city) cityName,
  }) {
    if (gameState == null) {
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueSelectWorkerOrCity,
        hasCityAccess: false,
        kind: SelectionResourceImprovementStatusKind.selectWorkerOrCity,
      );
    }

    final hex = CityHex(col: tile.col, row: tile.row);
    if (gameState.fieldImprovements.any(
      (improvement) => improvement.hex == hex,
    )) {
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueTileAlreadyImproved,
        hasCityAccess: false,
        kind: SelectionResourceImprovementStatusKind.tileAlreadyImproved,
      );
    }
    if (gameState.cities.any((city) => city.center == hex)) {
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueCityCenter,
        hasCityAccess: false,
        kind: SelectionResourceImprovementStatusKind.cityCenter,
      );
    }

    final city = WorkerImprovementRules.cityForImprovementHex(
      playerId: gameState.activePlayerId,
      hex: hex,
      cities: gameState.cities,
    );
    if (city != null) {
      final name = cityName(city);
      return _TileCityStatus(
        cityRequirement: l10n.resourceValueWorksForCity(name),
        hasCityAccess: true,
        kind: SelectionResourceImprovementStatusKind.availableForWorker,
      );
    }

    return _TileCityStatus(
      cityRequirement: l10n.resourceValueOutsideCityBorders,
      hasCityAccess: false,
      kind: SelectionResourceImprovementStatusKind.outsideCityBorders,
    );
  }

  static bool _hasTechnologyUnlocked(
    GameState? gameState,
    TechnologyId technologyId,
  ) {
    if (gameState == null) return false;
    return gameState.research
        .forPlayer(gameState.activePlayerId)
        .hasUnlocked(technologyId);
  }

  static _ImprovementStatus _improvementStatus({
    required FieldImprovementType? improvementType,
    required TechnologyDefinition? requiredTechnology,
    required bool technologyUnlocked,
    required String Function(TechnologyId id) technologyName,
    required AppLocalizations l10n,
    required _TileCityStatus cityStatus,
  }) {
    if (improvementType == null) {
      return _ImprovementStatus(
        label: l10n.resourceValueNoLegalImprovementForTile,
        kind: SelectionResourceImprovementStatusKind.noLegalImprovementForTile,
      );
    }
    if (!cityStatus.hasCityAccess) {
      return _ImprovementStatus(
        label: cityStatus.cityRequirement,
        kind: cityStatus.kind,
      );
    }
    if (!technologyUnlocked && requiredTechnology != null) {
      final name = technologyName(requiredTechnology.id);
      return _ImprovementStatus(
        label: l10n.resourceValueRequiresTechnology(name),
        kind: SelectionResourceImprovementStatusKind.requiresTechnology,
        requiredTechnologyName: name,
      );
    }
    return _ImprovementStatus(
      label: l10n.resourceValueAvailableForWorker,
      kind: SelectionResourceImprovementStatusKind.availableForWorker,
    );
  }

  static List<String> _futureLinesFor({
    required ResourceType resource,
    required _ResourceValueCategory category,
    required FieldImprovementType? improvementType,
    required TechnologyDefinition? requiredTechnology,
    required bool technologyUnlocked,
    required TechnologyRuleset technologyRuleset,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required AppLocalizations l10n,
  }) {
    final lines = <String>[];

    if (improvementType != null && requiredTechnology != null) {
      final techName = technologyName(requiredTechnology.id);
      final improvementLabel = improvementName(improvementType);
      lines.add(
        technologyUnlocked
            ? l10n.resourceValueUnlockedByTechnology(techName, improvementLabel)
            : l10n.resourceValueUnlocksFullYieldAfterTechnology(
                techName,
                improvementLabel,
              ),
      );
    }

    for (final technology in technologyRuleset.technologies.values) {
      final techName = technologyName(technology.id);
      for (final boost in technology.boosts) {
        if (_boostMentionsResource(boost.condition, resource)) {
          lines.add(
            l10n.resourceValueResearchBoostLine(
              techName,
              _percent(boost.discount),
            ),
          );
        }
      }
      for (final effect in technology.effects) {
        final line = _effectLineFor(
          effect: effect,
          resource: resource,
          technologyName: techName,
          l10n: l10n,
        );
        if (line != null) lines.add(line);
      }
    }

    if (lines.isEmpty) lines.add(_categoryDefaultFutureLine(l10n, category));
    return _distinctPrefix(lines, limit: 3);
  }

  static bool _boostMentionsResource(
    TechnologyBoostCondition condition,
    ResourceType resource,
  ) {
    return switch (condition) {
      ControlsResource(:final resourceType) => resourceType == resource,
      ControlsAnyResource(:final resourceTypes) => resourceTypes.contains(
        resource,
      ),
      HasImprovementCount() || HasAnyImprovement() => false,
    };
  }

  static String? _effectLineFor({
    required TechnologyEffect effect,
    required ResourceType resource,
    required String technologyName,
    required AppLocalizations l10n,
  }) {
    return switch (effect) {
      StrategicResourceProductionBonus(:final resourceType, :final production)
          when resourceType == resource =>
        l10n.resourceValueTechnologyControlledResourceBonus(
          technologyName,
          production,
        ),
      _ => null,
    };
  }

  static List<String> _distinctPrefix(
    List<String> lines, {
    required int limit,
  }) {
    final result = <String>[];
    for (final line in lines) {
      if (result.contains(line)) continue;
      result.add(line);
      if (result.length >= limit) break;
    }
    return result;
  }

  static String _currentResourceSummary({
    required AppLocalizations l10n,
    required TileYield resourceYield,
    required TileYield tileYield,
  }) {
    if (resourceYield == TileYield.zero) {
      return l10n.resourceValueNoBaseYieldSummary(_yieldText(l10n, tileYield));
    }
    return l10n.resourceValueBaseYieldSummary(
      _yieldText(l10n, resourceYield),
      _yieldText(l10n, tileYield),
    );
  }

  static String _expansionReasonFor({
    required AppLocalizations l10n,
    required ResourceType resource,
    required _ResourceValueCategory category,
    required TileYield tileYield,
    required TileYield improvementYield,
  }) {
    final combined = tileYield + improvementYield;
    if (category.kind == _ResourceValueCategoryKind.strategic) {
      return l10n.resourceValueExpansionStrategic;
    }
    if (combined.food >= combined.production &&
        combined.food >= combined.gold) {
      return l10n.resourceValueExpansionFood;
    }
    if (combined.production >= combined.gold) {
      return l10n.resourceValueExpansionProduction;
    }
    if (resource == ResourceType.pearls || resource == ResourceType.ivory) {
      return l10n.resourceValueExpansionTrade;
    }
    return l10n.resourceValueExpansionEconomy;
  }

  static String _yieldText(AppLocalizations l10n, TileYield yield) {
    final parts = <String>[
      if (yield.food != 0) l10n.resourceValueYieldFood(yield.food),
      if (yield.production != 0)
        l10n.resourceValueYieldProduction(yield.production),
      if (yield.gold != 0) l10n.resourceValueYieldGold(yield.gold),
      if (yield.defense != 0) l10n.resourceValueYieldDefense(yield.defense),
    ];
    if (parts.isEmpty) {
      return l10n.resourceValueZeroBaseYield;
    }
    return parts.join(', ');
  }

  static String _categoryLabel(
    AppLocalizations l10n,
    _ResourceValueCategory category,
  ) {
    return switch (category.kind) {
      _ResourceValueCategoryKind.bonus => l10n.resourceValueCategoryBonus,
      _ResourceValueCategoryKind.luxury => l10n.resourceValueCategoryLuxury,
      _ResourceValueCategoryKind.strategic =>
        l10n.resourceValueCategoryStrategic,
    };
  }

  static String _categoryDefaultFutureLine(
    AppLocalizations l10n,
    _ResourceValueCategory category,
  ) {
    return switch (category.kind) {
      _ResourceValueCategoryKind.bonus => l10n.resourceValueCategoryBonusFuture,
      _ResourceValueCategoryKind.luxury =>
        l10n.resourceValueCategoryLuxuryFuture,
      _ResourceValueCategoryKind.strategic =>
        l10n.resourceValueCategoryStrategicFuture,
    };
  }

  static List<SelectionYieldItem> _nonZeroYieldItems(
    AppLocalizations l10n,
    TileYield yield,
  ) {
    return SelectionYieldItem.fromYield(
      yield,
      foodLabel: l10n.yieldFoodShort,
      productionLabel: l10n.yieldProductionShort,
      goldLabel: l10n.yieldGoldShort,
      defenseLabel: l10n.yieldDefenseShort,
    ).where((item) => item.value != 0).toList(growable: false);
  }

  static _ResourceValueCategory _categoryFor(ResourceType resource) {
    if (HexResourceGroups.strategic.contains(resource)) {
      return _ResourceValueCategory.strategic;
    }
    if (_luxuryResources.contains(resource)) {
      return _ResourceValueCategory.luxury;
    }
    return _ResourceValueCategory.bonus;
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static const _luxuryResources = {
    ResourceType.gold,
    ResourceType.silver,
    ResourceType.gems,
    ResourceType.silk,
    ResourceType.spices,
    ResourceType.cotton,
    ResourceType.grapes,
    ResourceType.ivory,
    ResourceType.pearls,
    ResourceType.coffee,
    ResourceType.cocoa,
    ResourceType.tobacco,
    ResourceType.sugar,
  };
}

class _TileCityStatus {
  final String cityRequirement;
  final bool hasCityAccess;
  final SelectionResourceImprovementStatusKind kind;

  const _TileCityStatus({
    required this.cityRequirement,
    required this.hasCityAccess,
    required this.kind,
  });
}

class _ImprovementStatus {
  final String label;
  final SelectionResourceImprovementStatusKind kind;
  final String? requiredTechnologyName;

  const _ImprovementStatus({
    required this.label,
    required this.kind,
    this.requiredTechnologyName,
  });
}

enum _ResourceValueCategoryKind { bonus, luxury, strategic }

class _ResourceValueCategory {
  final _ResourceValueCategoryKind kind;
  final Color color;

  const _ResourceValueCategory({required this.kind, required this.color});

  static const bonus = _ResourceValueCategory(
    kind: _ResourceValueCategoryKind.bonus,
    color: Color(0xFF87c96a),
  );

  static const luxury = _ResourceValueCategory(
    kind: _ResourceValueCategoryKind.luxury,
    color: Color(0xFFe0c35c),
  );

  static const strategic = _ResourceValueCategory(
    kind: _ResourceValueCategoryKind.strategic,
    color: Color(0xFF8da8e8),
  );
}
