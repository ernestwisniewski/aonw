import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/city/city_building_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_details_dialog.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_canvas.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_details_layers.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_dialog.dart';
import 'package:aonw/game/presentation/widgets/unit/unit_details_panel.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders reusable technology panel without dialog barrier', (
    tester,
  ) async {
    var closed = false;

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreePanel(
          maxHeight: 420,
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.agriculture,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
              ),
            ],
          ),
          onResearch: (_) {},
          onClose: () => closed = true,
        ),
      ),
    );
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Recommended research'), findsOneWidget);
    expect(find.textContaining('Show tree'), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('starts on recommended research and selects a recommendation', (
    tester,
  ) async {
    final researched = <TechnologyId>[];

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreePanel(
          maxHeight: 520,
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.agriculture,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
              ),
              TechnologyCardViewModel(
                id: TechnologyId.mining,
                state: TechnologyCardState.locked,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
                treeColumn: 1,
              ),
            ],
          ),
          onResearch: researched.add,
          onClose: () {},
        ),
      ),
    );
    expect(find.text('Recommended research'), findsOneWidget);
    expect(find.text('Agriculture'), findsOneWidget);
    expect(find.text('Show tree (2)'), findsOneWidget);
    expect(find.byKey(const Key('technologyTreeBoard.grid')), findsNothing);

    await tester.tap(find.text('RESEARCH'));
    await tester.pump();

    expect(researched, [TechnologyId.agriculture]);
  });

  testWidgets('keeps technology tree grid on narrow portrait', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _technologyTestApp(
        child: const TechnologyTreePanel(
          maxHeight: 620,
          viewModel: TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.mining,
                state: TechnologyCardState.locked,
                progress: 0,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 4,
                boostActive: false,
                treeColumn: 2,
                treeRow: 1,
              ),
              TechnologyCardViewModel(
                id: TechnologyId.agriculture,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
              ),
            ],
          ),
          onResearch: _noopResearch,
          onClose: _noop,
        ),
      ),
    );
    await _showFullTree(tester);

    final board = find.byKey(const Key('technologyTreeBoard.grid'));

    expect(board, findsOneWidget);
    expect(
      find.descendant(
        of: board,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is TechnologyTreePainter,
        ),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(board).width, 592);
  });

  testWidgets('opens detailed technology description from help button', (
    tester,
  ) async {
    var selectedResearchCount = 0;

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.agriculture,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
                unlocks: [UnlockFieldImprovement(FieldImprovementType.farm)],
                boosts: [
                  TechnologyBoostDefinition(
                    condition: ControlsAnyResource({
                      ResourceType.wheat,
                      ResourceType.rice,
                    }),
                    discount: 0.25,
                    label: 'Wheat or rice',
                  ),
                ],
              ),
              TechnologyCardViewModel(
                id: TechnologyId.mining,
                state: TechnologyCardState.locked,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
                unlocks: [UnlockFieldImprovement(FieldImprovementType.mine)],
                prerequisiteIds: [TechnologyId.agriculture],
                treeRow: 1,
              ),
            ],
          ),
          onResearch: (_) => selectedResearchCount++,
        ),
      ),
    );
    await _showFullTree(tester);

    expect(find.byTooltip('Technology details'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Technology details').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(selectedResearchCount, 0);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(TechnologyDetailsDialog), findsNothing);
    expect(find.byType(TechnologyDetailsPanel), findsOneWidget);
    _expectWarmSurface(tester, const Key('technologyDetailsPanel.surface'));
    expect(find.textContaining('Opens the basic growth path'), findsOneWidget);
    expect(find.text('UNLOCKS'), findsOneWidget);
    expect(find.textContaining('Farm'), findsWidgets);
    expect(find.text('BOOSTS'), findsOneWidget);
    expect(find.textContaining('Control:'), findsOneWidget);
    expect(find.textContaining('rice or wheat'), findsOneWidget);
  });

  testWidgets('portrait opens technology details as standalone modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.agriculture,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 6,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
              ),
            ],
          ),
          onResearch: (_) {},
        ),
      ),
    );
    await _showFullTree(tester);

    await tester.tap(find.byTooltip('Technology details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(TechnologyDetailsDialog), findsOneWidget);
    expect(find.byType(TechnologyInlineTechnologyDetailsLayer), findsNothing);
    expect(find.byType(TechnologyDetailsPanel), findsOneWidget);

    final surface = tester.getRect(
      find.byKey(const Key('technologyDetailsPanel.surface')),
    );
    expect(surface.width, greaterThan(340));
    expect(surface.width, lessThanOrEqualTo(390));
  });

  testWidgets(
    'opens building details from technology unlocks and returns to technology details',
    (tester) async {
      await tester.pumpWidget(
        _technologyTestApp(
          child: TechnologyTreeDialog(
            viewModel: const TechnologyPanelViewModel(
              sciencePerTurn: 2,
              activeTechnology: null,
              technologies: [
                TechnologyCardViewModel(
                  id: TechnologyId.craftsmanship,
                  state: TechnologyCardState.available,
                  progress: 0,
                  baseCost: 7,
                  totalCost: 7,
                  turnsRemaining: 4,
                  boostActive: false,
                  unlocks: [UnlockCityBuilding(CityBuildingUnlockId.workshop)],
                ),
              ],
            ),
            onResearch: (_) {},
          ),
        ),
      );
      await _showFullTree(tester);

      await tester.tap(find.byTooltip('Technology details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('UNLOCKS'), findsOneWidget);
      expect(find.byType(TechnologyDetailsPanel), findsOneWidget);
      expect(find.byType(TechnologyDetailsDialog), findsNothing);
      expect(find.text('Workshop'), findsWidgets);
      final buildingDetailsFinder = find.byTooltip('Building details');
      expect(buildingDetailsFinder, findsOneWidget);

      await tester.ensureVisible(buildingDetailsFinder);
      await tester.pump();
      await tester.tap(buildingDetailsFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(CityBuildingDetailsDialog), findsNothing);
      expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);
      _expectWarmSurface(tester, const Key('cityBuildingDetailsPanel.surface'));
      expect(find.textContaining('basic craft center'), findsOneWidget);
      expect(find.text('COST'), findsWidgets);

      await tester.tap(find.byTooltip('Close').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('basic craft center'), findsNothing);
      expect(find.text('UNLOCKS'), findsOneWidget);
      expect(find.text('Workshop'), findsWidgets);
    },
  );

  testWidgets('opens building details directly from technology tree unlock', (
    tester,
  ) async {
    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.craftsmanship,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 4,
                boostActive: false,
                unlocks: [UnlockCityBuilding(CityBuildingUnlockId.workshop)],
              ),
            ],
          ),
          onResearch: (_) {},
        ),
      ),
    );
    await _showFullTree(tester);

    expect(find.byTooltip('Building details'), findsOneWidget);

    await tester.tap(find.byTooltip('Building details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);
    expect(find.textContaining('basic craft center'), findsOneWidget);
  });

  testWidgets('portrait opens building unlock details as standalone modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.craftsmanship,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 4,
                boostActive: false,
                unlocks: [UnlockCityBuilding(CityBuildingUnlockId.workshop)],
              ),
            ],
          ),
          onResearch: (_) {},
        ),
      ),
    );
    await _showFullTree(tester);

    await tester.tap(find.byTooltip('Building details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(CityBuildingDetailsDialog), findsOneWidget);
    expect(find.byType(TechnologyInlineCityBuildingDetailsLayer), findsNothing);
    expect(find.byType(CityBuildingDetailsPanel), findsOneWidget);

    final surface = tester.getRect(
      find.byKey(const Key('cityBuildingDetailsPanel.surface')),
    );
    expect(surface.width, greaterThan(340));
    expect(surface.width, lessThanOrEqualTo(390));
  });

  testWidgets('opens unit details directly from technology tree unlock', (
    tester,
  ) async {
    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.hunting,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 4,
                boostActive: false,
                unlocks: [UnlockUnitType(GameUnitType.archer)],
              ),
            ],
          ),
          onResearch: (_) {},
        ),
      ),
    );
    await _showFullTree(tester);

    expect(find.byTooltip('Unit details'), findsOneWidget);

    await tester.tap(find.byTooltip('Unit details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(UnitDetailsPanel), findsOneWidget);
    _expectWarmSurface(tester, const Key('unitDetailsPanel.surface'));
    expect(find.textContaining('ranged unit'), findsOneWidget);
  });

  testWidgets('portrait opens unit unlock details as standalone modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.hunting,
                state: TechnologyCardState.available,
                progress: 0,
                baseCost: 7,
                totalCost: 7,
                turnsRemaining: 4,
                boostActive: false,
                unlocks: [UnlockUnitType(GameUnitType.archer)],
              ),
            ],
          ),
          onResearch: (_) {},
        ),
      ),
    );
    await _showFullTree(tester);

    await tester.tap(find.byTooltip('Unit details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(TechnologyInlineUnitDetailsLayer), findsNothing);
    expect(find.byType(UnitDetailsPanel), findsOneWidget);

    final surface = tester.getRect(
      find.byKey(const Key('unitDetailsPanel.surface')),
    );
    expect(surface.width, greaterThan(340));
    expect(surface.width, lessThanOrEqualTo(390));
  });

  testWidgets(
    'opens unit details from technology unlocks and returns to technology details',
    (tester) async {
      await tester.pumpWidget(
        _technologyTestApp(
          child: TechnologyTreeDialog(
            viewModel: const TechnologyPanelViewModel(
              sciencePerTurn: 2,
              activeTechnology: null,
              technologies: [
                TechnologyCardViewModel(
                  id: TechnologyId.hunting,
                  state: TechnologyCardState.available,
                  progress: 0,
                  baseCost: 7,
                  totalCost: 7,
                  turnsRemaining: 4,
                  boostActive: false,
                  unlocks: [UnlockUnitType(GameUnitType.archer)],
                ),
              ],
            ),
            onResearch: (_) {},
          ),
        ),
      );
      await _showFullTree(tester);

      await tester.tap(find.byTooltip('Technology details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('UNLOCKS'), findsOneWidget);
      expect(find.byType(TechnologyDetailsPanel), findsOneWidget);
      expect(find.text('Archer'), findsWidgets);
      final unitDetailsFinder = find.byTooltip('Unit details');
      expect(unitDetailsFinder, findsOneWidget);

      await tester.ensureVisible(unitDetailsFinder);
      await tester.pump();
      await tester.tap(unitDetailsFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(UnitDetailsPanel), findsOneWidget);
      expect(find.textContaining('ranged unit'), findsOneWidget);
      expect(find.text('COMBAT'), findsOneWidget);

      await tester.tap(find.byTooltip('Close').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(UnitDetailsPanel), findsNothing);
      expect(find.text('UNLOCKS'), findsOneWidget);
      expect(find.text('Archer'), findsWidgets);
    },
  );

  testWidgets('selects prerequisite path only for locked technologies', (
    tester,
  ) async {
    final researched = <TechnologyId>[];

    await tester.pumpWidget(
      _technologyTestApp(
        child: TechnologyTreeDialog(
          viewModel: const TechnologyPanelViewModel(
            sciencePerTurn: 2,
            activeTechnology: null,
            technologies: [
              TechnologyCardViewModel(
                id: TechnologyId.agriculture,
                state: TechnologyCardState.available,
                progress: 0,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
              ),
              TechnologyCardViewModel(
                id: TechnologyId.mining,
                state: TechnologyCardState.locked,
                progress: 0,
                totalCost: 6,
                turnsRemaining: 3,
                boostActive: false,
                prerequisiteIds: [TechnologyId.agriculture],
                treeColumn: 1,
              ),
            ],
          ),
          onResearch: researched.add,
        ),
      ),
    );
    await _showFullTree(tester);

    await tester.tap(find.text('Agriculture'));
    await tester.pump();

    expect(researched, [TechnologyId.agriculture]);
    expect(_selectedPathTarget(tester), isNull);

    await tester.tap(find.text('Mining'));
    await tester.pump();

    expect(researched, [TechnologyId.agriculture]);
    expect(_selectedPathTarget(tester), TechnologyId.mining);
    expect(
      _selectedPathEdges(tester),
      contains((parent: TechnologyId.agriculture, child: TechnologyId.mining)),
    );
  });

  testWidgets('remembers selected view mode between panel instances', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _technologyTestApp(
        container: container,
        child: const TechnologyTreePanel(
          maxHeight: 520,
          viewModel: _viewModeMemoryModel,
          onResearch: _noopResearch,
          onClose: _noop,
        ),
      ),
    );

    expect(find.text('Recommended research'), findsOneWidget);
    expect(find.textContaining('Show tree'), findsOneWidget);

    await _showFullTree(tester);

    expect(find.byKey(const Key('technologyTreeBoard.grid')), findsOneWidget);
    expect(
      container.read(technologyTreeViewModeProvider),
      TechnologyTreeViewMode.tree,
    );

    await tester.pumpWidget(
      _technologyTestApp(
        container: container,
        child: const TechnologyTreePanel(
          maxHeight: 520,
          viewModel: _viewModeMemoryModel,
          onResearch: _noopResearch,
          onClose: _noop,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('technologyTreeBoard.grid')), findsOneWidget);
    expect(find.textContaining('Show tree'), findsNothing);

    await tester.tap(find.text('Recommendations'));
    await tester.pump();

    expect(
      container.read(technologyTreeViewModeProvider),
      TechnologyTreeViewMode.recommendations,
    );

    await tester.pumpWidget(
      _technologyTestApp(
        container: container,
        child: const TechnologyTreePanel(
          maxHeight: 520,
          viewModel: _viewModeMemoryModel,
          onResearch: _noopResearch,
          onClose: _noop,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Recommended research'), findsOneWidget);
    expect(find.textContaining('Show tree'), findsOneWidget);
  });

  test('routes skipped-column connectors through the row gap', () {
    const parentRect = Rect.fromLTWH(16, 16, 194, 164);
    const childRect = Rect.fromLTWH(508, 16, 194, 164);
    final points = technologyTreeConnectorPointsForTesting(
      parent: _card(TechnologyId.agriculture, treeColumn: 0, treeRow: 0),
      child: _card(TechnologyId.storage, treeColumn: 2, treeRow: 0),
      parentRect: parentRect,
      childRect: childRect,
      size: const Size(718, 400),
    );

    expect(points, hasLength(6));
    expect(
      points.any((point) => point.dy > parentRect.bottom),
      isTrue,
      reason:
          'Storage is directly available after Agriculture, so the connector '
          'must visibly bypass Animal Husbandry instead of running through it.',
    );
  });

  test('keeps adjacent-column connectors direct', () {
    const parentRect = Rect.fromLTWH(16, 16, 194, 164);
    const childRect = Rect.fromLTWH(262, 16, 194, 164);
    final points = technologyTreeConnectorPointsForTesting(
      parent: _card(TechnologyId.agriculture, treeColumn: 0, treeRow: 0),
      child: _card(TechnologyId.animalHusbandry, treeColumn: 1, treeRow: 0),
      parentRect: parentRect,
      childRect: childRect,
      size: const Size(472, 400),
    );

    expect(points, hasLength(4));
    expect(points.every((point) => point.dy == parentRect.center.dy), isTrue);
  });
}

const _viewModeMemoryModel = TechnologyPanelViewModel(
  sciencePerTurn: 2,
  activeTechnology: null,
  technologies: [
    TechnologyCardViewModel(
      id: TechnologyId.agriculture,
      state: TechnologyCardState.available,
      progress: 0,
      baseCost: 6,
      totalCost: 6,
      turnsRemaining: 3,
      boostActive: false,
    ),
    TechnologyCardViewModel(
      id: TechnologyId.mining,
      state: TechnologyCardState.locked,
      progress: 0,
      baseCost: 7,
      totalCost: 7,
      turnsRemaining: 4,
      boostActive: false,
      treeColumn: 1,
    ),
  ],
);

Widget _technologyTestApp({
  required Widget child,
  ProviderContainer? container,
}) {
  final app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(child: app);
}

void _noop() {}

void _noopResearch(TechnologyId technologyId) {}

Future<void> _showFullTree(WidgetTester tester) async {
  await tester.tap(find.textContaining('Show tree'));
  await tester.pump();
}

void _expectWarmSurface(WidgetTester tester, Key key) {
  final surface = tester.widget<DecoratedBox>(find.byKey(key));
  final decoration = surface.decoration as BoxDecoration;
  expect(decoration.gradient, isA<LinearGradient>());
  expect(decoration.color, isNull);
}

TechnologyCardViewModel _card(
  TechnologyId id, {
  required int treeColumn,
  required int treeRow,
}) {
  return TechnologyCardViewModel(
    id: id,
    state: TechnologyCardState.locked,
    progress: 0,
    totalCost: 6,
    turnsRemaining: 3,
    boostActive: false,
    treeColumn: treeColumn,
    treeRow: treeRow,
  );
}

TechnologyId? _selectedPathTarget(WidgetTester tester) {
  for (final paint in tester.widgetList<CustomPaint>(
    find.byType(CustomPaint),
  )) {
    final target = technologyTreeSelectedPathTargetForTesting(paint.painter);
    if (target != null) return target;
  }
  return null;
}

Set<({TechnologyId parent, TechnologyId child})> _selectedPathEdges(
  WidgetTester tester,
) {
  for (final paint in tester.widgetList<CustomPaint>(
    find.byType(CustomPaint),
  )) {
    final edges = technologyTreeSelectedPathEdgesForTesting(paint.painter);
    if (edges.isNotEmpty) return edges;
  }
  return const {};
}
