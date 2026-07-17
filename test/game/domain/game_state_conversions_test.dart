import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameStatePersistence', () {
    test('copyWithPersistentState round-trips projected persistent fields', () {
      final persistent = _persistentProjection();

      final projected = const GameState(
        activePlayerId: 'ui_player',
        activePlayerCanAct: false,
      ).copyWithPersistentState(persistent);

      expect(projected.toPersistentState(), persistent);
      expect(projected.activePlayerId, 'ui_player');
      expect(projected.activePlayerCanAct, isFalse);
    });

    test('projection does not cache a legacy mutable source', () {
      final playerGold = <String, int>{'player_1': 1};
      final state = GameState(playerGold: playerGold);

      final beforeMutation = state.toPersistentState();
      playerGold['player_1'] = 2;
      final afterMutation = state.toPersistentState();

      expect(beforeMutation.playerGold, {'player_1': 1});
      expect(afterMutation.playerGold, {'player_1': 2});
    });

    test(
      'copyWithPersistentState preserves lifecycle but drops interaction fields',
      () {
        final turnStartedAt = DateTime.utc(2026, 7, 9, 12);
        final persistent = PersistentGameState(
          runtimeState: GameRuntimeState(
            cityFoundingDraft: CityFoundingDraft(
              unitId: 'settler_1',
              ownerPlayerId: 'player_1',
              center: const CityHex(col: 2, row: 2),
            ),
            pendingAction: const PendingResearchSelection(
              ownerPlayerId: 'player_1',
            ),
            timeoutStreaksByPlayerId: const {'player_1': 2},
            afkPlayerIds: const {'player_2'},
            kickedPlayerIds: const {'player_3'},
            turnStartedAt: turnStartedAt,
          ),
        );

        final projected = const GameState().copyWithPersistentState(persistent);
        final runtime = projected.runtimeState;

        expect(projected.cityFoundingDraft, isNull);
        expect(projected.pendingAction, isNull);
        expect(runtime.cityFoundingDraft, isNull);
        expect(runtime.pendingAction, isNull);
        expect(runtime.timeoutStreaksByPlayerId, {'player_1': 2});
        expect(runtime.afkPlayerIds, {'player_2'});
        expect(runtime.kickedPlayerIds, {'player_3'});
        expect(runtime.turnStartedAt, turnStartedAt);
      },
    );
  });
}

PersistentGameState _persistentProjection() {
  final unit = GameUnit.startingWarrior(
    ownerPlayerId: 'player_1',
    col: 1,
    row: 2,
  );
  final fog = FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: {const HexCoordinate(col: 0, row: 0)},
        visibleHexes: {const HexCoordinate(col: 1, row: 1)},
      ),
    },
  );
  final research = ResearchState(
    players: {
      'player_1': PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.agriculture},
        activeTechnologyId: TechnologyId.mining,
        progressByTechnologyId: const {TechnologyId.mining: 3},
        scienceOverflow: 1,
      ),
    },
  );

  return PersistentGameState(
    playerColors: const {'player_1': 0xFF112233},
    playerCountries: const {'player_1': PlayerCountry.france},
    playerGold: const {'player_1': 42},
    playerWarWeariness: const {'player_1': 3},
    playerStabilityNet: const {'player_1': 7},
    units: [unit],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Paris',
        center: CityHex(col: 2, row: 2),
        population: 2,
      ),
    ],
    artifacts: const [
      WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.map(col: 3, row: 3),
      ),
    ],
    fieldImprovements: const [
      FieldImprovement(
        hex: CityHex(col: 2, row: 3),
        type: FieldImprovementType.farm,
        builtByCityId: 'city_1',
      ),
    ],
    fogOfWar: fog,
    research: research,
    wonderRegistry: WonderRegistry(
      completedBy: {WonderType.greatLibrary: 'player_1'},
    ),
    runtimeState: GameRuntimeState(
      submittedPlayerIds: const {'player_1'},
      timeoutStreaksByPlayerId: const {'player_2': 2},
      afkPlayerIds: const {'player_2'},
      kickedPlayerIds: const {'player_3'},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'unit_1',
          defenderCol: 4,
          defenderRow: 4,
          declaredAtTick: 1,
          declaringPlayerId: 'player_1',
        ),
      ],
      diplomacy: DiplomacyState(
        relations: {
          'player_1|player_2': const DiplomaticRelation(
            playerAId: 'player_1',
            playerBId: 'player_2',
            status: DiplomaticRelationStatus.friendly,
            relationScore: 10,
          ),
        },
      ),
      dominationHoldTurnsByPlayerId: const {'player_1': 2},
      culturalVictoryHoldTurnsByPlayerId: const {'player_1': 1},
      mapObjectiveHoldStatesByObjectiveId: const {
        'objective_1': MapObjectiveHoldState(
          objectiveId: 'objective_1',
          playerId: 'player_1',
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: const [
        ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'player_1',
          importerPlayerId: 'player_2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          remainingTurns: 4,
        ),
      ],
      turnStartedAt: DateTime.utc(2026, 7, 9, 12),
    ),
  );
}
