import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('renders active agreements as directional per-turn flows', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await _pumpTradeModal(
      tester,
      state: _tradeState().copyWith(
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'horses_import',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 2,
            remainingTurns: 3,
            amountPerTurn: 2,
          ),
        ],
      ),
      mapData: _resourceMap(ResourceType.horses),
    );

    expect(find.text('Active agreements'), findsOneWidget);
    expect(
      find.text('Importing: 2 horses/turn · 2 gold/turn · 3 turns left'),
      findsOneWidget,
    );
  });

  testWidgets('explains and disables imports when gold is unavailable', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await _pumpTradeModal(
      tester,
      state: _tradeState().copyWith(playerGold: const {'player_1': 0}),
      mapData: _resourceMap(ResourceType.horses),
    );

    expect(
      find.text('You need at least 2 gold to start this import.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<EpicButton>(find.widgetWithText(EpicButton, 'Import horses'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('keeps the editor open and reports command failures', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await _pumpTradeModal(
      tester,
      state: _tradeState(),
      mapData: _resourceMap(ResourceType.horses),
      onCommand: (_) async => throw StateError('stale offer'),
    );

    await tester.tap(find.widgetWithText(EpicButton, 'Import horses'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The agreement could not be created. Review the terms and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Import horses'), findsOneWidget);
  });

  testWidgets('keeps the editor open when a stale offer is rejected', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await _pumpTradeModal(
      tester,
      state: _tradeState(),
      mapData: _resourceMap(ResourceType.horses),
      onResourceTradeCommand: (_) async => false,
    );

    await tester.tap(find.widgetWithText(EpicButton, 'Import horses'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The offer changed and could not be accepted. '
        'Review the available terms and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Import horses'), findsOneWidget);
  });

  testWidgets('offers stockpiled resources only from active extraction flow', (
    tester,
  ) async {
    _useLargeSurface(tester);
    final state = _tradeState(targetTechnology: TechnologyId.combustion)
        .copyWith(
          fieldImprovements: const [
            FieldImprovement(
              hex: CityHex(col: 2, row: 0),
              type: FieldImprovementType.oilWell,
              builtByCityId: 'city_2',
            ),
          ],
        );

    await _pumpTradeModal(
      tester,
      state: state,
      mapData: _resourceMap(ResourceType.oil),
    );
    expect(find.text('Import oil'), findsOneWidget);

    await _pumpTradeModal(
      tester,
      state: state.copyWith(fieldImprovements: const []),
      mapData: _resourceMap(ResourceType.oil),
    );
    expect(find.text('Import oil'), findsNothing);
  });

  testWidgets('offers marble in the strategic resource trade selector', (
    tester,
  ) async {
    _useLargeSurface(tester);
    await _pumpTradeModal(
      tester,
      state: _tradeState(targetTechnology: TechnologyId.mining),
      mapData: _resourceMap(ResourceType.marble),
    );

    expect(find.text('Import marble'), findsOneWidget);
  });
}

void _useLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpTradeModal(
  WidgetTester tester, {
  required GameClientState state,
  required WorldMap mapData,
  Future<void> Function(DomainCommand command)? onCommand,
  Future<bool> Function(DomainCommand command)? onResourceTradeCommand,
}) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: DiplomacyPlayerModal(
        gameSave: _save,
        gameState: state,
        mapData: mapData,
        activePlayerId: 'player_1',
        targetPlayerId: 'player_2',
        onCommand: onCommand ?? (_) async {},
        onResourceTradeCommand: onResourceTradeCommand,
      ),
    ),
  ),
);

GameClientState _tradeState({
  TechnologyId targetTechnology = TechnologyId.animalHusbandry,
}) => GameClientState(
  activePlayerId: 'player_1',
  playerGold: const {'player_1': 10},
  research: ResearchState(
    players: {
      'player_1': PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.ironWorking},
      ),
      'player_2': PlayerResearchState(
        unlockedTechnologyIds: {targetTechnology},
      ),
    },
  ),
  cities: const [
    GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Krakow',
      center: CityHex(col: 0, row: 0),
    ),
    GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'Rome',
      center: CityHex(col: 2, row: 0),
    ),
  ],
);

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'test',
  turn: 1,
  savedAt: DateTime.utc(2026, 8, 12),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 1),
    Player(id: 'player_2', name: 'Bob', colorValue: 2),
  ],
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
);

WorldMap _resourceMap(ResourceType resource) => WorldMap(
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < 3; col++)
      WorldTile(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: switch (col) {
          0 => const [ResourceType.iron],
          2 => [resource],
          _ => const [],
        },
        height: 0,
      ),
  ],
);
