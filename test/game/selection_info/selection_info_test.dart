import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_sprite_catalog.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/description_detail_content.dart';
import 'package:aonw/game/presentation/widgets/theme/city_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/field_improvement_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('SelectionInfoChipsFactory', () {
    test('returns no chips for empty selection model', () {
      expect(
        SelectionInfoChipsFactory.chipsFor(
          const SelectionViewModel.empty(),
          l10n: l10n,
        ),
        isEmpty,
      );
    });

    test('builds base chips for terrain-only tile', () {
      final chips = SelectionInfoChipsFactory.chipsFor(
        _tileModel(),
        l10n: l10n,
      );

      expect(chips.map((chip) => chip.id), [
        SelectionInfoChipId.description,
        SelectionInfoChipId.terrain,
        SelectionInfoChipId.improvements,
      ]);
      expect(
        chips
            .singleWhere((chip) => chip.id == SelectionInfoChipId.terrain)
            .badge,
        '+1',
      );
      expect(
        chips
            .singleWhere((chip) => chip.id == SelectionInfoChipId.improvements)
            .badge,
        isNull,
      );
    });

    test('adds resource and improvement chips with badges', () {
      final chips = SelectionInfoChipsFactory.chipsFor(
        _tileModel(resources: 'Fish + Iron', improvements: [_improvement()]),
        l10n: l10n,
      );

      expect(chips.map((chip) => chip.id), [
        SelectionInfoChipId.description,
        SelectionInfoChipId.terrain,
        SelectionInfoChipId.resources,
        SelectionInfoChipId.improvements,
      ]);
      expect(
        chips
            .singleWhere((chip) => chip.id == SelectionInfoChipId.resources)
            .badge,
        '2',
      );
      expect(
        chips
            .singleWhere((chip) => chip.id == SelectionInfoChipId.improvements)
            .badge,
        '1',
      );
    });

    test('keeps city detail entry points out of info chips', () {
      final chips = SelectionInfoChipsFactory.chipsFor(
        _cityModel(),
        l10n: l10n,
      );

      expect(
        chips.map((chip) => chip.id),
        isNot(contains(SelectionInfoChipId.description)),
      );
      expect(
        chips.map((chip) => chip.id),
        isNot(contains(SelectionInfoChipId.buildings)),
      );
    });

    test('builds unit chips for movement-only unit', () {
      final chips = SelectionInfoChipsFactory.chipsFor(
        _unitModel(),
        l10n: l10n,
      );

      expect(chips.map((chip) => chip.id), [
        SelectionInfoChipId.description,
        SelectionInfoChipId.terrain,
      ]);
      expect(
        chips
            .singleWhere((chip) => chip.id == SelectionInfoChipId.terrain)
            .badge,
        '+1',
      );
    });

    test('does not add duplicate unit info chip', () {
      final chips = SelectionInfoChipsFactory.chipsFor(
        _unitModel(),
        l10n: l10n,
      );

      expect(chips.map((chip) => chip.label), isNot(contains('Unit')));
    });
  });

  group('SelectionDetailViewModelFactory', () {
    test('returns terrain detail for terrain chip', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.terrain,
        _tileModel(),
        l10n,
      );

      expect(detail, isA<SelectionTerrainDetail>());
      expect((detail! as SelectionTerrainDetail).terrainLabels, [
        'Grassland',
        'River',
      ]);
    });

    test('returns empty improvements detail for tile without improvements', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.improvements,
        _tileModel(),
        l10n,
      );

      expect(detail, isA<SelectionImprovementsDetail>());
      expect((detail! as SelectionImprovementsDetail).improvements, isEmpty);
    });

    test('returns empty buildings detail for city without buildings', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.buildings,
        _cityModel(),
        l10n,
      );

      expect(detail, isA<SelectionBuildingsDetail>());
      expect((detail! as SelectionBuildingsDetail).buildings, isEmpty);
    });

    test('uses city name and city sprite in city description detail', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.description,
        _cityModel(
          assetIcon: const SelectionAssetIconViewModel.city(
            cityVisualLevel: 2,
            cityTechnologyProfileIndex: 3,
          ),
        ),
        l10n,
      );

      expect(detail, isA<SelectionDescriptionDetail>());
      final description = detail! as SelectionDescriptionDetail;
      expect(description.title, 'City');
      expect(description.heading, isEmpty);
      expect(description.subtitle, isEmpty);
      expect(description.assetIcon?.isCity, isTrue);
      expect(description.assetIcon?.cityVisualLevel, 2);
      expect(description.assetIcon?.cityTechnologyProfileIndex, 3);
    });

    test('uses city description items for controlled objectives', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.description,
        _cityModel(
          descriptionItems: const [
            SelectionInfoItem(
              icon: GameIcons.victory,
              label: 'Strategic pass',
              value: 'Holding 0/3 • +2 VP',
              color: GameUiTheme.gold,
            ),
          ],
        ),
        l10n,
      );

      expect(detail, isA<SelectionDescriptionDetail>());
      final description = detail! as SelectionDescriptionDetail;
      expect(description.items, hasLength(1));
      expect(description.items.single.label, 'Strategic pass');
    });

    test('returns empty terrain detail for unit without terrain data', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.terrain,
        _unitModel(terrain: null),
        l10n,
      );

      expect(detail, isA<SelectionTerrainDetail>());
      expect((detail! as SelectionTerrainDetail).terrainLabels, isEmpty);
    });

    test('returns army detail for commander army action', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        SelectionInfoChipId.army,
        _unitModel(
          supportsArmyDetail: true,
          armyTroops: const [ArmyTroop(type: TroopType.warrior, count: 12)],
        ),
        l10n,
      );

      expect(detail, isA<SelectionArmyDetail>());
      expect((detail! as SelectionArmyDetail).troops, hasLength(1));
    });

    test('does not expose legacy worker detail popup', () {
      final detail = SelectionDetailViewModelFactory.detailFor(
        'worker',
        _unitModel(workerAction: _workerAction()),
        l10n,
      );

      expect(detail, isNull);
    });
  });

  group('DescriptionDetailContent', () {
    testWidgets('caps improvement sprite preview at 250 px wide', (
      tester,
    ) async {
      await tester.pumpWidget(
        _descriptionHarness(
          width: 320,
          detail: const SelectionDescriptionDetail(
            chipId: SelectionInfoChipId.description,
            contentKey: 'improvement:3:3:description',
            title: 'Farm',
            heading: '',
            subtitle: '',
            items: [],
            yields: [
              SelectionYieldItem(
                icon: GameIcons.food,
                label: 'FOOD',
                value: 1,
                color: GameUiTheme.success,
              ),
            ],
            tags: [],
            assetIcon: SelectionAssetIconViewModel.fieldImprovement(
              fieldImprovementType: FieldImprovementType.farm,
            ),
          ),
        ),
      );

      final icon = tester.widget<FieldImprovementSpriteIcon>(
        find.byKey(const Key('selectionDescription.improvementSprite')),
      );
      expect(icon.width, 250);
      expect(icon.height, closeTo(250 / (500 / 370), 0.01));
    });

    testWidgets(
      'caps city sprite preview at 250 px wide at the bottom of city description',
      (tester) async {
        await tester.pumpWidget(
          _descriptionHarness(
            width: 360,
            detail: const SelectionDescriptionDetail(
              chipId: SelectionInfoChipId.description,
              contentKey: 'city:city_1:description',
              title: 'Capital',
              heading: '',
              subtitle: '',
              items: [],
              yields: [],
              tags: [],
              assetIcon: SelectionAssetIconViewModel.city(
                cityVisualLevel: 2,
                cityTechnologyProfileIndex: 3,
              ),
            ),
          ),
        );

        final icon = tester.widget<CitySpriteIcon>(
          find.byKey(const Key('selectionDescription.citySprite')),
        );
        expect(icon.width, 250);
        expect(icon.height, closeTo(250 / (500 / 370), 0.01));
        expect(icon.visualLevel, 2);
        expect(icon.technologyProfileIndex, 3);
      },
    );

    testWidgets('renders city objective descriptions above yield breakdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _descriptionHarness(
          width: 420,
          detail: SelectionDescriptionDetail(
            chipId: SelectionInfoChipId.description,
            contentKey: 'city:city_1:description',
            title: 'City',
            heading: '',
            subtitle: '',
            items: const [
              SelectionInfoItem(
                icon: GameIcons.victory,
                label: 'Strategic pass',
                value: 'Holding 0/3 • +2 VP',
                color: GameUiTheme.gold,
              ),
            ],
            yields: const [],
            tags: const [],
            cityYieldBreakdown: _cityYieldBreakdown(),
          ),
        ),
      );

      expect(find.text('Strategic pass'), findsOneWidget);
      expect(find.text('Holding 0/3 • +2 VP'), findsOneWidget);
      expect(find.byKey(const Key('cityYieldBreakdown.title')), findsOneWidget);
    });

    test('uses regular city atlas cells without asset adjustments', () {
      final data = CitySpriteIconCatalog.iconFor(
        visualLevel: 2,
        technologyProfileIndex: 3,
      );

      expect(data.cropToContent, isFalse);
      expect(data.sourceRectResolver, isNull);
      expect(data.assetPath, CitySpriteCatalog.assetPath);
      expect(data.column, 2);
      expect(data.row, 3);
      expect(data.adjustmentId, isNull);
    });
  });
}

