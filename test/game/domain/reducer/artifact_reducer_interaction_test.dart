import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/artifact/artifact_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('ArtifactReducer interaction contract', () {
    test('accepted excavation clears only transient interaction', () {
      final unit = _unit(id: 'scout_1', col: 2, row: 3);
      final state = GameState(
        activePlayerId: _playerId,
        units: [unit],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.map(col: 2, row: 3),
          ),
        ],
        interaction: _richInteraction(unit),
      );

      final transition = ArtifactReducer.startExcavation(
        state,
        const StartArtifactExcavationCommand('scout_1'),
      );

      _expectAcceptedInteraction(state, transition);
      expect(
        transition.state.artifacts.single.location.isBeingExcavated,
        isTrue,
      );
    });

    test('accepted city storage clears only transient interaction', () {
      final unit = _unit(
        id: 'carrier_1',
        col: 1,
        row: 1,
        carriedArtifactId: 'artifact_1',
      );
      final state = GameState(
        activePlayerId: _playerId,
        units: [unit],
        cities: const [_playerCity],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.carried(unitId: 'carrier_1'),
          ),
        ],
        interaction: _richInteraction(unit),
      );

      final transition = ArtifactReducer.storeInCity(
        state,
        const StoreArtifactInCityCommand('carrier_1', cityId: 'city_1'),
      );

      _expectAcceptedInteraction(state, transition);
      expect(
        transition.state.artifacts.single.location,
        const WorldArtifactLocation.stored(cityId: 'city_1'),
      );
    });

    test('accepted artifact trade clears only transient interaction', () {
      final selectedUnit = _unit(id: 'sentinel_1', col: 8, row: 8);
      final state = GameState(
        activePlayerId: _playerId,
        playerGold: const {_playerId: 10, _otherPlayerId: 1},
        units: [selectedUnit],
        cities: const [_playerCity, _otherPlayerCity],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.merchantsSeal,
            location: WorldArtifactLocation.stored(cityId: 'city_1'),
          ),
        ],
        interaction: _richInteraction(selectedUnit),
      );

      final transition = ArtifactReducer.tradeArtifact(
        state,
        const TradeArtifactCommand(
          playerId: _playerId,
          targetPlayerId: _otherPlayerId,
          offeredArtifactId: 'artifact_1',
          offeredGold: 3,
        ),
      );

      _expectAcceptedInteraction(state, transition);
      expect(transition.state.playerGold, {_playerId: 7, _otherPlayerId: 4});
      expect(
        transition.state.artifacts.single.location,
        const WorldArtifactLocation.stored(cityId: 'city_2'),
      );
    });

    test('rejected excavation preserves state and interaction identity', () {
      final unit = _unit(id: 'scout_1', col: 2, row: 3);
      final state = GameState(
        activePlayerId: _playerId,
        units: [unit],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.map(col: 2, row: 3),
          ),
        ],
        interaction: _richInteraction(unit),
      );

      final transition = ArtifactReducer.startExcavation(
        state,
        const StartArtifactExcavationCommand('scout_1'),
        context: const GameCommandContext(actorPlayerId: _otherPlayerId),
      );

      _expectRejectedInteraction(state, transition);
    });

    test('rejected city storage preserves state and interaction identity', () {
      final unit = _unit(
        id: 'carrier_1',
        col: 1,
        row: 1,
        carriedArtifactId: 'artifact_1',
      );
      final state = GameState(
        activePlayerId: _playerId,
        units: [unit],
        cities: const [_playerCity],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.heroSword,
            location: WorldArtifactLocation.carried(unitId: 'carrier_1'),
          ),
        ],
        interaction: _richInteraction(unit),
      );

      final transition = ArtifactReducer.storeInCity(
        state,
        const StoreArtifactInCityCommand('carrier_1', cityId: 'city_1'),
        context: const GameCommandContext(actorPlayerId: _otherPlayerId),
      );

      _expectRejectedInteraction(state, transition);
    });

    test(
      'rejected artifact trade preserves state and interaction identity',
      () {
        final selectedUnit = _unit(id: 'sentinel_1', col: 8, row: 8);
        final state = GameState(
          activePlayerId: _playerId,
          playerGold: const {_playerId: 10, _otherPlayerId: 1},
          units: [selectedUnit],
          cities: const [_playerCity, _otherPlayerCity],
          artifacts: const [
            WorldArtifact(
              id: 'artifact_1',
              type: WorldArtifactType.merchantsSeal,
              location: WorldArtifactLocation.stored(cityId: 'city_1'),
            ),
          ],
          interaction: _richInteraction(selectedUnit),
        );

        final transition = ArtifactReducer.tradeArtifact(
          state,
          const TradeArtifactCommand(
            playerId: _playerId,
            targetPlayerId: _otherPlayerId,
            offeredArtifactId: 'artifact_1',
          ),
          context: const GameCommandContext(actorPlayerId: _otherPlayerId),
        );

        _expectRejectedInteraction(state, transition);
      },
    );
  });
}

