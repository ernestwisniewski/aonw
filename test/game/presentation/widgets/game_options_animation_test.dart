import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/widgets/options/game_options_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map options toggle gameplay animations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GameOptionsOverlay(
              session: _session(),
              allowGraphicMode: false,
              onViewModeChanged: (_) {},
              displaySettings: const HexDisplaySettings(),
              onToggleTerrain: () {},
              onToggleResources: () {},
              onToggleHeightBadge: () {},
              onToggleCitySites: () {},
              onToggleCityGrowth: () {},
              onToggleHexBorders: () {},
              onToggleHeightWalls: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('gameOptions.optionsButton')));
    await tester.pump();
    final row = find.byKey(const Key('gameOptions.showAnimationsRow'));
    await tester.ensureVisible(row);
    await tester.pump();
    expect(
      find.byKey(const Key('gameOptions.showAnimationsIcon.on')),
      findsOneWidget,
    );

    await tester.tap(row);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameOptionsOverlay)),
      listen: false,
    );
    expect(container.read(gameplaySettingsProvider).showAnimations, isFalse);
    expect(
      find.byKey(const Key('gameOptions.showAnimationsIcon.off')),
      findsOneWidget,
    );

    final cameraRow = find.byKey(
      const Key('gameOptions.animateCameraTransitionsRow'),
    );
    await tester.ensureVisible(cameraRow);
    await tester.pump();
    await tester.tap(cameraRow);
    await tester.pump();
    expect(
      container.read(gameplaySettingsProvider).animateCameraTransitions,
      isFalse,
    );
    expect(
      find.byKey(const Key('gameOptions.animateCameraTransitionsIcon.off')),
      findsOneWidget,
    );
  });
}

GameSession _session() => GameSession(
  mapData: WorldMap(
    cols: 1,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
    ],
  ),
  viewMode: MapViewMode.tile,
  saveId: 'save',
);
