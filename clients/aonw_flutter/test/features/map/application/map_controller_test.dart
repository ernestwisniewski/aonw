import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_controller.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('loads ready state and keeps interaction local', () async {
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene()),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state, isA<GameSessionReady>());

    controller.hover((col: 1, row: 1));
    controller.select((col: 2, row: 1));
    controller.toggleReference();

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient, same(ready.scene.player));
    expect(ready.turnPresentations.active?.turn, 1);
    expect(ready.interaction.hovered, (col: 1, row: 1));
    expect(ready.interaction.selected, (col: 2, row: 1));
    expect(ready.interaction.referenceVisible, isFalse);

    controller.completeTurnPresentation();
    expect(
      (controller.state as GameSessionReady).turnPresentations.active,
      isNull,
    );

    controller.select((col: 9, row: 9));
    expect((controller.state as GameSessionReady).interaction.selected, isNull);
  });

  test('exposes typed repository failure', () async {
    final controller = MapController(
      repository: FakeMapRepository.failure(
        const MapLoadException(code: 'invalid_map', message: 'Bad map'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();

    final failure = controller.state as GameSessionFailure;
    expect(failure.code, 'invalid_map');
    expect(failure.message, 'Bad map');
  });

  test('a slower old load cannot replace a newer result', () async {
    final repository = _CompletingMapRepository();
    final controller = MapController(repository: repository);
    addTearDown(controller.dispose);

    final firstLoad = controller.load();
    final secondLoad = controller.load();
    repository.requests[1].complete(testMapScene(mapId: 'new-map'));
    await secondLoad;
    repository.requests[0].complete(testMapScene(mapId: 'old-map'));
    await firstLoad;

    final ready = controller.state as GameSessionReady;
    expect(ready.scene.map.mapId, 'new-map');
  });

  test(
    'keeps public errors stable and reports technical diagnostics',
    () async {
      final diagnostics =
          <({String code, Object error, StackTrace stackTrace})>[];
      final cause = FormatException('raw decoder details');
      final controller = MapController(
        repository: FakeMapRepository.failure(
          MapLoadException(
            code: 'invalid_map',
            message: 'The map could not be opened.',
            diagnosticCause: cause,
            diagnosticStackTrace: StackTrace.current,
          ),
        ),
        diagnosticReporter: (code, error, stackTrace) =>
            diagnostics.add((code: code, error: error, stackTrace: stackTrace)),
      );
      addTearDown(controller.dispose);

      await controller.load();

      final failure = controller.state as GameSessionFailure;
      expect(failure.message, 'The map could not be opened.');
      expect(diagnostics.single.code, 'invalid_map');
      expect(diagnostics.single.error, same(cause));
    },
  );

  test(
    'selects a unit, previews a Rust route, and confirms movement',
    () async {
      final unit = testVisibleUnit();
      final scene = testMapScene(units: [unit]);
      final movedPlayer = PlayerMapView(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 1),
        turn: 1,
        units: [
          testVisibleUnit(coordinate: (col: 1, row: 0), movementUnits: 8),
        ],
      );
      final repository = FakeMapRepository.success(
        scene,
        reachableResult: testReachableView(),
        routeResult: testRoutePlanView(),
        moveResult: MoveUnitResultView.accepted(player: movedPlayer),
      );
      final controller = MapController(repository: repository);
      addTearDown(controller.dispose);

      await controller.load();
      controller.select((col: 0, row: 0));
      await pumpEventQueue();

      var ready = controller.state as GameSessionReady;
      expect(ready.interaction.selectedUnitId, unit.id);
      expect(ready.interaction.reachable?.tileAt((col: 1, row: 0)), isNotNull);

      controller.select((col: 1, row: 0));
      await pumpEventQueue();
      ready = controller.state as GameSessionReady;
      expect(ready.interaction.route?.destination, (col: 1, row: 0));

      controller.confirmMove();
      await pumpEventQueue();
      ready = controller.state as GameSessionReady;
      expect(ready.scene.player.stamp.revision, 1);
      expect(ready.scene.player.units.single.coordinate, (col: 1, row: 0));
      expect(ready.interaction.selected, (col: 1, row: 0));
      expect(ready.interaction.selectedUnitId, isNull);
      expect(ready.interaction.route, isNull);
    },
  );

  test(
    'keeps a rejected move typed and leaves the snapshot unchanged',
    () async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      final controller = MapController(
        repository: FakeMapRepository.success(
          scene,
          reachableResult: testReachableView(),
          routeResult: testRoutePlanView(),
          moveResult: const MoveUnitResultView.rejected(
            code: CommandRejectionCodeView.moveTargetOccupied,
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.select((col: 0, row: 0));
      await pumpEventQueue();
      controller.select((col: 1, row: 0));
      await pumpEventQueue();
      controller.confirmMove();
      await pumpEventQueue();

      final ready = controller.state as GameSessionReady;
      expect(ready.scene.player, same(scene.player));
      expect(
        ready.interaction.movementError,
        'Move rejected: move_target_occupied',
      );
      expect(ready.interaction.route, isNotNull);
    },
  );
}

final class _CompletingMapRepository implements MapRepository {
  final requests = <Completer<MapScene>>[];

  @override
  Future<MapScene> load(MapAssetPaths assets) {
    final request = Completer<MapScene>();
    requests.add(request);
    return request.future;
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
  Future<void> close() async {}
}