GameInteractionState _richInteraction(GameUnit selectedUnit) {
  return GameInteractionState(
    selection: GameSelection.unit(selectedUnit),
    movePreview: UnitMovementPlan(
      unitId: selectedUnit.id,
      targetCol: selectedUnit.col + 1,
      targetRow: selectedUnit.row,
      totalCost: 1,
      availableMovementPoints: selectedUnit.movementPoints,
      steps: [
        UnitMovementStep(
          col: selectedUnit.col,
          row: selectedUnit.row,
          enterCost: 0,
          cumulativeCost: 0,
        ),
        UnitMovementStep(
          col: selectedUnit.col + 1,
          row: selectedUnit.row,
          enterCost: 1,
          cumulativeCost: 1,
        ),
      ],
    ),
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'settler_draft',
      ownerPlayerId: _playerId,
      center: const CityHex(col: 6, row: 6),
    ),
    pendingAction: const PendingResearchSelection(ownerPlayerId: _playerId),
    moveCommandActive: true,
  );
}

void _expectAcceptedInteraction(
  GameState before,
  GameStateTransition transition,
) {
  expect(identical(transition.state, before), isFalse);
  expect(identical(transition.state.interaction, before.interaction), isFalse);
  expect(before.selection, isNotNull);
  expect(before.movePreview, isNotNull);
  expect(before.moveCommandActive, isTrue);
  expect(transition.state.selection, isNull);
  expect(transition.state.movePreview, isNull);
  expect(transition.state.moveCommandActive, isFalse);
  expect(
    identical(transition.state.cityFoundingDraft, before.cityFoundingDraft),
    isTrue,
  );
  expect(
    identical(transition.state.pendingAction, before.pendingAction),
    isTrue,
  );
  expect(transition.events, isEmpty);
  expect(transition.uiEffects, isEmpty);
}

void _expectRejectedInteraction(
  GameState before,
  GameStateTransition transition,
) {
  expect(identical(transition.state, before), isTrue);
  expect(identical(transition.state.interaction, before.interaction), isTrue);
  expect(identical(transition.state.selection, before.selection), isTrue);
  expect(identical(transition.state.movePreview, before.movePreview), isTrue);
  expect(
    identical(transition.state.cityFoundingDraft, before.cityFoundingDraft),
    isTrue,
  );
  expect(
    identical(transition.state.pendingAction, before.pendingAction),
    isTrue,
  );
  expect(transition.state.moveCommandActive, before.moveCommandActive);
  expect(transition.events, isEmpty);
  expect(transition.uiEffects, isEmpty);
}

GameUnit _unit({
  required String id,
  required int col,
  required int row,
  String? carriedArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.scout,
    name: 'Scout',
    col: col,
    row: row,
    movementPoints: 5,
    carriedArtifactId: carriedArtifactId,
  );
}

const _playerCity = GameCity(
  id: 'city_1',
  ownerPlayerId: _playerId,
  name: 'One City',
  center: CityHex(col: 1, row: 1),
);

const _otherPlayerCity = GameCity(
  id: 'city_2',
  ownerPlayerId: _otherPlayerId,
  name: 'Two City',
  center: CityHex(col: 4, row: 1),
);
