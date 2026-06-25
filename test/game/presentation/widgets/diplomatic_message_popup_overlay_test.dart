import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomatic_message_popup_overlay.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows an incoming diplomatic message popup for the recipient', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsOneWidget);
    expect(find.text('From: Alice'), findsOneWidget);
    expect(find.text('Your units are blocking my routes.'), findsOneWidget);
    expect(find.text('Conciliatory'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('Evasive'), findsOneWidget);
    expect(find.text('Aggressive'), findsOneWidget);

    await tester.tap(find.byKey(const Key('diplomaticMessageDialog.later')));
    await tester.pumpAndSettle();

    expect(find.text('New dispatch'), findsNothing);

    final state = container.read(hudMinimizedPopupsProvider);
    final entry = state.entries.single;
    expect(entry.id, _messagePopupId);
    expect(entry.kind, HudMinimizedPopupKind.diplomaticMessage);
    expect(entry.title, 'New dispatch');
    expect(entry.payload['messageId'], 'message_1');
  });

  testWidgets('does not show an incoming message popup to the sender', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsNothing);

    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsOneWidget);
  });

  testWidgets('shows an incoming diplomatic proposal popup for the recipient', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addDiplomaticProposalNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('New proposal'), findsOneWidget);
    expect(find.text('From: Alice'), findsOneWidget);
    expect(find.text('Friendship proposal'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('diplomaticProposalDialog.later')));
    await tester.pumpAndSettle();

    expect(find.text('New proposal'), findsNothing);

    final state = container.read(hudMinimizedPopupsProvider);
    final entry = state.entries.single;
    expect(entry.id, _proposalPopupId);
    expect(entry.kind, HudMinimizedPopupKind.diplomaticProposal);
    expect(entry.title, 'New proposal');
    expect(entry.payload['proposalId'], 'proposal_1');
  });

  testWidgets(
    'does not dismiss an unanswered diplomatic proposal on backdrop tap',
    (tester) async {
      await _pumpOverlay(tester);
      await tester.pumpAndSettle();
      final container = _container(tester);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .selectPlayer(_save, 'player_2');
      await tester.pump();

      _addDiplomaticProposalNotification(container);
      await tester.pump();
      await tester.pump();

      expect(find.text('New proposal'), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(find.text('New proposal'), findsOneWidget);
      expect(container.read(hudMinimizedPopupsProvider).entries, isEmpty);
    },
  );

  testWidgets(
    'shows expired diplomatic proposals as passive diplomacy popups',
    (tester) async {
      await _pumpOverlay(tester);
      await tester.pumpAndSettle();
      final container = _container(tester);
      container
          .read(gamePlayerControlControllerProvider.notifier)
          .selectPlayer(_save, 'player_2');
      await tester.pump();

      _addExpiredProposalNotification(container);
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('diplomaticEventDialog.surface')),
        findsOneWidget,
      );
      expect(find.text('Diplomacy'), findsWidgets);
      expect(find.textContaining('Alice -> Bob'), findsOneWidget);
      expect(find.textContaining('Truce proposal'), findsOneWidget);
      expect(find.textContaining('Expired'), findsOneWidget);
      expect(find.textContaining('Blocked'), findsNothing);
    },
  );

  testWidgets('does not show an incoming proposal popup to the sender', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);

    _addDiplomaticProposalNotification(container);
    await tester.pump();
    await tester.pump();

    expect(find.text('New proposal'), findsNothing);

    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();
    await tester.pump();

    expect(find.text('New proposal'), findsOneWidget);
  });

  testWidgets('minimizes and restores an incoming diplomatic message popup', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('diplomaticMessageDialog.minimize')));
    await tester.pumpAndSettle();

    final state = container.read(hudMinimizedPopupsProvider);
    final entry = state.entries.single;
    expect(entry.id, _messagePopupId);
    expect(entry.kind, HudMinimizedPopupKind.diplomaticMessage);
    expect(entry.title, 'New dispatch');
    expect(entry.subtitle, contains('Alice'));
    expect(entry.subtitle, contains('Your units are blocking'));
    expect(entry.payload['messageId'], 'message_1');

    container
        .read(hudMinimizedPopupsProvider.notifier)
        .requestRestore(entry.id);
    await tester.pump();
    await tester.pump();

    expect(find.text('New dispatch'), findsOneWidget);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(entry.id),
      false,
    );
  });

  testWidgets('minimizes and restores an incoming diplomatic proposal popup', (
    tester,
  ) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addDiplomaticProposalNotification(container);
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('diplomaticProposalDialog.minimize')),
    );
    await tester.pumpAndSettle();

    final state = container.read(hudMinimizedPopupsProvider);
    final entry = state.entries.single;
    expect(entry.id, _proposalPopupId);
    expect(entry.kind, HudMinimizedPopupKind.diplomaticProposal);
    expect(entry.title, 'New proposal');
    expect(entry.subtitle, contains('Alice'));
    expect(entry.subtitle, contains('Friendship proposal'));
    expect(entry.payload['proposalId'], 'proposal_1');

    container
        .read(hudMinimizedPopupsProvider.notifier)
        .requestRestore(entry.id);
    await tester.pump();
    await tester.pump();

    expect(find.text('New proposal'), findsOneWidget);
    expect(
      container.read(hudMinimizedPopupsProvider).hasEntry(entry.id),
      false,
    );
  });

  testWidgets('response buttons close the popup', (tester) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addDiplomaticMessageNotification(container);
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('diplomaticMessageDialog.response.neutral')),
    );
    await tester.pumpAndSettle();

    expect(find.text('New dispatch'), findsNothing);
  });

  testWidgets('proposal response buttons close the popup', (tester) async {
    await _pumpOverlay(tester);
    await tester.pumpAndSettle();
    final container = _container(tester);
    container
        .read(gamePlayerControlControllerProvider.notifier)
        .selectPlayer(_save, 'player_2');
    await tester.pump();

    _addDiplomaticProposalNotification(container);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('diplomaticProposalDialog.accept')));
    await tester.pumpAndSettle();

    expect(find.text('New proposal'), findsNothing);
  });
}

