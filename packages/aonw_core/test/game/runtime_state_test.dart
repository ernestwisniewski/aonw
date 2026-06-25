import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameRuntimeState', () {
    test('empty json restores empty runtime state', () {
      final runtimeState = GameRuntimeState.fromJson(const {});

      expect(runtimeState, GameRuntimeState.empty);
    });

    test('round-trips city founding draft and pending action', () {
      final runtimeState = GameRuntimeState(
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'commander_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 2, row: 3),
          controlledHexes: const [
            CityHex(col: 2, row: 4),
            CityHex(col: 3, row: 3),
          ],
        ),
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'player_1',
          unitId: 'worker_1',
          improvementType: FieldImprovementType.mine,
        ),
        submittedPlayerIds: const {'player_2', 'player_1'},
        timeoutStreaksByPlayerId: const {'player_2': 2},
        afkPlayerIds: const {'player_2'},
        kickedPlayerIds: const {'player_3'},
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'warrior_1',
            defenderCol: 4,
            defenderRow: 5,
            declaredAtTick: 7,
            declaringPlayerId: 'player_1',
          ),
        ],
        diplomacy: DiplomacyState.empty.registerUnitAttack(
          attackerPlayerId: 'player_1',
          defenderPlayerId: 'player_2',
          turn: 3,
        ),
        mapObjectiveHoldStatesByObjectiveId: const {
          'pass_1': MapObjectiveHoldState(
            objectiveId: 'pass_1',
            playerId: 'player_1',
            holdTurns: 2,
          ),
        },
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'trade_1',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.iron,
            goldPerTurn: 4,
            remainingTurns: 10,
          ),
        ],
        turnStartedAt: DateTime.utc(2026, 4, 27, 12),
      );

      final restored = GameRuntimeState.fromJson(runtimeState.toJson());

      expect(restored, runtimeState);
      expect(restored.submittedPlayerIds, {'player_1', 'player_2'});
      expect(restored.timeoutStreaksByPlayerId, {'player_2': 2});
      expect(restored.afkPlayerIds, {'player_2'});
      expect(restored.kickedPlayerIds, {'player_3'});
      expect(restored.toJson()['submittedPlayerIds'], ['player_1', 'player_2']);
      expect(restored.intendedAttacks.single.attackerUnitId, 'warrior_1');
      expect(
        restored.diplomacy.statusBetween('player_1', 'player_2'),
        DiplomaticRelationStatus.hostile,
      );
      expect(
        restored.mapObjectiveHoldStatesByObjectiveId['pass_1'],
        const MapObjectiveHoldState(
          objectiveId: 'pass_1',
          playerId: 'player_1',
          holdTurns: 2,
        ),
      );
      expect(restored.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'player_2',
          importerPlayerId: 'player_1',
          resource: ResourceType.iron,
          goldPerTurn: 4,
          remainingTurns: 10,
        ),
      ]);
      expect(restored.turnStartedAt, DateTime.utc(2026, 4, 27, 12));
    });

    test('can strip local client interaction state', () {
      final stripped = GameRuntimeState(
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 0, row: 0),
        ),
        pendingAction: const PendingResearchSelection(
          ownerPlayerId: 'player_1',
        ),
        submittedPlayerIds: const {'player_1'},
        timeoutStreaksByPlayerId: const {'player_1': 1},
        afkPlayerIds: const {'player_1'},
        kickedPlayerIds: const {'player_3'},
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'warrior_1',
            defenderCol: 1,
            defenderRow: 0,
            declaredAtTick: 7,
            declaringPlayerId: 'player_1',
          ),
        ],
        diplomacy: DiplomacyState.empty.registerCityAttack(
          attackerPlayerId: 'player_1',
          defenderPlayerId: 'player_2',
        ),
        mapObjectiveHoldStatesByObjectiveId: const {
          'pass_1': MapObjectiveHoldState(
            objectiveId: 'pass_1',
            playerId: 'player_1',
            holdTurns: 2,
          ),
        },
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'trade_1',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 2,
            remainingTurns: 5,
          ),
        ],
        turnStartedAt: DateTime.utc(2026, 4, 29),
      ).withoutClientInteractionState();

      expect(stripped.cityFoundingDraft, isNull);
      expect(stripped.pendingAction, isNull);
      expect(stripped.submittedPlayerIds, {'player_1'});
      expect(stripped.timeoutStreaksByPlayerId, {'player_1': 1});
      expect(stripped.afkPlayerIds, {'player_1'});
      expect(stripped.kickedPlayerIds, {'player_3'});
      expect(stripped.intendedAttacks, hasLength(1));
      expect(
        stripped.diplomacy.statusBetween('player_1', 'player_2'),
        DiplomaticRelationStatus.war,
      );
      expect(stripped.mapObjectiveHoldStatesByObjectiveId, {
        'pass_1': const MapObjectiveHoldState(
          objectiveId: 'pass_1',
          playerId: 'player_1',
          holdTurns: 2,
        ),
      });
      expect(stripped.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'player_2',
          importerPlayerId: 'player_1',
          resource: ResourceType.horses,
          goldPerTurn: 2,
          remainingTurns: 5,
        ),
      ]);
      expect(stripped.turnStartedAt, DateTime.utc(2026, 4, 29));
    });

    test('parses pending action modes', () {
      const actions = <PendingPlayerAction>[
        PendingResearchSelection(ownerPlayerId: 'player_1'),
        PendingCityWorkedHexSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
        PendingCityExpansionSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
        PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'warrior_1',
          defenderCol: 2,
          defenderRow: 1,
        ),
        PendingCommanderMergeSelection(
          ownerPlayerId: 'player_1',
          commanderUnitId: 'commander_1',
        ),
        PendingMerchantTradeRouteSelection(
          ownerPlayerId: 'player_1',
          unitId: 'merchant_1',
        ),
        PendingMerchantMoveToCitySelection(
          ownerPlayerId: 'player_1',
          unitId: 'merchant_1',
        ),
        PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'warrior_1',
          restoreMovementPoints: 2,
        ),
      ];

      for (final action in actions) {
        expect(PendingPlayerAction.fromJson(action.toJson()), action);
      }
    });

    test('reports pending action unit ownership', () {
      const unitActions = <PendingPlayerAction>[
        PendingWorkerActionSelection(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
        ),
        PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
          restoreMovementPoints: 2,
        ),
        PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'unit_1',
        ),
        PendingCommanderMergeSelection(
          ownerPlayerId: 'player_1',
          commanderUnitId: 'unit_1',
        ),
        PendingMerchantTradeRouteSelection(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
        ),
        PendingMerchantMoveToCitySelection(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
        ),
      ];

      for (final action in unitActions) {
        expect(action.ownsUnit('unit_1'), isTrue);
        expect(action.ownsUnit('other_unit'), isFalse);
      }

      const nonUnitActions = <PendingPlayerAction>[
        PendingResearchSelection(ownerPlayerId: 'player_1'),
        PendingCityWorkedHexSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
        PendingCityExpansionSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
      ];

      for (final action in nonUnitActions) {
        expect(action.ownsUnit('unit_1'), isFalse);
      }
    });
  });
}