Widget _descriptionHarness({
  required double width,
  required SelectionDescriptionDetail detail,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: DescriptionDetailContent(model: detail, compact: false),
        ),
      ),
    ),
  );
}

SelectionViewModel _tileModel({
  String? resources,
  List<SelectionImprovementItem> improvements = const [],
  List<SelectionYieldItem> yields = const [],
  String? yieldTitle,
  String? yieldTooltip,
}) {
  return SelectionViewModel(
    icon: GameIcons.terrain,
    color: GameUiTheme.gold,
    title: 'Dobre pole',
    subtitle: 'Dobra lokacja',
    selectionKey: 'tile:1:2',
    yields: yields,
    yieldTitle: yieldTitle,
    yieldTooltip: yieldTooltip,
    improvements: improvements,
    items: [
      const SelectionInfoItem(
        icon: GameIcons.terrain,
        label: 'Terrain',
        value: 'Grassland + River',
        color: GameUiTheme.gold,
        semanticId: SelectionInfoItemSemanticId.terrain,
      ),
      if (resources != null)
        SelectionInfoItem(
          icon: GameIcons.resources,
          label: 'Resources',
          value: resources,
          color: GameUiTheme.gold,
          semanticId: SelectionInfoItemSemanticId.resources,
        ),
    ],
  );
}

