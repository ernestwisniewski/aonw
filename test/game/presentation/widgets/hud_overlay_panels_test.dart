import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_dialog.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_overlay_panel_slot.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_overlay_panels.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_dialog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _player = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 16),
  camera: CameraState.zero,
  players: const [_player],
);

void main() {
  group('HudOverlayPanels', () {
    testWidgets('renders no overlay slots when all panels are inactive', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_panels()));

      expect(find.byType(HudOverlayPanelSlot), findsNothing);
      expect(find.byType(TechnologyTreePanel), findsNothing);
      expect(find.byType(CityProductionPanel), findsNothing);
    });

    testWidgets('renders technology panel when technology is active', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_panels(technologyActive: true)));

      expect(find.byType(HudOverlayPanelSlot), findsOneWidget);
      expect(find.byType(TechnologyTreePanel), findsOneWidget);
    });

    testWidgets('renders city production panel for selected city', (
      tester,
    ) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Miasto',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );

      await tester.pumpWidget(
        _app(
          _panels(
            cityProductionCity: city,
            gameState: const GameState(cities: [city]),
          ),
        ),
      );

      final panel = tester.widget<CityProductionPanel>(
        find.byType(CityProductionPanel),
      );

      expect(panel.city.id, 'city_1');
      expect(panel.productionPerTurn, 2);
    });
  });
}

Widget _app(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

HudOverlayPanels _panels({
  bool technologyActive = false,
  GameCity? cityProductionCity,
  GameState? gameState,
}) {
  return HudOverlayPanels(
    panelPadding: EdgeInsets.zero,
    technologyActive: technologyActive,
    empireActive: false,
    activityLogActive: false,
    cityProductionCity: cityProductionCity,
    gameState: gameState,
    activePlayerId: 'player_1',
    technologyViewModel: TechnologyPanelViewModel.empty,
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    mapData: _mapData(),
    cityProductionPerTurn: 2,
    activityLogEntries: const [],
    gameSave: _save,
  );
}

MapData _mapData() {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 2; col++)
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
