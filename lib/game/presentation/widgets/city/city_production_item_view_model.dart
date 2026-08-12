import 'package:aonw/game/presentation/formatters/game_wonder_display_names.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

class CityProductionItem {
  const CityProductionItem({
    required this.buildingType,
    required this.unitType,
    required this.projectType,
    required this.title,
    required this.emoji,
    required this.icon,
    required this.active,
    required this.investedProduction,
    required this.totalCost,
    required this.productionPerTurn,
    required this.turnsRemaining,
    required this.rushGoldCost,
    required this.locked,
    required this.requirementLabel,
    required this.buildingState,
    this.wonderType,
    this.buildingSortMetrics = CityProductionSortMetrics.zero,
    this.metaLabels = const [],
    this.continuous = false,
    this.eta = const TurnEta.blocked(),
    this.strategicResourceLabel,
    this.strategicResourceShortage = false,
    this.unitAvailability,
    this.unitRequirementLabels = const [],
    this.spawnBlocked = false,
  });

  final CityBuildingType? buildingType;
  final GameUnitType? unitType;
  final CityProjectType? projectType;
  final WonderType? wonderType;
  final String title;
  final String? emoji;
  final GameIconData? icon;
  final bool active;
  final int investedProduction;
  final int totalCost;
  final int productionPerTurn;
  final int? turnsRemaining;
  final TurnEta eta;
  final int rushGoldCost;
  final bool locked;
  final String? requirementLabel;
  final CityBuildingCardState? buildingState;
  final CityProductionSortMetrics buildingSortMetrics;
  final List<String> metaLabels;
  final bool continuous;
  final String? strategicResourceLabel;
  final bool strategicResourceShortage;
  final UnitProductionAvailability? unitAvailability;
  final List<String> unitRequirementLabels;
  final bool spawnBlocked;

  List<String> get unitRequirementLines => [
    ?strategicResourceLabel,
    if (locked)
      ...(unitRequirementLabels.isEmpty
          ? [?requirementLabel]
          : unitRequirementLabels),
  ];

  factory CityProductionItem.building(
    CityBuildingCardViewModel viewModel, {
    required AppLocalizations l10n,
    int? currentTurn,
    CityProductionSortMetrics sortMetrics = CityProductionSortMetrics.zero,
  }) {
    return CityProductionItem(
      buildingType: viewModel.type,
      unitType: null,
      projectType: null,
      wonderType: null,
      title: viewModel.displayName,
      emoji: viewModel.emoji,
      icon: null,
      active: viewModel.state == CityBuildingCardState.inProgress,
      investedProduction: viewModel.investedProduction,
      totalCost: viewModel.totalCost,
      productionPerTurn: viewModel.productionPerTurn,
      turnsRemaining: viewModel.turnsRemaining,
      eta: TurnEtaFormatter.fromTurns(
        turnsRemaining: viewModel.turnsRemaining,
        currentTurn: currentTurn,
        blockedLabel: l10n.cityProductionNoProduction,
      ),
      rushGoldCost: _rushGoldCost(
        productionCost: viewModel.totalCost,
        investedProduction: viewModel.investedProduction,
        productionPerTurn: viewModel.productionPerTurn,
      ),
      locked: viewModel.state == CityBuildingCardState.locked,
      requirementLabel: viewModel.requirementLabel,
      buildingState: viewModel.state,
      buildingSortMetrics: sortMetrics,
    );
  }

  factory CityProductionItem.unit({
    required AppLocalizations l10n,
    required GameUnitType type,
    required String title,
    required bool active,
    required int investedProduction,
    required int totalCost,
    required int productionPerTurn,
    required int? turnsRemaining,
    int? currentTurn,
    bool locked = false,
    String? requirementLabel,
    List<String> metaLabels = const [],
    String? strategicResourceLabel,
    bool strategicResourceShortage = false,
    UnitProductionAvailability? unitAvailability,
    List<String> unitRequirementLabels = const [],
    bool spawnBlocked = false,
  }) {
    return CityProductionItem(
      buildingType: null,
      unitType: type,
      projectType: null,
      wonderType: null,
      title: title,
      emoji: null,
      icon: gameIconForUnitType(type),
      active: active,
      investedProduction: investedProduction,
      totalCost: totalCost,
      productionPerTurn: productionPerTurn,
      turnsRemaining: turnsRemaining,
      eta: TurnEtaFormatter.fromTurns(
        turnsRemaining: turnsRemaining,
        currentTurn: currentTurn,
        blockedLabel: l10n.cityProductionNoProduction,
      ),
      rushGoldCost: _rushGoldCost(
        productionCost: totalCost,
        investedProduction: investedProduction,
        productionPerTurn: productionPerTurn,
      ),
      locked: locked,
      requirementLabel: requirementLabel,
      buildingState: null,
      metaLabels: metaLabels,
      strategicResourceLabel: strategicResourceLabel,
      strategicResourceShortage: strategicResourceShortage,
      unitAvailability: unitAvailability,
      unitRequirementLabels: List.unmodifiable(unitRequirementLabels),
      spawnBlocked: spawnBlocked,
    );
  }