SelectionViewModel _cityModel({
  List<String> buildings = const [],
  List<SelectionCityBuildingItem> buildingItems = const [],
  CityYieldBreakdownViewModel? cityYieldBreakdown,
  List<SelectionInfoItem> descriptionItems = const [],
  SelectionAssetIconViewModel? assetIcon,
}) {
  return SelectionViewModel(
    icon: GameIcons.cityFilled,
    color: GameUiTheme.gold,
    title: 'City',
    subtitle: 'Population 2 • 3/5 tiles',
    assetIcon: assetIcon,
    selectionKey: 'city:city_1',
    yields: const [
      SelectionYieldItem(
        icon: GameIcons.food,
        label: 'FOOD',
        value: 4,
        color: Color(0xFF87c96a),
      ),
      SelectionYieldItem(
        icon: GameIcons.production,
        label: 'PROD',
        value: 2,
        color: Color(0xFFc9a95f),
      ),
    ],
    cityBuildings: buildings,
    cityBuildingItems: buildingItems,
    cityYieldBreakdown: cityYieldBreakdown,
    descriptionItems: descriptionItems,
    items: [
      const SelectionInfoItem(
        icon: GameIcons.population,
        label: 'Population',
        value: '2',
        color: GameUiTheme.gold,
      ),
      const SelectionInfoItem(
        icon: GameIcons.workedHexes,
        label: 'Territory',
        value: '3/5',
        color: GameUiTheme.accent,
      ),
      SelectionInfoItem(
        icon: GameIcons.city,
        label: 'Buildings',
        value: '${buildings.length}',
        color: const Color(0xFF8da8e8),
      ),
    ],
  );
}

CityYieldBreakdownViewModel _cityYieldBreakdown() {
  return const CityYieldBreakdownViewModel(
    totalYield: TileYield(food: 2, production: 1, gold: 0, defense: 1),
    rows: [
      CityYieldBreakdownRow(
        label: 'Center',
        detail: 'Pole miasta',
        yield: TileYield(food: 2, production: 1, gold: 0, defense: 1),
      ),
    ],
    growthLabel: 'Growth',
    growthEta: TurnEta.blocked(),
  );
}

SelectionViewModel _unitModel({
  String id = 'unit_1',
  String title = 'WARRIOR',
  GameIconData icon = GameIcons.defense,
  String? terrain = 'Grassland + River',
  List<SelectionInfoItem> extraItems = const [],
  bool supportsArmyDetail = false,
  List<ArmyTroop> armyTroops = const [],
  WorkerActionPanelViewModel? workerAction,
}) {
  return SelectionViewModel(
    icon: icon,
    color: const Color(0xFFd48f74),
    title: title,
    subtitle: 'Ruch 2/2',
    selectionKey: 'unit:$id',
    supportsArmyDetail: supportsArmyDetail,
    armyTroops: armyTroops,
    workerAction: workerAction,
    items: [
      const SelectionInfoItem(
        icon: GameIcons.move,
        label: 'Ruch',
        value: '2/2',
        color: Color(0xFFe0c56d),
        showLabel: false,
      ),
      ...extraItems,
      if (terrain != null)
        SelectionInfoItem(
          icon: GameIcons.terrain,
          label: 'Terrain',
          value: terrain,
          color: const Color(0xFF89b66f),
          showLabel: false,
          semanticId: SelectionInfoItemSemanticId.terrain,
        ),
    ],
  );
}

WorkerActionPanelViewModel _workerAction() {
  return const WorkerActionPanelViewModel(
    unitId: 'worker_1',
    unitName: 'Worker',
    currentHex: CityHex(col: 1, row: 0),
    movementPoints: 2,
    selectionActive: false,
    selectedImprovementType: null,
    activeJob: null,
    options: [
      WorkerImprovementOptionViewModel(
        improvementType: FieldImprovementType.farm,
        title: 'Farm',
        yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
        buildTurns: 2,
        state: WorkerImprovementOptionState.available,
        reason: '+1 food',
        canSelect: false,
        score: 1000,
      ),
    ],
  );
}

SelectionImprovementItem _improvement() {
  return const SelectionImprovementItem(
    type: FieldImprovementType.farm,
    title: 'Farm',
    yield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
    buildTurns: 2,
    state: SelectionImprovementState.available,
    technologyRequirement: 'Requires: Agriculture',
    buildingRequirement: '',
    cityRequirement: 'Works for: Capital',
  );
}
