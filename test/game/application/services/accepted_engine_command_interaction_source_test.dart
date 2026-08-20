import 'package:aonw/game/application/services/accepted_engine_command_interaction_source.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foreign actor cannot replace client-owned interaction', () {
    final humanUnit = _unit('human', 'player_1');
    final state = GameClientState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      units: [humanUnit, _unit('ai_worker', 'player_2')],
      interaction: InteractionState(
        selection: GameSelection.unit(humanUnit),
        moveCommandActive: true,
        movePreview: _preview('human'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'human',
        ),
      ),
    );

    final projected = acceptedEngineCommandInteractionSource(
      currentState: state,
      command: const SelectWorkerImprovementCommand(
        'ai_worker',
        FieldImprovementType.farm,
      ),
      family: GameEngineCommandFamily.worker,
      domainActions: DomainActionState.empty,
      actorPlayerId: 'player_2',
    );

    expect(projected, same(state));
  });

  test('move command clears only the matching unit preview', () {
    final selected = _unit('selected', 'player_1');
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [selected, _unit('other', 'player_1')],
      interaction: InteractionState(
        selection: GameSelection.unit(selected),
        moveCommandActive: true,
        movePreview: _preview('selected'),
      ),
    );

    final unrelated = acceptedEngineCommandInteractionSource(
      currentState: state,
      command: const MoveUnitCommand('other', 1, 0),
      family: GameEngineCommandFamily.movement,
      domainActions: state.domain.actions,
      actorPlayerId: 'player_1',
    );
    final matching = acceptedEngineCommandInteractionSource(
      currentState: state,
      command: const MoveUnitCommand('selected', 1, 0),
      family: GameEngineCommandFamily.movement,
      domainActions: state.domain.actions,
      actorPlayerId: 'player_1',
    );

    expect(unrelated, same(state));
    expect(matching.movePreview, isNull);
    expect(matching.moveCommandActive, isTrue);
    expect(matching.selection, same(state.selection));
  });
}

GameUnit _unit(String id, String ownerPlayerId) => GameUnit(
  id: id,
  ownerPlayerId: ownerPlayerId,
  type: GameUnitType.warrior,
  name: id,
  col: 0,
  row: 0,
);

UnitMovementPlan _preview(String unitId) => UnitMovementPlan(
  unitId: unitId,
  targetCol: 1,
  targetRow: 0,
  totalCost: 1,
  availableMovementUnits: 3,
  steps: const [],
);
