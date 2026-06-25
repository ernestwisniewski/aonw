import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerActionPanelViewModel gating', () {
    test('canStartSelection is false when every option is blocked', () {
      const vm = WorkerActionPanelViewModel(
        unitId: 'u1',
        unitName: 'Worker',
        currentHex: CityHex(col: 0, row: 0),
        movementPoints: 1,
        selectionActive: false,
        selectedImprovementType: null,
        activeJob: null,
        options: [
          WorkerImprovementOptionViewModel(
            improvementType: FieldImprovementType.orchard,
            title: 'Orchard',
            yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
            buildTurns: 5,
            state: WorkerImprovementOptionState.blocked,
            reason: 'Requires technology: Sadownictwo',
            canSelect: false,
            score: 0,
          ),
        ],
      );

      expect(vm.canStartSelection, isFalse);
    });

    test('canStartSelection is true when at least one option is buildable', () {
      const vm = WorkerActionPanelViewModel(
        unitId: 'u1',
        unitName: 'Worker',
        currentHex: CityHex(col: 0, row: 0),
        movementPoints: 1,
        selectionActive: false,
        selectedImprovementType: null,
        activeJob: null,
        options: [
          WorkerImprovementOptionViewModel(
            improvementType: FieldImprovementType.farm,
            title: 'Farm',
            yield: TileYield(food: 2, production: 0, gold: 0, defense: 0),
            buildTurns: 4,
            state: WorkerImprovementOptionState.recommended,
            reason: '',
            canSelect: true,
            score: 12,
          ),
          WorkerImprovementOptionViewModel(
            improvementType: FieldImprovementType.orchard,
            title: 'Orchard',
            yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
            buildTurns: 5,
            state: WorkerImprovementOptionState.blocked,
            reason: 'Requires technology: Sadownictwo',
            canSelect: false,
            score: 0,
          ),
        ],
      );

      expect(vm.canStartSelection, isTrue);
    });

    test(
      'buildBlockedReason is the empty-list message when options is empty',
      () {
        const vm = WorkerActionPanelViewModel(
          unitId: 'u1',
          unitName: 'Worker',
          currentHex: CityHex(col: 0, row: 0),
          movementPoints: 1,
          selectionActive: false,
          selectedImprovementType: null,
          activeJob: null,
          options: <WorkerImprovementOptionViewModel>[],
        );

        expect(vm.buildBlockedReason, 'No build is available on this tile.');
      },
    );

    test(
      'buildBlockedReason aggregates blocked option reasons (deduplicated, max 2)',
      () {
        const vm = WorkerActionPanelViewModel(
          unitId: 'u1',
          unitName: 'Worker',
          currentHex: CityHex(col: 0, row: 0),
          movementPoints: 1,
          selectionActive: false,
          selectedImprovementType: null,
          activeJob: null,
          options: [
            WorkerImprovementOptionViewModel(
              improvementType: FieldImprovementType.orchard,
              title: 'Orchard',
              yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
              buildTurns: 5,
              state: WorkerImprovementOptionState.blocked,
              reason: 'Requires technology: Sadownictwo',
              canSelect: false,
              score: 0,
            ),
            WorkerImprovementOptionViewModel(
              improvementType: FieldImprovementType.mine,
              title: 'Mine',
              yield: TileYield(food: 0, production: 2, gold: 0, defense: 0),
              buildTurns: 6,
              state: WorkerImprovementOptionState.blocked,
              reason: 'Requires technology: Mining',
              canSelect: false,
              score: 0,
            ),
            WorkerImprovementOptionViewModel(
              improvementType: FieldImprovementType.vineyard,
              title: 'Vineyard',
              yield: TileYield(food: 0, production: 0, gold: 2, defense: 0),
              buildTurns: 5,
              state: WorkerImprovementOptionState.blocked,
              // Same reason text as another option — should not duplicate.
              reason: 'Requires technology: Sadownictwo',
              canSelect: false,
              score: 0,
            ),
          ],
        );

        // Order is the option list order; duplicates removed; capped at 2 entries.
        expect(
          vm.buildBlockedReason,
          'Requires technology: Sadownictwo • Requires technology: Mining',
        );
      },
    );

    test(
      'buildBlockedReason returns null when at least one option is buildable',
      () {
        const vm = WorkerActionPanelViewModel(
          unitId: 'u1',
          unitName: 'Worker',
          currentHex: CityHex(col: 0, row: 0),
          movementPoints: 1,
          selectionActive: false,
          selectedImprovementType: null,
          activeJob: null,
          options: [
            WorkerImprovementOptionViewModel(
              improvementType: FieldImprovementType.farm,
              title: 'Farm',
              yield: TileYield(food: 2, production: 0, gold: 0, defense: 0),
              buildTurns: 4,
              state: WorkerImprovementOptionState.available,
              reason: '',
              canSelect: true,
              score: 8,
            ),
          ],
        );

        expect(vm.buildBlockedReason, isNull);
      },
    );
  });
}
