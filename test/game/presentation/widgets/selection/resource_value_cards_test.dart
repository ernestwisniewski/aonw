import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_info_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/resources_detail_content.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resource value cards', () {
    final l10n = AppLocalizationsEn();

    test('describe current yield, improvement and future resource hooks', () {
      const tile = TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [ResourceType.wheat],
        height: 0,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'city_1',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      final model = HudSelectionInfoModelFactory.from(
        selection: GameSelection.tile(tile),
        gameState: const GameState(activePlayerId: 'player_1', cities: [city]),
        mapData: _mapData(tile),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: l10n,
      );

      expect(model, isNotNull);
      expect(
        model!.items.singleWhere((item) => item.label == 'Resources').value,
        l10n.resourceWheat,
      );

      expect(model.resourceValueCards, hasLength(1));
      final card = model.resourceValueCards.single;
      expect(card.title, l10n.resourceWheat);
      expect(card.categoryLabel, 'Bonus');
      expect(card.currentSummary, contains('+2 FOOD'));
      expect(card.currentYield.map((item) => item.label), contains('FOOD'));
      expect(card.improvementTitle, l10n.fieldImprovementFarm);
      expect(card.improvementStatus, contains(l10n.technologyAgriculture));
      expect(card.futureLines.join(' '), contains(l10n.technologyAgriculture));
      expect(card.expansionReason, contains('city growth'));
    });

    test('keeps strategic resources visible as expansion targets', () {
      const tile = TileData(
        col: 2,
        row: 0,
        terrains: [TerrainType.hills],
        resources: [ResourceType.iron],
        height: 1,
      );

      final model = HudSelectionInfoModelFactory.from(
        selection: GameSelection.tile(tile),
        gameState: const GameState(activePlayerId: 'player_1'),
        mapData: _mapData(tile),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: l10n,
      );

      final card = model!.resourceValueCards.single;
      expect(card.title, l10n.resourceIron);
      expect(card.categoryLabel, 'Strategic');
      expect(card.currentSummary, contains('+2 PROD'));
      expect(card.futureLines.join(' '), contains(l10n.technologyIronWorking));
      expect(card.expansionReason, contains('strategic resource'));
    });

    testWidgets('render as sectioned cards in resources detail content', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ResourcesDetailContent(
                compact: false,
                model: SelectionResourcesDetail(
                  chipId: SelectionInfoChipId.resources,
                  title: 'Resources',
                  contentKey: 'tile:1:0:resources',
                  resourceLabels: ['Wheat'],
                  resourceItems: [],
                  valueCards: [
                    SelectionResourceValueCard(
                      title: 'Wheat',
                      categoryLabel: 'Bonus',
                      currentSummary: 'Resource gives +2 FOOD',
                      currentYield: [
                        SelectionYieldItem(
                          icon: GameIcons.food,
                          label: 'FOOD',
                          value: 4,
                          color: GameUiTheme.success,
                        ),
                      ],
                      improvementTitle: 'Farm',
                      improvementStatus: 'Requires: Agriculture',
                      improvementStatusKind:
                          SelectionResourceImprovementStatusKind
                              .requiresTechnology,
                      requiredTechnologyName: 'Agriculture',
                      improvementYield: [
                        SelectionYieldItem(
                          icon: GameIcons.food,
                          label: 'FOOD',
                          value: 1,
                          color: GameUiTheme.success,
                        ),
                      ],
                      futureLines: [
                        'After Agriculture: Farm unlocks the full tile yield.',
                      ],
                      expansionReason:
                          'A good expansion target for city growth.',
                      accentColor: GameUiTheme.success,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Wheat'), findsOneWidget);
      expect(find.text('BONUS'), findsOneWidget);
      expect(find.text('VALUE'), findsOneWidget);
      expect(find.text('NOW'), findsNWidgets(2));
      expect(find.text('AFTER IMPROVEMENT'), findsNWidgets(2));
      expect(find.text('REQUIRES'), findsOneWidget);
      expect(find.text('BEST MOVE'), findsOneWidget);
      expect(find.text('LATER'), findsNothing);
      expect(find.text('EXPANSION'), findsNothing);
      expect(find.textContaining('Agriculture'), findsNWidgets(2));
      expect(
        find.text('Unlock Agriculture first, then build Farm.'),
        findsOneWidget,
      );
    });
  });
}

MapData _mapData(TileData tile) {
  return MapData(cols: 4, rows: 4, tiles: [tile]);
}