  factory CityProductionItem.project({
    required CityProjectType type,
    required int productionPerTurn,
    required bool active,
    required AppLocalizations l10n,
  }) {
    final output = CityProductionQueue.project(
      projectType: type,
    ).projectOutput(productionPerTurn: productionPerTurn)!;
    final continuousLabel = l10n.cityProductionContinuous;
    return CityProductionItem(
      buildingType: null,
      unitType: null,
      projectType: type,
      wonderType: null,
      title: _projectTitle(type, l10n),
      emoji: null,
      icon: _iconForProject(type),
      active: active,
      investedProduction: 0,
      totalCost: 0,
      productionPerTurn: productionPerTurn,
      turnsRemaining: null,
      eta: TurnEta.blocked(continuousLabel),
      rushGoldCost: 0,
      locked: false,
      requirementLabel: null,
      buildingState: null,
      continuous: true,
      metaLabels: [
        continuousLabel,
        switch (type) {
          CityProjectType.wealth => l10n.cityProjectGoldPerTurn(output.amount),
          CityProjectType.research => l10n.cityProjectSciencePerTurn(
            output.amount,
          ),
        },
      ],
    );
  }

  factory CityProductionItem.wonder({
    required AppLocalizations l10n,
    required WonderType type,
    required bool active,
    required int investedProduction,
    required int totalCost,
    required int productionPerTurn,
    required int? turnsRemaining,
    int? currentTurn,
    bool locked = false,
    String? requirementLabel,
    List<String> metaLabels = const [],
  }) {
    return CityProductionItem(
      buildingType: null,
      unitType: null,
      projectType: null,
      wonderType: type,
      title: WonderDisplayNames.wonder(l10n, type),
      emoji: null,
      icon: GameIcons.victory,
      active: active,
      investedProduction: investedProduction,
      totalCost: totalCost,
      productionPerTurn: productionPerTurn,
      turnsRemaining: turnsRemaining,
      eta: TurnEtaFormatter.fromTurns(
        turnsRemaining: turnsRemaining,
        currentTurn: currentTurn,
        blockedLabel: l10n.cityProductionNoProduction,
      ),
      rushGoldCost: _rushGoldCost(
        productionCost: totalCost,
        investedProduction: investedProduction,
        productionPerTurn: productionPerTurn,
      ),
      locked: locked,
      requirementLabel: requirementLabel,
      buildingState: null,
      metaLabels: metaLabels,
    );
  }

  double get progress {
    if (continuous) return 0;
    if (totalCost <= 0) return 0;
    return (investedProduction / totalCost).clamp(0.0, 1.0);
  }

  bool get canBeRushed => !continuous && active && rushGoldCost > 0;

  TurnEta get effectiveEta {
    if (eta.hasTurns || turnsRemaining == null) return eta;
    return TurnEtaFormatter.fromTurns(
      turnsRemaining: turnsRemaining,
      blockedLabel: eta.blockedLabel,
    );
  }
}

class CityProductionSortMetrics {
  const CityProductionSortMetrics({
    this.food = 0,
    this.production = 0,
    this.gold = 0,
    this.defense = 0,
    this.science = 0,
    this.maxControlledHexes = 0,
    this.foodDepositBonusPercent = 0,
  });

  static const zero = CityProductionSortMetrics();

  final int food;
  final int production;
  final int gold;
  final int defense;
  final int science;
  final int maxControlledHexes;
  final int foodDepositBonusPercent;
}

class CitySpecializationItem {
  const CitySpecializationItem({
    required this.type,
    required this.title,
    required this.icon,
    required this.active,
    required this.locked,
    required this.metaLabels,
    this.bestFit = false,
  });

  final CitySpecializationType type;
  final String title;
  final GameIconData icon;
  final bool active;
  final bool locked;
  final List<String> metaLabels;
  final bool bestFit;
}

int _rushGoldCost({
  required int productionCost,
  required int investedProduction,
  required int productionPerTurn,
}) {
  return CityProductionRules.rushGoldCost(
    productionCost: productionCost,
    investedProduction: investedProduction,
    productionPerTurn: productionPerTurn,
  );
}

String _projectTitle(CityProjectType type, AppLocalizations l10n) =>
    switch (type) {
      CityProjectType.wealth => l10n.cityProjectWealth,
      CityProjectType.research => l10n.cityProjectResearch,
    };

GameIconData _iconForProject(CityProjectType type) => switch (type) {
  CityProjectType.wealth => GameIcons.gold,
  CityProjectType.research => GameIcons.science,
};
