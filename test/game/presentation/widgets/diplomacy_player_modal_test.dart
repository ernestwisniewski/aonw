import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders player diplomacy details and actions', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    GameCommand? dispatched;
    await _pumpModal(
      tester,
      gameState: _state(),
      onCommand: (command) async => dispatched = command,
    );

    expect(
      find.byKey(const Key('diplomacyPlayerModal.surface')),
      findsOneWidget,
    );
    expect(find.text('Diplomacy'), findsOneWidget);
    expect(find.textContaining('Bob'), findsWidgets);
    expect(find.textContaining('Bob · Germany'), findsOneWidget);
    expect(find.text('Relations'), findsOneWidget);
    expect(find.text('Treaty'), findsOneWidget);
    expect(find.text('Attitude'), findsOneWidget);
    expect(find.text('Treaty benefits'), findsOneWidget);
    expect(find.text('No treaty benefits'), findsOneWidget);
    expect(find.text('What changes relations'), findsOneWidget);
    expect(find.textContaining('Proposal accepted'), findsWidgets);
    expect(find.textContaining('Dispatch response'), findsWidgets);
    expect(find.text('+18'), findsWidgets);
    expect(find.text('-8'), findsWidgets);
    expect(
      find.byKey(const Key('diplomacy.relationChart.turn.4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diplomacy.relationChart.turn.5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diplomacy.relationChart.turn.6')),
      findsOneWidget,
    );
    expect(find.text('History'), findsOneWidget);
    expect(find.textContaining('Unit attack'), findsOneWidget);
    expect(
      find.textContaining('Dispatches: Your units are blocking my routes.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Proposals: Friendship proposal'),
      findsOneWidget,
    );
    expect(find.text('Dispatches'), findsOneWidget);
    expect(find.text('Conciliatory (+20)'), findsOneWidget);
    expect(find.text('Neutral (+6)'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
    expect(
      find.textContaining('Friendship proposal: likely rejected'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Truce proposal: likely rejected'),
      findsOneWidget,
    );
    expect(find.text('Strategic resources'), findsOneWidget);
    expect(find.text('Import horses'), findsOneWidget);
    expect(find.text('Trade iron for horses'), findsOneWidget);

    await tester.tap(find.widgetWithText(EpicButton, 'Trade iron for horses'));
    await tester.pump();

    expect(dispatched, isA<OpenResourceExchangeCommand>());
    final exchange = dispatched as OpenResourceExchangeCommand;
    expect(exchange.playerId, 'player_1');
    expect(exchange.targetPlayerId, 'player_2');
    expect(exchange.offeredResource, ResourceType.iron);
    expect(exchange.requestedResource, ResourceType.horses);
    expect(exchange.durationTurns, 8);

    await tester.tap(find.widgetWithText(EpicButton, 'Import horses'));
    await tester.pump();

    expect(dispatched, isA<OpenResourceTradeCommand>());
    final trade = dispatched as OpenResourceTradeCommand;
    expect(trade.playerId, 'player_1');
    expect(trade.targetPlayerId, 'player_2');
    expect(trade.resource, ResourceType.horses);
    expect(trade.goldPerTurn, 2);
    expect(trade.durationTurns, 8);

    await tester.tap(find.widgetWithText(EpicButton, 'Propose friendship'));
    await tester.pump();

    expect(dispatched, isA<SendDiplomaticProposalCommand>());
    expect(
      (dispatched as SendDiplomaticProposalCommand).kind,
      DiplomaticProposalKind.friendship,
    );
  });

  testWidgets('adds peace payment to truce proposals during war', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final baseState = _state();
    final state = baseState.copyWith(
      playerGold: const {
        'player_1': DiplomaticProposalForecast.minimumTruceGoldPayment,
      },
      diplomacy: baseState.diplomacy.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.war,
      ),
    );
    GameCommand? dispatched;

    await _pumpModal(
      tester,
      gameState: state,
      onCommand: (command) async => dispatched = command,
    );

    expect(
      find.textContaining('Truce proposal: likely accepted'),
      findsOneWidget,
    );
    expect(find.text('Peace terms: 5 gold'), findsOneWidget);

    await tester.tap(find.widgetWithText(EpicButton, 'Propose truce'));
    await tester.pump();

    expect(dispatched, isA<SendDiplomaticProposalCommand>());
    final command = dispatched as SendDiplomaticProposalCommand;
    expect(command.kind, DiplomaticProposalKind.truce);
    expect(
      command.goldPayment,
      DiplomaticProposalForecast.minimumTruceGoldPayment,
    );
  });

  testWidgets('sends gold gift proposals from diplomacy actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    GameCommand? dispatched;
    await _pumpModal(
      tester,
      gameState: _state().copyWith(playerGold: const {'player_1': 12}),
      onCommand: (command) async => dispatched = command,
    );

    expect(find.text('Gold gift: 10 gold'), findsOneWidget);

    await tester.tap(find.widgetWithText(EpicButton, 'Send gold gift'));
    await tester.pump();

    expect(dispatched, isA<SendGoldGiftCommand>());
    final command = dispatched as SendGoldGiftCommand;
    expect(command.playerId, 'player_1');
    expect(command.targetPlayerId, 'player_2');
    expect(command.amount, 10);
  });
}

