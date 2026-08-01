import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainEventPresentationProjector', () {
    test(
      'projects visible combat once before its retreat without supplied facts',
      () {
        final attacker = GameUnit.produced(
          id: 'attacker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.archer,
          col: 0,
          row: 0,
        );
        final defender = GameUnit.produced(
          id: 'defender',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        );
        final event = CombatResolvedEvent(
          attackerUnitId: attacker.id,
          defenderUnitId: defender.id,
          outcome: CombatOutcome(
            attackerUnitId: attacker.id,
            defenderUnitId: defender.id,
            attackerHpAfter: 7,
            defenderHpAfter: 1,
            attackerKilled: false,
            defenderKilled: false,
            defenderRetreated: true,
            steps: [AttackStep(damage: 5), RetaliationStep(damage: 1)],
          ),
        );

        final effects = DomainEventPresentationProjector.project(
          interactionEffects: const [],
          events: [event],
          previousState: GameClientState(units: [attacker, defender]),
          state: GameClientState(
            units: [attacker, defender.copyWith(col: 2, hitPoints: 1)],
          ),
        );

        final combat = effects.whereType<PlayCombatAnimationEffect>().single;
        final retreat = effects
            .whereType<AnimateUnitMoveEffect>()
            .where((effect) => effect.unitId == defender.id)
            .single;
        expect(effects.indexOf(combat), lessThan(effects.indexOf(retreat)));
        expect(combat.attackerFromCol, attacker.col);
        expect(combat.attackerFromRow, attacker.row);
        expect(retreat.fromCol, defender.col);
        expect(retreat.steps.single.col, 2);
      },
    );

    test(
      'preserves domain event order across movement combat and building',
      () {
        final attacker = GameUnit.produced(
          id: 'attacker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        );
        final defender = GameUnit.produced(
          id: 'defender',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 0,
        );
        const city = GameCity(
          id: 'city',
          ownerPlayerId: 'player_1',
          name: 'New city',
          center: CityHex(col: 3, row: 0),
        );
        final previousState = GameClientState(units: [attacker, defender]);
        final state = GameClientState(
          units: [attacker, defender],
          cities: const [city],
        );
        final effects = DomainEventPresentationProjector.project(
          interactionEffects: const [],
          events: [
            const UnitMovedEvent(
              unitId: 'attacker',
              fromCol: 0,
              fromRow: 0,
              toCol: 1,
              toRow: 0,
            ),
            CombatResolvedEvent(
              attackerUnitId: attacker.id,
              defenderUnitId: defender.id,
              outcome: CombatOutcome(
                attackerUnitId: attacker.id,
                defenderUnitId: defender.id,
                attackerHpAfter: 8,
                defenderHpAfter: 6,
                attackerKilled: false,
                defenderKilled: false,
                steps: [AttackStep(damage: 4), RetaliationStep(damage: 2)],
              ),
            ),
            const CityFoundedEvent(cityId: 'city', ownerPlayerId: 'player_1'),
          ],
          previousState: previousState,
          state: state,
        );

        final movementIndex = effects.indexWhere(
          (effect) =>
              effect is AnimateUnitMoveEffect && effect.unitId == attacker.id,
        );
        final combatIndex = effects.indexWhere(
          (effect) => effect is PlayCombatAnimationEffect,
        );
        final constructionIndex = effects.lastIndexWhere(
          (effect) =>
              effect is SpawnParticleBurstEffect &&
              effect.kind == ParticleBurstKind.cityFounded,
        );
        expect(movementIndex, greaterThanOrEqualTo(0));
        expect(combatIndex, greaterThan(movementIndex));
        expect(constructionIndex, greaterThan(combatIndex));
      },
    );

    test('projects artifact lifecycle cues only from ordered events', () {
      final effects = DomainEventPresentationProjector.project(
        interactionEffects: const [],
        events: const [
          ArtifactExcavationStartedEvent(
            artifactId: 'artifact',
            ownerPlayerId: 'player_1',
            unitId: 'scout',
            col: 1,
            row: 0,
          ),
          ArtifactCarriedEvent(
            artifactId: 'artifact',
            ownerPlayerId: 'player_1',
            unitId: 'scout',
            col: 2,
            row: 0,
          ),
          ArtifactStoredEvent(
            artifactId: 'artifact',
            ownerPlayerId: 'player_1',
            unitId: 'scout',
            cityId: 'city',
            col: 3,
            row: 0,
          ),
        ],
        previousState: GameClientState(),
        state: GameClientState(),
      );

      expect(
        effects.whereType<ShowFloatingTextEffect>().map(
          (effect) => (effect.text, effect.col, effect.row),
        ),
        const [
          ('Excavate', 1, 0),
          ('Artifact carried', 2, 0),
          ('Artifact stored', 3, 0),
        ],
      );
      expect(effects.whereType<SpawnParticleBurstEffect>(), hasLength(3));
    });
  });
}
