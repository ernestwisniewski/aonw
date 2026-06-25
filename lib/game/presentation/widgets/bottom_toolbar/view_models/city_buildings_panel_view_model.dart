import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';

enum CityBuildingCardState { built, inProgress, available, locked }

class CityBuildingCardViewModel {
  final CityBuildingType type;
  final CityBuildingCardState state;
  final int investedProduction;
  final int totalCost;
  final int productionPerTurn;
  final int? turnsRemaining;
  final String displayName;
  final String emoji;
  final String? requirementLabel;

  const CityBuildingCardViewModel({
    required this.type,
    required this.state,
    required this.investedProduction,
    required this.totalCost,
    required this.productionPerTurn,
    required this.turnsRemaining,
    required this.displayName,
    required this.emoji,
    this.requirementLabel,
  });
}

class CityBuildingsPanelViewModel {
  final String cityName;
  final List<CityBuildingCardViewModel> buildings;

  CityBuildingCardViewModel? get activeBuilding => buildings
      .where((b) => b.state == CityBuildingCardState.inProgress)
      .firstOrNull;

  const CityBuildingsPanelViewModel({
    required this.cityName,
    required this.buildings,
  });
}

abstract final class CityBuildingsPanelViewModelFactory {
  static String displayNameFor(AppLocalizations l10n, CityBuildingType type) =>
      GameDisplayNames.cityBuilding(l10n, type);

  static String emojiFor(CityBuildingType type) => switch (type) {
    CityBuildingType.granary => '🌾',
    CityBuildingType.waterMill => '💧',
    CityBuildingType.workshop => '🏭',
    CityBuildingType.storehouse => '🏬',
    CityBuildingType.housing => '🏠',
    CityBuildingType.merchantHall => '⚖️',
    CityBuildingType.stonemason => '🧱',
    CityBuildingType.barracks => '🛡️',
    CityBuildingType.marketplace => '💰',
    CityBuildingType.port => '⚓',
    CityBuildingType.aqueduct => '🌊',
    CityBuildingType.forge => '🔥',
    CityBuildingType.stable => '♞',
    CityBuildingType.bank => '🏦',
    CityBuildingType.buildersGuild => '🧰',
    CityBuildingType.factory => '⚙️',
    CityBuildingType.lighthouse => '🗼',
    CityBuildingType.trainingGrounds => '🎯',
    CityBuildingType.townHall => '🏛️',
    CityBuildingType.monument => '🗿',
    CityBuildingType.archive => '📜',
    CityBuildingType.academy => '🎓',
    CityBuildingType.university => '🎓',
    CityBuildingType.observatory => '🔭',
    CityBuildingType.laboratory => '🧪',
    CityBuildingType.reactor => '⚛️',
    CityBuildingType.courthouse => '⚖️',
    CityBuildingType.court => '⚖️',
    CityBuildingType.governorsOffice => '🏛️',
    CityBuildingType.surveyorsOffice => '🗺️',
    CityBuildingType.planningOffice => '🏙️',
    CityBuildingType.apothecary => '⚕️',
    CityBuildingType.publicBaths => '♨️',
    CityBuildingType.hospital => '🏥',
    CityBuildingType.ministries => '🏛️',
    CityBuildingType.walls => '🧱',
    CityBuildingType.armory => '⚔️',
    CityBuildingType.siegeWorkshop => '🏗️',
    CityBuildingType.citadel => '🏰',
    CityBuildingType.warCollege => '🎖️',
    CityBuildingType.conscriptionOffice => '🪖',
    CityBuildingType.borderFort => '🏰',
    CityBuildingType.airfield => '✈️',
    CityBuildingType.artisansGuild => '🧰',
    CityBuildingType.masterWorkshop => '🛠️',
    CityBuildingType.steelworks => '🏭',
    CityBuildingType.railDepot => '🚂',
    CityBuildingType.powerPlant => '⚡',
    CityBuildingType.assemblyPlant => '🏭',
    CityBuildingType.refinery => '🛢️',
    CityBuildingType.mapRoom => '🗺️',
    CityBuildingType.shipyard => '⚓',
    CityBuildingType.dryDock => '⚓',
    CityBuildingType.navalAcademy => '⚓',
    CityBuildingType.harborCustoms => '⚓',
    CityBuildingType.museum => '🏛️',
    CityBuildingType.parliament => '🏛️',
    CityBuildingType.broadcastTower => '📡',
    CityBuildingType.worldFairGrounds => '🎪',
  };

