import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/app/composition/app_composition.dart';
import 'package:aonw_flutter/app/telemetry/client_telemetry.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
  final lifecycle = _lifecycleOracle();

  testWidgets('composition owns one controller and closes its repository', (
    tester,
  ) async {
    final first = _LifecycleMapRepository();
    final second = _LifecycleMapRepository();
    final firstInput = _LifecycleMapInputSource();
    final secondInput = _LifecycleMapInputSource();

    await tester.pumpWidget(
      AppComposition(mapRepository: first, mapInputSource: firstInput).root,
    );
    await tester.pump();
    expect(first.loadCalls, 1);
    expect(first.closeCalls, 0);
    expect(firstInput.closeCalls, 0);

    await tester.pumpWidget(
      AppComposition(mapRepository: second, mapInputSource: secondInput).root,
    );
    await tester.pump();
    final expected = lifecycle['routeReplace'] as Map<String, dynamic>;
    expect(first.closeCalls, expected['oldRepositoryCloseCalls']);
    expect(firstInput.closeCalls, expected['oldInputCloseCalls']);
    expect(second.loadCalls, expected['newRepositoryLoadCalls']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(second.closeCalls, 1);
    expect(secondInput.closeCalls, 1);
  });

  testWidgets('application lifecycle pauses and resumes gamepad input', (
    tester,
  ) async {
    final repository = _LifecycleMapRepository();
    final input = _LifecycleMapInputSource();
    final telemetry = _RecordingClientTelemetry();
    final games = <AonwFlameGame>[];
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pumpWidget(
      AppComposition(
        mapRepository: repository,
        mapInputSource: input,
        flameGameFactory: () {
          final game = AonwFlameGame();
          games.add(game);
          return game;
        },
        telemetry: telemetry,
      ).root,
    );
    await tester.pump();
    expect(input.activeStates, [true]);
    expect(telemetry.events, [ClientTelemetryEvent.appStarted]);
    expect(games.single.debugViewportActive, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(input.activeStates.last, isFalse);
    expect(repository.closeCalls, 0);
    expect(telemetry.events.last, ClientTelemetryEvent.appSuspended);
    expect(games.single.debugViewportActive, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(input.activeStates.last, isTrue);
    final expected = lifecycle['pauseResume'] as Map<String, dynamic>;
    expect(
      repository.closeCalls,
      expected['repositoryCloseCallsBeforeUnmount'],
    );
    expect(input.activeStates, expected['inputActiveStates']);
    expect(telemetry.events.map((event) => event.code), expected['telemetry']);
    expect(games.single.debugViewportActive, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(input.activeStates.last, isFalse);
    expect(repository.closeCalls, 1);
    expect(games.single.debugDisposed, isTrue);
  });

  testWidgets('route replacement never duplicates game session or input', (
    tester,
  ) async {
    final games = <AonwFlameGame>[];
    final firstRepository = _LifecycleMapRepository();
    final secondRepository = _LifecycleMapRepository();
    final firstInput = _LifecycleMapInputSource();
    final secondInput = _LifecycleMapInputSource();

    AonwFlameGame createGame() {
      final game = AonwFlameGame();
      games.add(game);
      return game;
    }

    await tester.pumpWidget(
      AppComposition(
        mapRepository: firstRepository,
        mapInputSource: firstInput,
        flameGameFactory: createGame,
      ).root,
    );
    await tester.pumpAndSettle();

    expect(games, hasLength(1));
    expect(games.single.debugMountCount, 1);
    expect(games.single.debugViewportActive, isTrue);
    expect(firstRepository.loadCalls, 1);
    expect(firstInput.listenCalls, 1);

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isFalse);
    expect(firstRepository.closeCalls, 0);
    expect(firstInput.listenCalls, 1);
    expect(firstInput.cancelCalls, 0);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(games.single.debugViewportActive, isTrue);
    expect(firstInput.listenCalls, 1);

    await tester.pumpWidget(
      AppComposition(
        mapRepository: secondRepository,
        mapInputSource: secondInput,
        flameGameFactory: createGame,
      ).root,
    );
    await tester.pumpAndSettle();

    expect(games, hasLength(2));
    expect(games.first.debugDisposed, isTrue);
    expect(firstRepository.closeCalls, 1);
    expect(firstInput.listenCalls, 1);
    expect(firstInput.cancelCalls, 1);
    expect(firstInput.closeCalls, 1);
    expect(secondRepository.loadCalls, 1);
    expect(secondInput.listenCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(games.last.debugDisposed, isTrue);
    expect(secondRepository.closeCalls, 1);
    expect(secondInput.cancelCalls, 1);
    expect(secondInput.closeCalls, 1);
  });
}

Map<String, dynamic> _lifecycleOracle() {
  for (final path in [
    '../../aonw_tests/fixtures/input/flutter_viewport_oracle.json',
    'aonw_tests/fixtures/input/flutter_viewport_oracle.json',
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      final value = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return value['lifecycle'] as Map<String, dynamic>;
    }
  }
  throw StateError('Flutter viewport oracle fixture not found.');
}

final class _RecordingClientTelemetry implements ClientTelemetry {
  final events = <ClientTelemetryEvent>[];

  @override
  void record(ClientTelemetryEvent event) => events.add(event);
}

final class _LifecycleMapInputSource
    implements MapInputSource, LifecycleAwareMapInputSource {
  _LifecycleMapInputSource() {
    _commands = StreamController<MapInputCommand>.broadcast(
      onListen: () => listenCalls += 1,
      onCancel: () => cancelCalls += 1,
    );
  }

  var closeCalls = 0;
  var listenCalls = 0;
  var cancelCalls = 0;
  final activeStates = <bool>[];
  late final StreamController<MapInputCommand> _commands;

  @override
  Stream<MapInputCommand> get commands => _commands.stream;

  @override
  Future<void> close() async {
    closeCalls += 1;
    await _commands.close();
  }

  @override
  void setActive(bool active) => activeStates.add(active);
}

final class _LifecycleMapRepository implements MapRepository {
  var loadCalls = 0;
  var closeCalls = 0;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    loadCalls += 1;
    return testMapScene();
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<void> close() async {
    closeCalls += 1;
  }
}
