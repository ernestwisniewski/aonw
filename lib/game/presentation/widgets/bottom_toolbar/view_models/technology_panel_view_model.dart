import 'dart:math' as math;

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';

enum TechnologyCardState { researched, active, available, locked }

class TechnologyCardViewModel {
  final TechnologyId id;
  final TechnologyEra era;
  final TechnologyCardState state;
  final int progress;
  final int baseCost;
  final int totalCost;
  final int? turnsRemaining;
  final int? completionTurn;
  final bool boostActive;
  final List<TechnologyUnlock> unlocks;
  final List<TechnologyEffect> effects;
  final List<TechnologyBoostDefinition> boosts;
  final int treeColumn;
  final int treeRow;
  final List<TechnologyId> prerequisiteIds;
  final List<TechnologyId> blockedByTechnologyIds;

  const TechnologyCardViewModel({
    required this.id,
    this.era = TechnologyEra.foundation,
    required this.state,
    required this.progress,
    this.baseCost = 0,
    required this.totalCost,
    required this.turnsRemaining,
    this.completionTurn,
    required this.boostActive,
    this.unlocks = const [],
    this.effects = const [],
    this.boosts = const [],
    this.treeColumn = 0,
    this.treeRow = 0,
    this.prerequisiteIds = const [],
    this.blockedByTechnologyIds = const [],
  });

  double get progressRatio {
    if (totalCost <= 0) return 0;
    return (progress / totalCost).clamp(0.0, 1.0);
  }

  bool get canSelect => state == TechnologyCardState.available;

  TurnEta get eta => TurnEtaFormatter.fromTurns(
    turnsRemaining: turnsRemaining,
    completionTurn: completionTurn,
  );
}

class TechnologyPanelViewModel {
  final int sciencePerTurn;
  final TechnologyCardViewModel? activeTechnology;
  final List<TechnologyCardViewModel> technologies;

  const TechnologyPanelViewModel({
    required this.sciencePerTurn,
    required this.activeTechnology,
    required this.technologies,
  });

  static const empty = TechnologyPanelViewModel(
    sciencePerTurn: 0,
    activeTechnology: null,
    technologies: [],
  );

  List<TechnologyCardViewModel> get recommendedTechnologies {
    final recommended = technologies.where((card) => card.canSelect).toList()
      ..sort(_compareRecommendedTechnologies);
    return recommended.take(3).toList(growable: false);
  }

  static int _compareRecommendedTechnologies(
    TechnologyCardViewModel a,
    TechnologyCardViewModel b,
  ) {
    final score = _recommendationScore(b).compareTo(_recommendationScore(a));
    if (score != 0) return score;
    final turns = (a.turnsRemaining ?? 999).compareTo(b.turnsRemaining ?? 999);
    if (turns != 0) return turns;
    final column = a.treeColumn.compareTo(b.treeColumn);
    if (column != 0) return column;
    return a.treeRow.compareTo(b.treeRow);
  }

  static int _recommendationScore(TechnologyCardViewModel card) {
    var score = 0;
    if (card.boostActive) score += 80;
    if (_opensWorkerYields(card.id)) score += 48;
    score += card.unlocks.length * 16;
    score += card.effects.length * 20;
    if (card.turnsRemaining != null) {
      score += math.max(0, 24 - card.turnsRemaining! * 3);
    }
    score -= card.treeColumn * 2;
    return score;
  }

  static bool _opensWorkerYields(TechnologyId id) {
    return switch (id) {
      TechnologyId.agriculture ||
      TechnologyId.mining ||
      TechnologyId.hunting ||
      TechnologyId.animalHusbandry ||
      TechnologyId.fishing ||
      TechnologyId.woodworking ||
      TechnologyId.stoneworking => true,
      _ => false,
    };
  }
}