  static CityBuildingsPanelViewModel from(
    GameCity city, {
    required AppLocalizations l10n,
    CityRuleset cityRuleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    MapData? mapData,
    int productionPerTurn = 1,
    String? cityName,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final queue = city.productionQueue;
    final queuedBuildingType = switch (queue?.target) {
      BuildingProductionTarget(:final buildingType) => buildingType,
      UnitProductionTarget() => null,
      ProjectProductionTarget() => null,
      null => null,
    };
    final effectiveProductionPerTurn = CityProductionRules.productionPerTurn(
      productionPerTurn,
    );
    final cards = CityBuildingType.values.map((type) {
      final cost = CityProductionRules.buildingProductionCost(
        type,
        ruleset: cityRuleset,
        paceBalance: paceBalance,
      );
      int? turnsRemaining(int investedProduction) {
        return CityProductionRules.estimatedTurnsRemaining(
          productionCost: cost,
          investedProduction: investedProduction,
          productionPerTurn: effectiveProductionPerTurn,
        );
      }

      if (city.buildings.contains(type)) {
        return CityBuildingCardViewModel(
          type: type,
          state: CityBuildingCardState.built,
          investedProduction: cost,
          totalCost: cost,
          productionPerTurn: effectiveProductionPerTurn,
          turnsRemaining: 0,
          displayName: displayNameFor(l10n, type),
          emoji: emojiFor(type),
        );
      }
      if (queue != null && queuedBuildingType == type) {
        return CityBuildingCardViewModel(
          type: type,
          state: CityBuildingCardState.inProgress,
          investedProduction: queue.investedProduction,
          totalCost: cost,
          productionPerTurn: effectiveProductionPerTurn,
          turnsRemaining: turnsRemaining(queue.investedProduction),
          displayName: displayNameFor(l10n, type),
          emoji: emojiFor(type),
        );
      }
      final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
        playerId: city.ownerPlayerId,
        buildingType: type,
        research: research,
        ruleset: technologyRuleset,
      );
      final requirementsMet = mapData == null
          ? true
          : CityBuildingRequirementRules.meetsRequirements(
              city: city,
              buildingType: type,
              mapData: mapData,
              ruleset: cityRuleset,
              research: research,
            );
      if (!technologyUnlocked || !requirementsMet) {
        return CityBuildingCardViewModel(
          type: type,
          state: CityBuildingCardState.locked,
          investedProduction: 0,
          totalCost: cost,
          productionPerTurn: effectiveProductionPerTurn,
          turnsRemaining: turnsRemaining(0),
          displayName: displayNameFor(l10n, type),
          emoji: emojiFor(type),
          requirementLabel: _requirementLabel(
            l10n,
            type,
            technologyRuleset,
            cityRuleset,
            locationRequirementMissing: technologyUnlocked && !requirementsMet,
          ),
        );
      }
      return CityBuildingCardViewModel(
        type: type,
        state: CityBuildingCardState.available,
        investedProduction: 0,
        totalCost: cost,
        productionPerTurn: effectiveProductionPerTurn,
        turnsRemaining: turnsRemaining(0),
        displayName: displayNameFor(l10n, type),
        emoji: emojiFor(type),
      );
    }).toList();

    return CityBuildingsPanelViewModel(
      cityName: cityName ?? GameDisplayNames.city(l10n, city),
      buildings: cards,
    );
  }

  static String _requirementLabel(
    AppLocalizations l10n,
    CityBuildingType type,
    TechnologyRuleset technologyRuleset,
    CityRuleset cityRuleset, {
    bool locationRequirementMissing = false,
  }) {
    if (locationRequirementMissing) {
      return _locationRequirementLabel(l10n, type, cityRuleset);
    }
    final technology = TechnologyUnlockQuery.unlockingTechnologyForBuilding(
      buildingType: type,
      ruleset: technologyRuleset,
    );
    return technology != null
        ? l10n.requirementTechnologyName(
            GameDisplayNames.technology(l10n, technology.id),
          )
        : l10n.requirementTechnology;
  }

  static String _locationRequirementLabel(
    AppLocalizations l10n,
    CityBuildingType type,
    CityRuleset cityRuleset,
  ) {
    final definition = cityRuleset.buildingDefinitionFor(type);
    if (definition.requirements.any(
      (requirement) => requirement is CoastalAccessRequirement,
    )) {
      return l10n.requirementCoastalAccess;
    }
    for (final requirement in definition.requirements) {
      if (requirement is CityResourceRequirement) {
        return l10n.requirementResourcesName(
          _joinResourceNames(l10n, requirement.resources),
        );
      }
    }
    return l10n.requirementTechnology;
  }

  static String _joinResourceNames(
    AppLocalizations l10n,
    Set<ResourceType> resources,
  ) {
    final names =
        resources
            .map((resource) => GameDisplayNames.resource(l10n, resource))
            .toList()
          ..sort();
    if (names.isEmpty) return l10n.requirementTechnology;
    if (names.length == 1) return names.single;
    return '${names.take(names.length - 1).join(', ')} lub ${names.last}';
  }
}