Future<void> _pumpOverlay(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProviderScope(
          overrides: [gamePlayerControlSaveProvider.overrideWithValue(_save)],
          child: Scaffold(body: DiplomaticMessagePopupOverlay(gameSave: _save)),
        ),
      ),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(DiplomaticMessagePopupOverlay)),
    listen: false,
  );
}

void _addDiplomaticMessageNotification(ProviderContainer container) {
  final message = DiplomaticMessage.create(
    id: 'message_1',
    fromPlayerId: 'player_1',
    toPlayerId: 'player_2',
    topic: DiplomaticMessageTopic.blockedRoutes,
    createdTurn: 1,
    expiresOnTurn: 6,
  );
  final state = GameState(
    activePlayerId: 'player_2',
    playerColors: const {'player_1': 0xFF4A7FC4, 'player_2': 0xFFC45050},
    diplomacy: DiplomacyState.empty.addMessage(message),
  );
  container
      .read(gameEventNotificationsProvider.notifier)
      .addAll(
        [
          DiplomaticMessageSentEvent(
            messageId: message.id,
            fromPlayerId: message.fromPlayerId,
            toPlayerId: message.toPlayerId,
            topic: message.topic,
            category: message.category,
            expiresOnTurn: message.expiresOnTurn,
          ),
        ],
        state,
        visiblePlayerId: 'player_2',
      );
}

void _addDiplomaticProposalNotification(ProviderContainer container) {
  const proposal = DiplomaticProposal(
    id: 'proposal_1',
    fromPlayerId: 'player_1',
    toPlayerId: 'player_2',
    kind: DiplomaticProposalKind.friendship,
    createdTurn: 1,
    expiresOnTurn: 6,
  );
  final state = GameState(
    activePlayerId: 'player_2',
    playerColors: const {'player_1': 0xFF4A7FC4, 'player_2': 0xFFC45050},
    diplomacy: DiplomacyState.empty.addProposal(proposal),
  );
  container
      .read(gameEventNotificationsProvider.notifier)
      .addAll(
        [
          DiplomaticProposalSentEvent(
            proposalId: proposal.id,
            fromPlayerId: proposal.fromPlayerId,
            toPlayerId: proposal.toPlayerId,
            kind: proposal.kind,
            expiresOnTurn: proposal.expiresOnTurn,
          ),
        ],
        state,
        visiblePlayerId: 'player_2',
      );
}

void _addExpiredProposalNotification(ProviderContainer container) {
  const state = GameState(
    activePlayerId: 'player_2',
    playerColors: {'player_1': 0xFF4A7FC4, 'player_2': 0xFFC45050},
  );
  container
      .read(gameEventNotificationsProvider.notifier)
      .addAll(
        const [
          DiplomaticProposalExpiredEvent(
            proposalId: 'proposal_2',
            fromPlayerId: 'player_1',
            toPlayerId: 'player_2',
            kind: DiplomaticProposalKind.truce,
          ),
        ],
        state,
        visiblePlayerId: 'player_2',
      );
}

String get _messagePopupId {
  return HudMinimizedPopupIds.diplomaticMessage(_save.id, 'message_1');
}

String get _proposalPopupId {
  return HudMinimizedPopupIds.diplomaticProposal(_save.id, 'proposal_1');
}

final _save = GameSave(
  id: 'save',
  name: 'Game',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 5, 26),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4),
    Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050),
  ],
);