Future<void> _pumpModal(
  WidgetTester tester, {
  required GameState gameState,
  required Future<void> Function(GameCommand command) onCommand,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DiplomacyPlayerModal(
          gameSave: _save(),
          gameState: gameState,
          mapData: _map(),
          activePlayerId: 'player_1',
          targetPlayerId: 'player_2',
          onCommand: onCommand,
        ),
      ),
    ),
  );
}

GameSave _save() {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    turn: 6,
    savedAt: DateTime.utc(2026, 5, 5),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
      Player(
        id: 'player_2',
        name: 'Bob',
        colorValue: 0xFFDC2626,
        country: PlayerCountry.germany,
      ),
    ],
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    },
  );
}

GameState _state() {
  final message =
      DiplomaticMessage.create(
        id: 'message_1',
        fromPlayerId: 'player_2',
        toPlayerId: 'player_1',
        topic: DiplomaticMessageTopic.blockedRoutes,
        createdTurn: 5,
        expiresOnTurn: 10,
      ).copyWith(
        response: DiplomaticMessageResponse.evasive,
        respondedTurn: 5,
        relationScoreDelta: -8,
        relationScoreAfter: -55,
      );
  const proposal = DiplomaticProposal(
    id: 'proposal_1',
    fromPlayerId: 'player_1',
    toPlayerId: 'player_2',
    kind: DiplomaticProposalKind.friendship,
    createdTurn: 6,
    expiresOnTurn: 11,
  );
  return GameState(
    activePlayerId: 'player_1',
    diplomacy: DiplomacyState.empty
        .adjustRelationScore(
          'player_1',
          'player_2',
          -10,
          turn: 4,
          reason: DiplomaticScoreChangeReason.unitAttack,
          sourceId: 'unit_attack_1',
        )
        .adjustRelationScore(
          'player_1',
          'player_2',
          -30,
          turn: 4,
          reason: DiplomaticScoreChangeReason.cityAttack,
          sourceId: 'city_attack_1',
        )
        .adjustRelationScore(
          'player_1',
          'player_2',
          -25,
          turn: 4,
          reason: DiplomaticScoreChangeReason.declarationOfWar,
          sourceId: 'war_1',
        )
        .adjustRelationScore(
          'player_1',
          'player_2',
          18,
          turn: 4,
          reason: DiplomaticScoreChangeReason.proposalAccepted,
          sourceId: 'proposal_1',
        )
        .adjustRelationScore(
          'player_1',
          'player_2',
          -8,
          turn: 5,
          reason: DiplomaticScoreChangeReason.messageResponse,
          sourceId: 'message_1',
        )
        .adjustRelationScore(
          'player_1',
          'player_2',
          -15,
          turn: 6,
          reason: DiplomaticScoreChangeReason.promiseBroken,
          sourceId: 'message_2',
        )
        .setStatus('player_1', 'player_3', DiplomaticRelationStatus.war)
        .setStatus('player_2', 'player_3', DiplomaticRelationStatus.war)
        .addMessage(
          DiplomaticMessage.create(
            id: 'message_3',
            fromPlayerId: 'player_2',
            toPlayerId: 'player_1',
            topic: DiplomaticMessageTopic.commonEnemy,
            createdTurn: 6,
            expiresOnTurn: 11,
          ),
        )
        .addMessage(message)
        .addProposal(proposal),
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.ironWorking},
        ),
        'player_2': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.animalHusbandry},
        ),
      },
    ),
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Krakow',
        population: 3,
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Rome',
        population: 4,
        center: CityHex(col: 2, row: 0),
      ),
    ],
    units: [
      GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      ),
      GameUnit(
        id: 'unit_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.archer,
        name: 'Archer',
        col: 2,
        row: 0,
      ),
    ],
  );
}

MapData _map() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: switch (col) {
            0 => const [ResourceType.iron],
            2 => const [ResourceType.horses],
            _ => const [],
          },
          height: 0,
        ),
    ],
  );
}
