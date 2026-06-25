import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_selection_detail_sync.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudSelectionDetailSync', () {
    test(
      'closes an open detail when the current selection does not support it',
      () {
        final sync = HudSelectionDetailSync.fromSelection(
          selection: const SelectionViewModel.empty(),
          openChipId: SelectionInfoChipId.resources,
        );

        expect(sync.closeUnsupportedDetail, isTrue);
      },
    );

    test('closes legacy worker detail when it is no longer supported', () {
      final sync = HudSelectionDetailSync.fromSelection(
        selection: _workerSelection(),
        openChipId: 'worker',
      );

      expect(sync.closeUnsupportedDetail, isTrue);
    });
  });
}

SelectionViewModel _workerSelection() {
  return SelectionViewModel(
    icon: GameIcons.production,
    color: Colors.white,
    title: 'Worker',
    subtitle: 'Ready',
    items: const [],
    workerAction: _workerAction(),
    selectionKey: 'unit:worker_1',
  );
}

WorkerActionPanelViewModel _workerAction() {
  return const WorkerActionPanelViewModel(
    unitId: 'worker_1',
    unitName: 'Worker',
    currentHex: CityHex(col: 1, row: 1),
    movementPoints: 2,
    selectionActive: false,
    selectedImprovementType: null,
    activeJob: null,
    options: [],
  );
}
