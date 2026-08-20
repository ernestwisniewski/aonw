import 'package:aonw/game/application/services/local_single_player_turn_phase.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closes the city production panel', () {
    final audio = _RecordingAudioController();
    final container = ProviderContainer(
      overrides: [gameAudioControllerProvider.overrideWithValue(audio)],
    );
    addTearDown(container.dispose);

    container
        .read(hudPanelControllerProvider.notifier)
        .apply(const HudPanelModes(cityBuildings: true));

    container.read(hudCommandDispatcherProvider).closeCityProductionPanel();

    expect(container.read(hudPanelControllerProvider).cityBuildings, isFalse);
    expect(audio.cues, contains(GameSoundCue.uiPanelClose));
  });

  test(
    'city production dispatch closes the panel without close sound',
    () async {
      final audio = _RecordingAudioController();
      final container = ProviderContainer(
        overrides: [gameAudioControllerProvider.overrideWithValue(audio)],
      );
      addTearDown(container.dispose);

      container
          .read(hudPanelControllerProvider.notifier)
          .apply(const HudPanelModes(cityBuildings: true));

      await container
          .read(hudCommandDispatcherProvider)
          .startCityBuilding('city-1', CityBuildingType.granary);

      expect(container.read(hudPanelControllerProvider).cityBuildings, isFalse);
      expect(audio.cues, isNot(contains(GameSoundCue.uiPanelClose)));
    },
  );

  test(
    'technology selection closes the technology panel without close sound',
    () async {
      final audio = _RecordingAudioController();
      final container = ProviderContainer(
        overrides: [gameAudioControllerProvider.overrideWithValue(audio)],
      );
      addTearDown(container.dispose);

      container
          .read(hudPanelControllerProvider.notifier)
          .apply(const HudPanelModes(technology: true));

      await container
          .read(hudCommandDispatcherProvider)
          .selectTechnology(
            activePlayerId: 'player-1',
            technologyId: TechnologyId.agriculture,
          );

      expect(container.read(hudPanelControllerProvider).technology, isFalse);
      expect(audio.cues, isNot(contains(GameSoundCue.uiPanelClose)));
    },
  );

  test('opening the technology panel plays the technology cue', () {
    final audio = _RecordingAudioController();
    final container = ProviderContainer(
      overrides: [gameAudioControllerProvider.overrideWithValue(audio)],
    );
    addTearDown(container.dispose);

    container
        .read(hudCommandDispatcherProvider)
        .openTechnologyPanel(
          activePlayerId: 'player-1',
          state: GameClientState(activePlayerId: 'player-1'),
        );

    expect(container.read(hudPanelControllerProvider).technology, isTrue);
    expect(audio.cues, [GameSoundCue.technology]);
  });

  test('resource breakdown closes objectives while opening', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(hudPanelControllerProvider.notifier)
        .apply(const HudPanelModes(objectives: true));

    container
        .read(hudCommandDispatcherProvider)
        .toggleResourceBreakdown(ResourceBreakdownType.gold);

    expect(
      container.read(hudResourceBreakdownControllerProvider),
      TopResourcePopupType.gold,
    );
    expect(container.read(hudPanelControllerProvider).objectives, isFalse);
  });

  test('victory breakdown closes objectives while opening', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(hudPanelControllerProvider.notifier)
        .apply(const HudPanelModes(objectives: true));

    container.read(hudCommandDispatcherProvider).toggleVictoryBreakdown();

    expect(
      container.read(hudResourceBreakdownControllerProvider),
      TopResourcePopupType.victory,
    );
    expect(container.read(hudPanelControllerProvider).objectives, isFalse);
  });

  test('blocked human interaction cannot open or toggle HUD panels', () {
    final audio = _RecordingAudioController();
    final container = _blockedContainer(audio: audio);
    addTearDown(container.dispose);
    final dispatcher = container.read(hudCommandDispatcherProvider);
    final city = _city();
    final state = GameClientState(
      activePlayerId: 'player-1',
      interaction: InteractionState(
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0,
        ),
      ),
    );

    dispatcher
      ..openCityProductionPanel(state: state)
      ..openTechnologyPanel(activePlayerId: 'player-1', state: state)
      ..openObjectivesPanel(activePlayerId: 'player-1', state: state)
      ..openEmpirePanel(activePlayerId: 'player-1', state: state)
      ..openActivityLogPanel(activePlayerId: 'player-1', state: state)
      ..toggleCityProductionPanel(state: state)
      ..toggleTechnologyPanel(activePlayerId: 'player-1', state: state)
      ..toggleObjectivesPanel(activePlayerId: 'player-1', state: state)
      ..toggleEmpirePanel(activePlayerId: 'player-1', state: state)
      ..toggleActivityLogPanel(activePlayerId: 'player-1', state: state);

    expect(container.read(hudPanelControllerProvider), const HudPanelModes());
    expect(audio.cues, isEmpty);
  });

  test('blocked human interaction may still close panels through toggles', () {
    final container = _blockedContainer();
    addTearDown(container.dispose);
    container
        .read(hudPanelControllerProvider.notifier)
        .apply(
          const HudPanelModes(
            cityBuildings: true,
            technology: true,
            objectives: true,
            empire: true,
            activityLog: true,
          ),
        );
    container.read(hudCommandDispatcherProvider)
      ..toggleCityProductionPanel(state: null)
      ..toggleTechnologyPanel(activePlayerId: 'player-1', state: null)
      ..toggleObjectivesPanel(activePlayerId: 'player-1', state: null)
      ..toggleEmpirePanel(activePlayerId: 'player-1', state: null)
      ..toggleActivityLogPanel(activePlayerId: 'player-1', state: null);

    expect(container.read(hudPanelControllerProvider), const HudPanelModes());
  });

  test('blocked human interaction only allows closing resource popups', () {
    final audio = _RecordingAudioController();
    final container = _blockedContainer(audio: audio);
    addTearDown(container.dispose);
    final dispatcher = container.read(hudCommandDispatcherProvider)
      ..toggleResourceBreakdown(ResourceBreakdownType.gold)
      ..toggleVictoryBreakdown();
    expect(container.read(hudResourceBreakdownControllerProvider), isNull);

    container
        .read(hudResourceBreakdownControllerProvider.notifier)
        .toggle(TopResourcePopupType.gold);
    dispatcher.toggleVictoryBreakdown();
    expect(
      container.read(hudResourceBreakdownControllerProvider),
      TopResourcePopupType.gold,
    );

    dispatcher.toggleResourceBreakdown(ResourceBreakdownType.gold);
    expect(container.read(hudResourceBreakdownControllerProvider), isNull);
    expect(audio.cues, [GameSoundCue.uiPanelClose]);
  });

  test('auto-explore without a legal target does not show HUD feedback', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final scout = _unit(GameUnitType.scout);

    container
        .read(hudCommandDispatcherProvider)
        .autoExploreSelectedUnit(
          GameClientState(
            units: [scout],
            fogOfWar: _fullyDiscoveredFog(cols: 2, rows: 1),
            interaction: InteractionState(selection: GameSelection.unit(scout)),
          ),
        );

    expect(container.read(hudFeedbackProvider), isEmpty);
  });

  test('attack targeting closes primary panels for the selected unit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final warrior = _unit(GameUnitType.warrior);
    container
        .read(hudPanelControllerProvider.notifier)
        .apply(const HudPanelModes(objectives: true));

    container
        .read(hudCommandDispatcherProvider)
        .startAttackTargeting(
          GameClientState(
            units: [warrior],
            interaction: InteractionState(
              selection: GameSelection.unit(warrior),
            ),
          ),
        );

    expect(container.read(hudPanelControllerProvider).objectives, isFalse);
  });
}

