import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/replay/replay_renderer_effect_planner.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayRendererEffectPlanner artifact effects', () {
    test('projects excavation start', () {
      final scout = _scout(col: 3, row: 4);
      final artifact = _artifactAt(col: 3, row: 4);

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: [
          ArtifactExcavationStartedEvent(
            artifactId: artifact.id,
            ownerPlayerId: scout.ownerPlayerId,
            unitId: scout.id,
            col: 3,
            row: 4,
          ),
        ],
        previousState: GameState(units: [scout], artifacts: [artifact]),
        state: GameState(
          units: [scout.copyWith(excavatingArtifactId: artifact.id)],
          artifacts: [
            artifact.copyWith(
              location: WorldArtifactLocation.excavation(
                unitId: scout.id,
                col: 3,
                row: 4,
                remainingTurns: 2,
              ),
            ),
          ],
        ),
      );

      final burst = effects.whereType<SpawnParticleBurstEffect>().single;
      expect((burst.col, burst.row), (3, 4));
      final text = effects.whereType<ShowFloatingTextEffect>().single;
      expect((text.text, text.col, text.row), ('Excavate', 3, 4));
      expect(text.presentation, FloatingTextPresentation.bubble);
    });

    test('projects carried and stored transitions', () {
      final scout = _scout(col: 8, row: 3);
      final city = _city(col: 8, row: 3);
      final artifact = _artifactAt(col: 3, row: 4);

      final carriedEffects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: [
          ArtifactCarriedEvent(
            artifactId: artifact.id,
            ownerPlayerId: scout.ownerPlayerId,
            unitId: scout.id,
            col: 3,
            row: 4,
          ),
        ],
        previousState: GameState(units: [scout], artifacts: [artifact]),
        state: GameState(
          units: [scout.copyWith(carriedArtifactId: artifact.id)],
          artifacts: [
            artifact.copyWith(
              location: WorldArtifactLocation.carried(unitId: scout.id),
            ),
          ],
        ),
      );
      expect(
        carriedEffects.whereType<ShowFloatingTextEffect>().single.text,
        'Artifact carried',
      );

      final storedEffects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: [
          ArtifactStoredEvent(
            artifactId: artifact.id,
            ownerPlayerId: scout.ownerPlayerId,
            unitId: scout.id,
            cityId: city.id,
            col: 8,
            row: 3,
          ),
        ],
        previousState: GameState(units: [scout], cities: [city]),
        state: GameState(units: [scout], cities: [city]),
      );
      final storedText = storedEffects
          .whereType<ShowFloatingTextEffect>()
          .single;
      expect(
        (storedText.text, storedText.col, storedText.row),
        ('Artifact stored', 8, 3),
      );
    });

    test('uses perspective fog for artifact cue visibility', () {
      final city = _city(col: 8, row: 3);
      final event = ArtifactStoredEvent(
        artifactId: 'artifact_1',
        ownerPlayerId: 'player_1',
        unitId: 'scout_1',
        cityId: city.id,
        col: 8,
        row: 3,
      );

      bool isVisible(Set<HexCoordinate> visibleHexes) {
        final state = GameState(
          activePlayerId: 'player_1',
          cities: [city],
          fogOfWar: _fogForPlayer('player_1', visibleHexes),
        );
        final effects = ReplayRendererEffectPlanner.effectsForStep(
          interactionEffects: const [],
          events: [event],
          previousState: state,
          state: state,
        );
        return ReplayRendererEffectPlanner.hasPerspectiveVisibleEffect(
          effects: effects,
          previousState: state,
          state: state,
          perspectivePlayerId: 'player_1',
        );
      }

      expect(isVisible({const HexCoordinate(col: 8, row: 3)}), isTrue);
      expect(isVisible(const {}), isFalse);
    });
  });
}

GameUnit _scout({required int col, required int row}) {
  return GameUnit(
    id: 'scout_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.scout,
    name: GameUnitType.scout.defaultNameToken,
    col: col,
    row: row,
  );
}

WorldArtifact _artifactAt({required int col, required int row}) {
  return WorldArtifact.placed(
    type: WorldArtifactType.ancientImperialCrown,
    col: col,
    row: row,
  );
}

GameCity _city({required int col, required int row}) {
  return GameCity(
    id: 'city_player_1_${col}_$row',
    ownerPlayerId: 'player_1',
    name: 'Warszawa',
    center: CityHex(col: col, row: row),
  );
}

FogOfWarState _fogForPlayer(String playerId, Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visibleHexes),
    },
  );
}
