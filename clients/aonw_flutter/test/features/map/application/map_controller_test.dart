import 'package:aonw_flutter/features/map/application/map_controller.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
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
}
