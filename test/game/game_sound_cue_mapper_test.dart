import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue_mapper.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameSoundCueMapper', () {
    test('maps accepted move commands without movement animation cues', () {
      final beforeUnit = GameUnit(
        id: 'cavalry_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.cavalry,
        name: 'Cavalry',
        col: 0,
        row: 0,
      );
      final afterUnit = GameUnit(
        id: 'cavalry_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.cavalry,
        name: 'Cavalry',
        col: 1,
        row: 0,
      );
      final before = GameState(units: [beforeUnit]);
      final after = GameState(units: [afterUnit]);
      const effect = AnimateUnitMoveEffect(
        unitId: 'cavalry_1',
        fromCol: 0,
        fromRow: 0,
        steps: [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );

      expect(
        GameSoundCueMapper.forCommand(
          command: const MoveUnitCommand('cavalry_1', 1, 0),
          previousState: before,
          state: after,
          events: const [],
          uiEffects: const [effect],
        ),
        [GameSoundCue.walk],
      );
      expect(
        GameSoundCueMapper.forRendererEffects(
          effects: const [effect],
          state: after,
          previousState: before,
        ),
        isEmpty,
      );
    });

    test('does not play command cues for no-op commands', () {
      const state = GameState();

      expect(
        GameSoundCueMapper.forCommand(
          command: const SelectTileCommand(0, 0),
          previousState: state,
          state: state,
          events: const [],
          uiEffects: const [],
        ),
        isEmpty,
      );
    });

    test('maps empty tile taps to map tile selection cues', () {
      expect(
        GameSoundCueMapper.forCommand(
          command: const TileTappedCommand(0, 0),
          previousState: null,
          state: const GameState(activePlayerId: 'player_1'),
          events: const [],
          uiEffects: const [],
        ),
        [GameSoundCue.mapTileSelect],
      );
    });

    test('does not map unit selection while unit select asset is absent', () {
      final unit = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 0,
      );

      expect(
        GameSoundCueMapper.forCommand(
          command: const TileTappedCommand(0, 0),
          previousState: const GameState(activePlayerId: 'player_1'),
          state: GameState(
            activePlayerId: 'player_1',
            units: [unit],
            selection: GameSelection.unit(unit),
          ),
          events: const [],
          uiEffects: const [],
        ),
        isEmpty,
      );
    });

    test('maps city selection to the city cue', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );

      expect(
        GameSoundCueMapper.forCommand(
          command: const CityTappedCommand('city_1'),
          previousState: const GameState(
            activePlayerId: 'player_1',
            cities: [city],
          ),
          state: GameState(
            activePlayerId: 'player_1',
            cities: const [city],
            selection: GameSelection.city(
              city,
              cityYield: TileYield.zero,
              playerColor: 0,
            ),
          ),
          events: const [],
          uiEffects: const [],
        ),
        [GameSoundCue.city],
      );
    });

    test('suppresses command cues for another players unit', () {
      final beforeUnit = GameUnit(
        id: 'cavalry_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.cavalry,
        name: 'Cavalry',
        col: 0,
        row: 0,
      );
      final afterUnit = GameUnit(
        id: 'cavalry_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.cavalry,
        name: 'Cavalry',
        col: 1,
        row: 0,
      );

      expect(
        GameSoundCueMapper.forCommand(
          command: const MoveUnitCommand('cavalry_1', 1, 0),
          previousState: GameState(
            activePlayerId: 'player_1',
            units: [beforeUnit],
          ),
          state: GameState(activePlayerId: 'player_1', units: [afterUnit]),
          events: const [],
          uiEffects: const [],
        ),
        isEmpty,
      );
    });

    test('maps move targeting only to available preview cue', () {
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 0,
      );
      final previous = GameState(
        activePlayerId: 'player_1',
        units: [unit],
        selection: GameSelection.unit(unit),
      );

      expect(
        GameSoundCueMapper.forCommand(
          command: const ToggleMoveTargetingCommand(),
          previousState: previous,
          state: previous.copyWith(moveCommandActive: true),
          events: const [],
          uiEffects: const [],
        ),
        [GameSoundCue.movePreview],
      );
      expect(
        GameSoundCueMapper.forCommand(
          command: const ToggleMoveTargetingCommand(),
          previousState: previous.copyWith(moveCommandActive: true),
          state: previous,
          events: const [],
          uiEffects: const [],
        ),
        isEmpty,
      );
    });

    test('maps worker panel opening to available panel open cue', () {
      final unit = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 0,
      );

      expect(
        GameSoundCueMapper.forCommand(
          command: const StartWorkerActionSelectionCommand('worker_1'),
          previousState: GameState(activePlayerId: 'player_1', units: [unit]),
          state: GameState(
            activePlayerId: 'player_1',
            units: [unit],
            selection: GameSelection.unit(unit),
          ),
          events: const [],
          uiEffects: const [],
        ),
        [GameSoundCue.uiPanelOpen],
      );
    });

    test('keeps technology selection silent and maps turn command cue', () {
      const state = GameState(activePlayerId: 'player_1');

      expect(
        GameSoundCueMapper.forCommand(
          command: const SelectTechnologyCommand(
            'player_1',
            TechnologyId.agriculture,
          ),
          previousState: state,
          state: state.copyWith(
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
          ),
          events: const [],
          uiEffects: const [],
        ),
        isEmpty,
      );
      expect(
        GameSoundCueMapper.forCommand(
          command: const SetActivePlayerCommand('player_2', canAct: true),
          previousState: state,
          state: const GameState(activePlayerId: 'player_2'),
          events: const [],
          uiEffects: const [],
        ),
        [GameSoundCue.newTurn],
      );
    });

    test(
      'maps event cues for cities and combat without replaying technology',
      () {
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
        );
        final attacker = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        );
        final defender = GameUnit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.scout,
          name: 'Scout',
          col: 1,
          row: 0,
        );

        expect(
          GameSoundCueMapper.forEvents(
            events: [
              const CityFoundedEvent(
                cityId: 'city_1',
                ownerPlayerId: 'player_1',
              ),
              CombatResolvedEvent(
                attackerUnitId: attacker.id,
                defenderUnitId: defender.id,
                outcome: CombatOutcome(
                  attackerUnitId: attacker.id,
                  defenderUnitId: defender.id,
                  attackerHpAfter: 10,
                  defenderHpAfter: 5,
                  attackerKilled: false,
                  defenderKilled: false,
                ),
              ),
              const TechnologyResearchedEvent(
                playerId: 'player_1',
                technologyId: TechnologyId.agriculture,
              ),
            ],
            state: GameState(
              activePlayerId: 'player_1',
              cities: const [city],
              units: [attacker, defender],
            ),
            previousState: GameState(
              activePlayerId: 'player_1',
              cities: const [city],
              units: [attacker, defender],
            ),
          ),
          [GameSoundCue.city, GameSoundCue.attack],
        );
      },
    );

    test('suppresses event cues that do not belong to the audible player', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_2',
        name: 'Far City',
        center: CityHex(col: 4, row: 4),
      );

      expect(
        GameSoundCueMapper.forEvents(
          events: const [
            CityBuiltBuildingEvent(
              cityId: 'city_1',
              buildingType: CityBuildingType.granary,
            ),
            TechnologyResearchedEvent(
              playerId: 'player_2',
              technologyId: TechnologyId.agriculture,
            ),
          ],
          state: const GameState(activePlayerId: 'player_1', cities: [city]),
          previousState: const GameState(
            activePlayerId: 'player_1',
            cities: [city],
          ),
        ),
        isEmpty,
      );
    });

    test('does not map renderer effects directly to avoid duplicate cues', () {
      expect(
        GameSoundCueMapper.forRendererEffects(
          effects: const [
            PlayCombatAnimationEffect(
              attackerUnitId: 'archer_1',
              defenderUnitId: 'enemy_1',
            ),
          ],
          state: const GameState(activePlayerId: 'player_1'),
          previousState: const GameState(activePlayerId: 'player_1'),
        ),
        isEmpty,
      );
    });
  });
}