class _RecordingAudioController extends GameAudioController {
  final cues = <GameSoundCue>[];

  @override
  Future<void> play(GameSoundCue cue, {double volume = 1}) async {
    cues.add(cue);
  }

  @override
  void playAll(Iterable<GameSoundCue> cues) {
    this.cues.addAll(cues);
  }
}

ProviderContainer _blockedContainer({_RecordingAudioController? audio}) {
  return ProviderContainer(
    overrides: [
      gamePlayerControlControllerProvider.overrideWithValue(
        const PlayerControlState(
          activePlayerId: 'player-1',
          phase: LocalSinglePlayerTurnPhase.aiResolving,
        ),
      ),
      if (audio != null) gameAudioControllerProvider.overrideWithValue(audio),
    ],
  );
}

GameUnit _unit(GameUnitType type) {
  return GameUnit(
    id: '${type.name}_1',
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 0,
    row: 0,
  );
}

FogOfWarState _fullyDiscoveredFog({required int cols, required int rows}) {
  final hexes = {
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: row),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: hexes,
        visibleHexes: hexes,
      ),
    },
  );
}

GameCity _city() {
  return const GameCity(
    id: 'city-1',
    ownerPlayerId: 'player-1',
    name: 'City',
    center: CityHex(col: 0, row: 0),
  );
}
