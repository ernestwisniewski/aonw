import 'package:aonw_flutter/app/composition/app_composition.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
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
    expect(first.closeCalls, 1);
    expect(firstInput.closeCalls, 1);
    expect(second.loadCalls, 1);

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
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await tester.pumpWidget(
      AppComposition(mapRepository: repository, mapInputSource: input).root,
    );
    await tester.pump();
    expect(input.activeStates, [true]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(input.activeStates.last, isFalse);
    expect(repository.closeCalls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(input.activeStates.last, isTrue);
    expect(repository.closeCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(input.activeStates.last, isFalse);
    expect(repository.closeCalls, 1);
  });
}

final class _LifecycleMapInputSource
    implements MapInputSource, LifecycleAwareMapInputSource {
  var closeCalls = 0;
  final activeStates = <bool>[];

  @override
  Stream<MapInputCommand> get commands => const Stream.empty();

  @override
  Future<void> close() async {
    closeCalls += 1;
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
