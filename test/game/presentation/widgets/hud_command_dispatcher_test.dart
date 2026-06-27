import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue.dart';
import 'package:aonw/game/presentation/providers/audio/game_audio_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
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
          state: const GameState(activePlayerId: 'player-1'),
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

  test('auto-explore without a legal target does not show HUD feedback', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final scout = _unit(GameUnitType.scout);

    container
        .read(hudCommandDispatcherProvider)
        .autoExploreSelectedUnit(
          GameState(
            units: [scout],
            fogOfWar: _fullyDiscoveredFog(cols: 2, rows: 1),
            interaction: GameInteractionState(
              selection: GameSelection.unit(scout),
            ),
          ),
          _grassMap(cols: 2, rows: 1),
        );

    expect(container.read(hudFeedbackProvider), isEmpty);
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

MapData _grassMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
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
