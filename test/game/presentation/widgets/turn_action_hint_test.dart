import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/hud/turn_action_hint.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('hudPlayerReadyToEndTurn', () {
    test('requires units, cities, and research to be ready', () {
      expect(
        hudPlayerReadyToEndTurn(
          gameState: null,
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isFalse,
      );
      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(units: [_unit(movementPoints: 1)]),
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isFalse,
      );
      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(cities: [_city(productionQueued: false)]),
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isFalse,
      );
      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(
            units: [_unit(movementPoints: 0)],
            cities: [_city()],
          ),
          activePlayerId: 'player_1',
          technologyViewModel: _technologyViewModel(hasAvailable: true),
        ),
        isFalse,
      );
      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(
            units: [_unit(movementPoints: 0)],
            cities: [_city()],
          ),
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isTrue,
      );
    });

    test('treats auto-exploring scout as ready with movement points', () {
      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(
            units: [
              _unit(
                type: GameUnitType.scout,
                movementPoints: 2,
                posture: UnitPosture.autoExploring,
              ),
            ],
            cities: [_city()],
          ),
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isTrue,
      );
    });

    test('treats merchant with assigned trade route as ready', () {
      final merchant = _unit(
        type: GameUnitType.merchant,
        movementPoints: 2,
      ).copyWithMerchantTradeRoute(_tradeRoute());

      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(units: [merchant], cities: [_city()]),
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isTrue,
      );
    });

    test('still requires an idle merchant without a trade route', () {
      expect(
        hudPlayerReadyToEndTurn(
          gameState: GameState(
            units: [_unit(type: GameUnitType.merchant, movementPoints: 2)],
            cities: [_city()],
          ),
          activePlayerId: 'player_1',
          technologyViewModel: TechnologyPanelViewModel.empty,
        ),
        isFalse,
      );
    });
  });

  group('hudTurnHintLabel', () {
    test('prefers unit orders before city production and research', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 1)],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: _technologyViewModel(hasAvailable: true),
        activeObjectives: const [],
      );

      expect(label, 'Next step: Warrior');
    });

    test('uses city production when units are already handled', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 0)],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: _technologyViewModel(hasAvailable: true),
        activeObjectives: const [],
      );

      expect(label, 'Next step: production in City');
    });

    test('ignores auto-exploring scouts when choosing the next hint', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [
            _unit(
              type: GameUnitType.scout,
              movementPoints: 2,
              posture: UnitPosture.autoExploring,
            ),
          ],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [],
      );

      expect(label, 'Next step: production in City');
    });

    test('ignores merchants with assigned trade routes in next hint', () {
      final merchant = _unit(
        type: GameUnitType.merchant,
        movementPoints: 2,
      ).copyWithMerchantTradeRoute(_tradeRoute());
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [merchant],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [],
      );

      expect(label, 'Next step: production in City');
    });

    test('uses idle merchant as next unit hint before city production', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(type: GameUnitType.merchant, movementPoints: 2)],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [],
      );

      expect(label, 'Next step: Merchant');
    });

    test('uses research after units and cities are ready', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 0)],
          cities: [_city()],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: _technologyViewModel(hasAvailable: true),
        activeObjectives: const [],
      );

      expect(label, 'Next step: choose research');
    });

    test('uses score advice for the closest matching unit action', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [
            _unit(id: 'warrior_1', movementPoints: 1),
            _unit(id: 'worker_1', type: GameUnitType.worker, movementPoints: 1),
          ],
          cities: [_city()],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
            currentValue: 80,
            advice: GameObjectiveAdvice.improveField,
          ),
        ],
      );

      expect(label, 'Objective: improve a tile with a worker');
    });

    test('uses unit score advice for the closest combat unit action', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [
            _unit(id: 'worker_1', type: GameUnitType.worker, movementPoints: 1),
            _unit(id: 'warrior_1', movementPoints: 1),
          ],
          cities: [_city()],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
            currentValue: 80,
            advice: GameObjectiveAdvice.trainUnit,
          ),
        ],
      );

      expect(label, 'Objective: set unit: Warrior');
    });

    test('uses protect-lead advice for a combat unit action', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(id: 'warrior_1', movementPoints: 1)],
          cities: [_city()],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.holdScoreLeadObjective,
            currentValue: 3,
            advice: GameObjectiveAdvice.protectLead,
          ),
        ],
      );

      expect(label, 'Objective: secure the lead: Warrior');
    });

    test('uses score advice for city production action', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 0)],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
            currentValue: 80,
            advice: GameObjectiveAdvice.constructBuilding,
          ),
        ],
      );

      expect(label, 'Objective: queue a building in City');
    });

    test('uses economy score advice for city production action', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 0)],
          cities: [_city(productionQueued: false)],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
            currentValue: 80,
            advice: GameObjectiveAdvice.collectGold,
          ),
        ],
      );

      expect(label, 'Objective: close gold in City');
    });

    test('uses score advice for research action', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 0)],
          cities: [_city()],
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: _technologyViewModel(hasAvailable: true),
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
            currentValue: 80,
            advice: GameObjectiveAdvice.unlockTechnology,
          ),
        ],
      );

      expect(label, 'Objective: choose a scoring technology');
    });

    test('shows score advice when falling back to the active objective', () {
      final label = hudTurnHintLabel(
        l10n: l10n,
        gameState: GameState(
          units: [_unit(movementPoints: 0)],
          cities: [_city()],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        actionsLocked: false,
        readyToEndTurn: false,
        technologyViewModel: TechnologyPanelViewModel.empty,
        activeObjectives: const [
          GameObjectiveProgress(
            definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
            currentValue: 80,
            advice: GameObjectiveAdvice.collectGold,
          ),
        ],
      );

      expect(
        label,
        'Objective: Catch the score leader · Biggest gap: gold for score.',
      );
    });

    test('falls back to active objective or null when actions are locked', () {
      final objective = GameObjectiveProgress(
        definition: GameObjectiveTracker.earlyGameObjectives.first,
        currentValue: 0,
      );
      final state = GameState(
        units: [_unit(movementPoints: 0)],
        cities: [_city()],
      );

      expect(
        hudTurnHintLabel(
          l10n: l10n,
          gameState: state,
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          actionsLocked: false,
          readyToEndTurn: false,
          technologyViewModel: TechnologyPanelViewModel.empty,
          activeObjectives: [objective],
        ),
        'Objective: Choose research',
      );
      expect(
        hudTurnHintLabel(
          l10n: l10n,
          gameState: state,
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          actionsLocked: true,
          readyToEndTurn: false,
          technologyViewModel: TechnologyPanelViewModel.empty,
          activeObjectives: [objective],
        ),
        isNull,
      );
    });
  });
}

GameUnit _unit({
  String id = 'warrior_1',
  GameUnitType type = GameUnitType.warrior,
  required int movementPoints,
  UnitPosture posture = UnitPosture.active,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 0,
    row: 0,
    movementPoints: movementPoints,
    posture: posture,
  );
}

GameCity _city({bool productionQueued = true}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 1, row: 1),
    productionQueue: productionQueued
        ? CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 0,
          )
        : null,
  );
}

TechnologyPanelViewModel _technologyViewModel({required bool hasAvailable}) {
  return TechnologyPanelViewModel(
    sciencePerTurn: 0,
    activeTechnology: null,
    technologies: hasAvailable
        ? const [
            TechnologyCardViewModel(
              id: TechnologyId.agriculture,
              state: TechnologyCardState.available,
              progress: 0,
              totalCost: 6,
              turnsRemaining: null,
              boostActive: false,
            ),
          ]
        : const [],
  );
}

MerchantTradeRoute _tradeRoute() {
  return MerchantTradeRoute(
    originCityId: 'city_1',
    destinationCityId: 'city_2',
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    ],
  );
}
