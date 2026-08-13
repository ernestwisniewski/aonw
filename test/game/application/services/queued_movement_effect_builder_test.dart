import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueuedMovementEffectBuilder', () {
    test('projects ordered executions without merging the same unit', () {
      final first = MovementCommandExecution(
        unitId: 'scout_1',
        fromCol: 0,
        fromRow: 0,
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final second = MovementCommandExecution(
        unitId: 'scout_1',
        fromCol: 1,
        fromRow: 0,
        steps: const [
          UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 2),
        ],
      );

      final effects = QueuedMovementEffectBuilder.fromExecutions([
        first,
        second,
      ]);

      expect(
        effects.map((effect) {
          final steps = effect.steps
              .map(
                (step) =>
                    '${step.col},${step.row}:${step.enterCost}/'
                    '${step.cumulativeCost}',
              )
              .join('|');
          return '${effect.unitId}:${effect.fromCol},${effect.fromRow}->$steps';
        }),
        const ['scout_1:0,0->1,0:1/1', 'scout_1:1,0->2,0:1/1|3,0:1/2'],
      );
      expect(effects.first.steps, same(first.steps));
      expect(effects.last.steps, same(second.steps));
      expect(() => effects.clear(), throwsUnsupportedError);
    });

    test('returns the canonical empty list for no executions', () {
      expect(
        QueuedMovementEffectBuilder.fromExecutions(const []),
        same(const <AnimateUnitMoveEffect>[]),
      );
    });

    test(
      'projects the complete merchant route execution with movement costs',
      () {
        final merchant = GameUnit(
          id: 'merchant_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.merchant,
          name: 'Merchant',
          col: 0,
          row: 0,
          movementPoints: 0,
          merchantTradeRoute: MerchantTradeRoute(
            originCityId: 'city_origin',
            destinationCityId: 'city_target',
            steps: const [
              UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
              UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
              UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 3),
            ],
          ),
        );
        const cities = [
          GameCity(
            id: 'city_origin',
            ownerPlayerId: 'player_1',
            name: 'Origin',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'city_target',
            ownerPlayerId: 'player_1',
            name: 'Target',
            center: CityHex(col: 2, row: 0),
          ),
        ];
        final map = WorldMap(
          cols: 3,
          rows: 1,
          tiles: [
            WorldTile(
              col: 0,
              row: 0,
              terrains: [TerrainType.grassland],
              resources: [],
              height: 0,
            ),
            WorldTile(
              col: 1,
              row: 0,
              terrains: [TerrainType.desert],
              resources: [],
              height: 0,
            ),
            WorldTile(
              col: 2,
              row: 0,
              terrains: [TerrainType.grassland],
              resources: [],
              height: 0,
            ),
          ],
        );

        final movement = DomainTurnMovementProcessor.resetForPlayers(
          state: DomainState.snapshot(
            turn: 1,
            matchRules: MatchRules.standard,
            participants: const [
              Player(
                id: 'player_1',
                name: 'Player one',
                colorValue: 0xFF000001,
              ),
            ],
            units: [merchant],
            cities: cities,
          ),
          playerIds: const ['player_1'],
          mapData: map,
        );
        final execution = movement.executions.single;
        final effects = QueuedMovementEffectBuilder.fromExecutions([execution]);

        expect(movement.state.units.single.occupies(2, 0), isTrue);
        expect(
          (
            unitId: execution.unitId,
            fromCol: execution.fromCol,
            fromRow: execution.fromRow,
          ),
          (unitId: 'merchant_1', fromCol: 0, fromRow: 0),
        );
        expect(
          execution.steps.map(
            (step) =>
                '${step.col},${step.row}:'
                '${step.enterCost}/${step.cumulativeCost}',
          ),
          const ['1,0:4/4', '2,0:2/6'],
        );
        expect(
          effects.single,
          isA<AnimateUnitMoveEffect>()
              .having((effect) => effect.unitId, 'unitId', 'merchant_1')
              .having((effect) => effect.fromCol, 'fromCol', 0)
              .having((effect) => effect.fromRow, 'fromRow', 0)
              .having((effect) => effect.steps, 'steps', const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 4,
                  cumulativeCost: 4,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 2,
                  cumulativeCost: 6,
                ),
              ]),
        );
        expect(effects.single.steps, same(execution.steps));
      },
    );

    test('emits an animation effect for auto-exploring scout movement', () {
      final before = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 1,
        row: 1,
      ).copyWithPosture(UnitPosture.autoExploring);
      final after = before.copyWith(col: 2, row: 1, movementPoints: 1);

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'scout_1')
            .having((effect) => effect.fromCol, 'fromCol', 1)
            .having((effect) => effect.fromRow, 'fromRow', 1)
            .having((effect) => effect.steps.single.col, 'step col', 2)
            .having((effect) => effect.steps.single.row, 'step row', 1),
      );
    });

    test('emits an animation effect for merchant trade route movement', () {
      final before =
          GameUnit.produced(
            id: 'merchant_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            col: 0,
            row: 0,
          ).copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_origin',
              destinationCityId: 'city_target',
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 3,
                ),
              ],
            ),
          );
      final after = before
          .copyWith(col: 3, row: 0, movementPoints: 0)
          .copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_target',
              destinationCityId: 'city_origin',
              steps: const [
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 3,
                ),
              ],
            ),
          );

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'merchant_1')
            .having((effect) => effect.fromCol, 'fromCol', 0)
            .having((effect) => effect.fromRow, 'fromRow', 0)
            .having(
              (effect) => effect.steps.map((step) => step.col),
              'step cols',
              [1, 2, 3],
            ),
      );
    });

    test('emits an animation effect for merchant queued city travel', () {
      final before =
          GameUnit.produced(
            id: 'merchant_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            col: 1,
            row: 0,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 3,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
              ],
            ),
          );
      final after = before
          .copyWith(col: 3, row: 0, movementPoints: 1)
          .copyWithQueuedPath(null);

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'merchant_1')
            .having((effect) => effect.fromCol, 'fromCol', 1)
            .having(
              (effect) => effect.steps.map((step) => step.col),
              'step cols',
              [2, 3],
            ),
      );
    });

    test(
      'ignores ordinary movement deltas without queued or auto movement',
      () {
        final before = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        final after = before.copyWith(col: 2, row: 1, movementPoints: 1);

        final effects = QueuedMovementEffectBuilder.fromUnitDelta(
          beforeUnits: [before],
          afterUnits: [after],
        );

        expect(effects, isEmpty);
      },
    );

    test('infers an ordinary movement step when explicitly requested', () {
      final before = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 1,
        row: 1,
      );
      final after = before.copyWith(col: 2, row: 1, movementPoints: 1);

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
        inferDirectMoves: true,
      );

      expect(
        effects.single,
        isA<AnimateUnitMoveEffect>()
            .having((effect) => effect.unitId, 'unitId', 'warrior_1')
            .having((effect) => effect.fromCol, 'fromCol', 1)
            .having((effect) => effect.fromRow, 'fromRow', 1)
            .having((effect) => effect.steps.single.col, 'step col', 2)
            .having((effect) => effect.steps.single.row, 'step row', 1),
      );
    });

    test('rejects queued animation when the path lacks its start', () {
      final before =
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 3,
              targetRow: 1,
              steps: const [
                UnitMovementStep(
                  col: 2,
                  row: 1,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 1,
                  enterCost: 1,
                  cumulativeCost: 2,
                ),
              ],
            ),
          );
      final after = before.copyWith(col: 3, row: 1, movementPoints: 0);

      final effects = QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: [before],
        afterUnits: [after],
      );

      expect(effects, isEmpty);
    });

    test(
      'rejects queued animation when the path lacks its authoritative end',
      () {
        final before =
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ).copyWithQueuedPath(
              QueuedMovePath(
                targetCol: 3,
                targetRow: 1,
                steps: const [
                  UnitMovementStep(
                    col: 1,
                    row: 1,
                    enterCost: 0,
                    cumulativeCost: 0,
                  ),
                  UnitMovementStep(
                    col: 2,
                    row: 1,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                ],
              ),
            );
        final after = before.copyWith(col: 3, row: 1, movementPoints: 0);

        final effects = QueuedMovementEffectBuilder.fromUnitDelta(
          beforeUnits: [before],
          afterUnits: [after],
          inferDirectMoves: true,
        );

        expect(effects, isEmpty);
      },
    );
  });
}
