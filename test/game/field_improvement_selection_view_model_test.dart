import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldImprovementSelectionViewModelFactory', () {
    final l10n = AppLocalizationsEn();

    test('builds a focused model for a built field improvement', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'Capital',
        center: CityHex(col: 2, row: 2),
        controlledHexes: [CityHex(col: 3, row: 3)],
      );
      final improvement = FieldImprovement(
        hex: const CityHex(col: 3, row: 3),
        type: FieldImprovementType.farm,
        builtByCityId: city.id,
      );
      const tile = TileData(
        col: 3,
        row: 3,
        height: 0,
        terrains: [TerrainType.grassland],
        resources: [],
      );
      final selection = GameSelection.fieldImprovement(improvement, tile: tile);
      final state = GameState(
        activePlayerId: 'p1',
        cities: [city],
        fieldImprovements: [improvement],
      );

      final vm = SelectionViewModelFactory.from(
        selection,
        gameState: state,
        l10n: l10n,
        improvementName: (type) => 'Farm',
        cityName: (city) => city.name,
      );

      expect(vm.selectionKey, 'improvement:3:3');
      expect(vm.title, 'Farm');
      expect(vm.subtitle, 'Capital • +1 FOOD');
      expect(vm.assetIcon?.fieldImprovementType, FieldImprovementType.farm);
      expect(vm.preferImprovementsTab, isTrue);
      expect(vm.yields.map((item) => item.value), [1]);
      expect(vm.improvements, hasLength(1));
      expect(vm.improvements.single.state, SelectionImprovementState.built);
      expect(vm.improvements.single.cityRequirement, 'Works for: Capital');
      expect(vm.items, isEmpty);
    });

    test(
      'keeps the description popup focused on sprite and positive yield',
      () {
        const vm = SelectionViewModel(
          icon: GameIcons.improvement,
          color: GameUiTheme.success,
          title: 'Farm',
          subtitle: 'Works for: Capital • +1 FOOD',
          assetIcon: SelectionAssetIconViewModel.fieldImprovement(
            fieldImprovementType: FieldImprovementType.farm,
          ),
          selectionKey: 'improvement:3:3',
          items: [
            SelectionInfoItem(
              icon: GameIcons.terrain,
              label: 'Terrain',
              value: 'grassland',
              color: GameUiTheme.success,
            ),
          ],
          yields: [
            SelectionYieldItem(
              icon: GameIcons.food,
              label: 'FOOD',
              value: 1,
              color: GameUiTheme.success,
            ),
            SelectionYieldItem(
              icon: GameIcons.production,
              label: 'PROD',
              value: 0,
              color: GameUiTheme.resourcesAccent,
            ),
          ],
        );

        final detail = SelectionDetailViewModelFactory.detailFor(
          SelectionInfoChipId.description,
          vm,
          l10n,
        );

        expect(detail, isA<SelectionDescriptionDetail>());
        final description = detail! as SelectionDescriptionDetail;
        expect(description.title, 'Farm');
        expect(description.heading, isEmpty);
        expect(description.subtitle, isEmpty);
        expect(description.items, isEmpty);
        expect(description.tags, isEmpty);
        expect(description.yields.map((item) => item.value), [1]);
        expect(
          description.assetIcon?.fieldImprovementType,
          FieldImprovementType.farm,
        );
      },
    );

    test('exposes the improvements detail chip for selected improvement', () {
      const vm = SelectionViewModel(
        icon: GameIcons.improvement,
        color: GameUiTheme.success,
        title: 'Farm',
        subtitle: 'Works for: Capital',
        selectionKey: 'improvement:3:3',
        preferImprovementsTab: true,
        items: [],
        improvements: [
          SelectionImprovementItem(
            type: FieldImprovementType.farm,
            title: 'Farm',
            yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
            buildTurns: 2,
            state: SelectionImprovementState.built,
            technologyRequirement: '',
            buildingRequirement: '',
            cityRequirement: 'Works for: Capital',
          ),
        ],
      );

      final chips = SelectionInfoChipsFactory.chipsFor(vm, l10n: l10n);
      expect(chips.map((chip) => chip.id), [
        SelectionInfoChipId.description,
        SelectionInfoChipId.improvements,
      ]);

      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.improvements,
        vm,
        l10n,
      );
      expect(detail, isA<SelectionImprovementsDetail>());
      expect(
        (detail! as SelectionImprovementsDetail).improvements.single.state,
        SelectionImprovementState.built,
      );
    });
  });
}
