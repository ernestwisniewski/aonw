import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_detail_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_detail_view_model_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_chip_id.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model_factory.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitSelectionViewModelFactory', () {
    test('exposes movement and hp for combat units', () {
      final l10n = AppLocalizationsEn();
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        hitPoints: 4,
      );

      final vm = SelectionViewModelFactory.from(
        GameSelection.unit(unit),
        l10n: l10n,
      );

      expect(vm.subtitle, 'Move 3/3 • HP 4/10');
      expect(vm.description, contains('basic combat unit'));
      expect(vm.descriptionItems.map((item) => item.label), [
        'Attack',
        'Defense',
      ]);
      expect(_itemValue(vm, 'Attack'), '4');
      expect(_itemValue(vm, 'Defense'), '3');
      expect(_itemValue(vm, 'HP'), '4/10');
      expect(_itemValue(vm, 'Range'), '1');

      final detail =
          SelectionDetailViewModelFactory.detailFor(
                SelectionInfoChipId.description,
                vm,
                l10n,
              )
              as SelectionDescriptionDetail;
      expect(detail.body, vm.description);
      expect(detail.items.map((item) => item.label), ['Attack', 'Defense']);
    });

    test('keeps non-combat unit subtitle focused on movement', () {
      final l10n = AppLocalizationsEn();
      final unit = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 0,
      );

      final vm = SelectionViewModelFactory.from(
        GameSelection.unit(unit),
        l10n: l10n,
      );

      expect(vm.subtitle, startsWith('Move '));
      expect(vm.subtitle, isNot(contains('HP')));
      expect(vm.description, contains('Improves tiles'));
      expect(vm.descriptionItems, isEmpty);

      final detail =
          SelectionDetailViewModelFactory.detailFor(
                SelectionInfoChipId.description,
                vm,
                l10n,
              )
              as SelectionDescriptionDetail;
      expect(detail.body, vm.description);
      expect(detail.items, isEmpty);
    });
  });
}

String _itemValue(SelectionViewModel vm, String label) {
  return vm.items.singleWhere((item) => item.label == label).value;
}
