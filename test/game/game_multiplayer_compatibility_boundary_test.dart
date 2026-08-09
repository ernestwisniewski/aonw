import 'dart:async';

import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/game/game_multiplayer_compatibility_boundary.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _saveId = 'save_1';
const _childKey = Key('game-route-child');

void main() {
  testWidgets('active online route is closed until compatibility is allowed', (
    tester,
  ) async {
    const scenarios = [
      (access: MultiplayerAccessState.pending, opens: false),
      (access: MultiplayerAccessState.updateRequired, opens: false),
      (access: MultiplayerAccessState.unavailable, opens: false),
      (access: MultiplayerAccessState.allowed, opens: true),
    ];

    for (final scenario in scenarios) {
      final repository = _RecordingGameRepository(_save(GameMode.multiplayer));
      final container = ProviderContainer(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          multiplayerAccessStateProvider.overrideWithValue(scenario.access),
          networkSessionProvider.overrideWithValue(_networkSession()),
        ],
      );
      addTearDown(container.dispose);

      await _pumpBoundary(tester, container);

      expect(
        find.byKey(_childKey),
        scenario.opens ? findsOneWidget : findsNothing,
        reason: '${scenario.access} route decision',
      );
      expect(
        repository.loadCount,
        0,
        reason: '${scenario.access} must be decided before a snapshot read',
      );
    }
  });

  testWidgets(
    'explicit network save with AI stays closed without an active session',
    (tester) async {
      final repository = _RecordingGameRepository(
        _save(
          GameMode.multiplayer,
          origin: GameSaveOrigin.network,
          players: _localSinglePlayerParticipants,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repository),
          multiplayerAccessStateProvider.overrideWithValue(
            MultiplayerAccessState.updateRequired,
          ),
          networkSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await _pumpBoundary(tester, container);

      expect(repository.loadCount, 1);
      expect(find.byKey(_childKey), findsNothing);
      expect(
        find.text('Could not resume the last multiplayer session.'),
        findsOneWidget,
      );
      expect(find.text('RETRY'), findsOneWidget);
    },
  );

  testWidgets(
    'local save stays mounted during refresh despite multiplayer status',
    (tester) async {
      for (final access in [
        MultiplayerAccessState.updateRequired,
        MultiplayerAccessState.unavailable,
      ]) {
        final repository = _RecordingGameRepository(
          _save(
            NewGameFlow.singlePlayer.gameMode,
            name: 'multi campaign',
            origin: GameSaveOrigin.local,
            players: _localSinglePlayerParticipants,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            gameRepositoryProvider.overrideWithValue(repository),
            multiplayerAccessStateProvider.overrideWithValue(access),
            networkSessionProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        await _pumpBoundary(tester, container);

        expect(repository.loadCount, 1, reason: '$access local read');
        expect(find.byKey(_childKey), findsOneWidget, reason: '$access route');
        expect(NewGameFlow.singlePlayer.gameMode, GameMode.multiplayer);

        final reloadGate = Completer<void>();
        repository.pauseNextLoadUntil(reloadGate.future);
        container.invalidate(gameSaveSnapshotProvider(_saveId));
        await tester.pump();

        expect(
          find.byKey(_childKey),
          findsOneWidget,
          reason: '$access refresh',
        );

        reloadGate.complete();
        await tester.pumpAndSettle();
        expect(
          find.byKey(_childKey),
          findsOneWidget,
          reason: '$access reloaded',
        );
      }
    },
  );

  testWidgets('unavailable check can retry and then open an online route', (
    tester,
  ) async {
    var attempts = 0;
    final repository = _RecordingGameRepository(_save(GameMode.multiplayer));
    final container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repository),
        multiplayerUpdateCheckEnabledProvider.overrideWithValue(true),
        multiplayerUpdateNoticeProvider.overrideWith((_) async {
          attempts++;
          if (attempts == 1) throw StateError('temporary outage');
          return null;
        }),
        networkSessionProvider.overrideWithValue(_networkSession()),
      ],
    );
    addTearDown(container.dispose);

    await _pumpBoundary(tester, container);

    expect(find.byKey(_childKey), findsNothing);
    expect(find.text('RETRY'), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(_childKey), findsOneWidget);
    expect(repository.loadCount, 0);
  });
}

Future<void> _pumpBoundary(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameMultiplayerCompatibilityBoundary(
          saveId: _saveId,
          child: SizedBox(key: _childKey),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

NetworkSession _networkSession() {
  return NetworkSession(
    userId: 'user_1',
    playerId: 'player_1',
    token: AuthToken('token'),
    matchId: _saveId,
    connectionState: const NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
    ),
  );
}

const _localSinglePlayerParticipants = [
  Player(id: 'human', name: 'Human', colorValue: 0xFF4A7FC4),
  Player(
    id: 'ai',
    name: 'AI',
    colorValue: 0xFFC45050,
    kind: PlayerKind.ai,
    ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1),
  ),
];

GameSave _save(
  GameMode gameMode, {
  String name = 'Game',
  List<Player> players = const [],
  GameSaveOrigin origin = GameSaveOrigin.local,
}) {
  return GameSave(
    id: _saveId,
    name: name,
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {},
    savedAt: DateTime.utc(2026, 8, 9),
    camera: CameraState.zero,
    players: players,
    gameMode: gameMode,
    origin: origin,
  );
}

final class _RecordingGameRepository implements GameRepository {
  _RecordingGameRepository(this.gameSave);

  final GameSave gameSave;
  int loadCount = 0;
  Future<void>? _nextLoadGate;

  void pauseNextLoadUntil(Future<void> gate) => _nextLoadGate = gate;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) => throw UnimplementedError();

  @override
  Future<void> delete(String saveId) => throw UnimplementedError();

  @override
  Future<List<GameSaveIndex>> list() => throw UnimplementedError();

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    loadCount++;
    final gate = _nextLoadGate;
    _nextLoadGate = null;
    if (gate != null) await gate;
    return GameSnapshotFactory.create(save: gameSave);
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) =>
      throw UnimplementedError();

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) => throw UnimplementedError();
}