abstract final class TechnologyPanelViewModelFactory {
  static TechnologyPanelViewModel create({
    required GameState? state,
    required String playerId,
    required TechnologyRuleset ruleset,
    CityRuleset cityRuleset = CityRulesets.standard,
    MapData? mapData,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (state == null || playerId.isEmpty) {
      return TechnologyPanelViewModel.empty;
    }

    final playerResearch = state.research.forPlayer(playerId);
    final science = ScienceYieldCalculator.totalForPlayer(
      playerId: playerId,
      cities: state.cities,
      research: state.research,
      ruleset: ruleset,
      artifacts: state.artifacts,
      cityRuleset: cityRuleset,
    );
    final cityCount = state.cities
        .where((city) => city.ownerPlayerId == playerId)
        .length;

    final cards = ruleset.technologies.values.toList()
      ..sort(_compareTechnologies);
    final viewModels = [
      for (final technology in cards)
        _cardFor(
          technology: technology,
          playerId: playerId,
          playerResearch: playerResearch,
          state: state,
          mapData: mapData,
          cityCount: cityCount,
          sciencePerTurn: science.total,
          ruleset: ruleset,
          currentTurn: currentTurn,
          paceBalance: paceBalance,
        ),
    ];

    return TechnologyPanelViewModel(
      sciencePerTurn: science.total,
      activeTechnology: viewModels
          .where((card) => card.state == TechnologyCardState.active)
          .firstOrNull,
      technologies: viewModels,
    );
  }

  static TechnologyCardViewModel _cardFor({
    required TechnologyDefinition technology,
    required String playerId,
    required PlayerResearchState playerResearch,
    required GameState state,
    required MapData? mapData,
    required int cityCount,
    required int sciencePerTurn,
    required TechnologyRuleset ruleset,
    required int? currentTurn,
    required PaceBalance paceBalance,
  }) {
    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: technology.id,
      playerResearch: playerResearch,
      ruleset: ruleset,
    );
    final cardState = switch (availability) {
      TechnologyAvailability.unlocked => TechnologyCardState.researched,
      TechnologyAvailability.active => TechnologyCardState.active,
      TechnologyAvailability.available => TechnologyCardState.available,
      TechnologyAvailability.lockedByPrerequisites =>
        TechnologyCardState.locked,
      TechnologyAvailability.lockedByTechnology => TechnologyCardState.locked,
    };
    final boostDiscount = mapData != null
        ? TechnologyBoostEvaluator.bestDiscountFor(
            playerId: playerId,
            technology: technology,
            cities: state.cities,
            fieldImprovements: state.fieldImprovements,
            mapData: mapData,
          )
        : 0.0;
    final totalCost = ResearchCostCalculator.effectiveCost(
      technology: technology,
      cityCount: cityCount,
      ruleset: ruleset,
      boostDiscount: boostDiscount,
      paceBalance: paceBalance,
    );
    final progress = cardState == TechnologyCardState.researched
        ? totalCost
        : playerResearch.progressFor(technology.id).clamp(0, totalCost);
    final remaining = math.max(0, totalCost - progress);
    final turnsRemaining = sciencePerTurn > 0 && remaining > 0
        ? (remaining / sciencePerTurn).ceil()
        : null;
    final completionTurn = TurnEtaFormatter.expectedCompletionTurn(
      currentTurn: currentTurn,
      turnsRemaining: turnsRemaining,
    );

    return TechnologyCardViewModel(
      id: technology.id,
      era: technology.era,
      state: cardState,
      progress: progress,
      baseCost: technology.baseCost,
      totalCost: totalCost,
      turnsRemaining: turnsRemaining,
      completionTurn: completionTurn,
      boostActive: boostDiscount > 0,
      unlocks: technology.unlocks,
      effects: technology.effects,
      boosts: technology.boosts,
      treeColumn: technology.treePosition.column,
      treeRow: technology.treePosition.row,
      prerequisiteIds: technology.prerequisites,
      blockedByTechnologyIds: technology.blockedBy,
    );
  }

  static int _compareTechnologies(
    TechnologyDefinition a,
    TechnologyDefinition b,
  ) {
    final era = a.era.index.compareTo(b.era.index);
    if (era != 0) return era;
    final column = a.treePosition.column.compareTo(b.treePosition.column);
    if (column != 0) return column;
    return a.treePosition.row.compareTo(b.treePosition.row);
  }
}
