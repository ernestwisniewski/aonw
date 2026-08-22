import 'dart:async';

import 'package:aonw_flutter/features/map/application/map_controller.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('loads ready state and keeps interaction local', () async {
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene()),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state, isA<MapReadyState>());

    controller.hover((col: 1, row: 1));
    controller.select((col: 2, row: 1));
    controller.toggleReference();

    final ready = controller.state as MapReadyState;
    expect(ready.interaction.hovered, (col: 1, row: 1));
    expect(ready.interaction.selected, (col: 2, row: 1));
    expect(ready.interaction.referenceVisible, isFalse);

    controller.select((col: 9, row: 9));
    expect((controller.state as MapReadyState).interaction.selected, isNull);
  });

  test('exposes typed repository failure', () async {
    final controller = MapController(
      repository: FakeMapRepository.failure(
        const MapLoadException(code: 'invalid_map', message: 'Bad map'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();

    final failure = controller.state as MapFailureState;
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

    final ready = controller.state as MapReadyState;
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

      final failure = controller.state as MapFailureState;
      expect(failure.message, 'The map could not be opened.');
      expect(diagnostics.single.code, 'invalid_map');
      expect(diagnostics.single.error, same(cause));
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
}
