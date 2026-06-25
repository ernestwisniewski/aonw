import 'dart:ui' as ui;
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview_layer.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

UnitMovementPlan _plan({
  int targetCol = 1,
  int targetRow = 0,
  int totalCost = 1,
  int availableMovementPoints = 5,
  List<UnitMovementStep>? steps,
}) => UnitMovementPlan(
  unitId: 'commander_player_1',
  targetCol: targetCol,
  targetRow: targetRow,
  totalCost: totalCost,
  availableMovementPoints: availableMovementPoints,
  steps:
      steps ??
      [
        const UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(
          col: targetCol,
          row: targetRow,
          enterCost: 1,
          cumulativeCost: 1,
        ),
      ],
);

String _turnCountLabel(int turns) => AppLocalizationsEn().turnCountLabel(turns);

String get _confirmLabel => AppLocalizationsEn().selectionActionConfirm;

String _confirmWithTurns(int turns) => AppLocalizationsEn()
    .selectionActionConfirmWithTurns(_turnCountLabel(turns));

List<UnitMovePreview> _previewsIn(Component parent) {
  return parent.children.query<UnitMovePreview>().toList(growable: false);
}

UnitMovePreview _singlePreviewIn(Component parent) =>
    _previewsIn(parent).single;

List<MapPillComponent> _pillsIn(Component parent) {
  return parent.children.query<MapPillComponent>().toList(growable: false);
}

MapPillComponent _singlePillIn(Component parent) => _pillsIn(parent).single;

void main() {
  group('UnitMovePreviewLayer', () {
    test('sync adds a preview component with projected path points', () {
      final parent = Component();
      UnitMovePreviewLayer().sync(parent: parent, preview: _plan());

      final preview = _singlePreviewIn(parent);
      final expectedStart = HexGeometry.tilePosition(
        col: 0,
        row: 0,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      expect(parent.children.query<UnitMovePreviewLayer>(), hasLength(1));
      expect(preview.totalCost, 1);
      expect(preview.availableMovementPoints, 5);
      expect(preview.canMoveNow, isTrue);
      expect(preview.reachableColor, HudPalette.gold);
      expect(preview.priority, UnitMovePreviewLayer.routePriority);
      expect(
        preview.priority,
        greaterThan(MapPriority.perTile(MapPriority.sprite, col: 99, row: 99)),
      );
      expect(preview.points, hasLength(2));
      expect(preview.cumulativeCosts, [0, 1]);
      expect(preview.points.first.x, closeTo(expectedStart.x, 0.001));
      expect(
        preview.points.first.y,
        closeTo(expectedStart.y * HexGrid.perspectiveY - 12, 0.001),
      );
    });

    test('sync reuses a layer already attached to the parent', () async {
      final parent = Component();
      final layer = UnitMovePreviewLayer();

      await parent.add(layer);
      layer.sync(parent: parent, preview: _plan());

      expect(parent.children.query<UnitMovePreviewLayer>(), hasLength(1));
      expect(_previewsIn(parent), hasLength(1));
      expect(_pillsIn(parent), hasLength(1));
    });

    test('sync attaches the moving unit ghost type when available', () {
      final parent = Component();

      UnitMovePreviewLayer().sync(
        parent: parent,
        preview: _plan(),
        unitType: GameUnitType.worker,
      );

      final preview = _singlePreviewIn(parent);
      expect(preview.unitTypeForTesting, GameUnitType.worker);
      expect(preview.usesUnitGhostForTesting, isTrue);
    });

    test('syncMany adds every queued route as an animated preview', () {
      final parent = Component();

      UnitMovePreviewLayer().syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'queued:commander',
            preview: _plan(),
            unitType: GameUnitType.commander,
          ),
          UnitMovePreviewLayerEntry(
            id: 'queued:worker',
            preview: _plan(
              targetCol: 2,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 2,
                  cumulativeCost: 2,
                ),
              ],
            ),
            unitType: GameUnitType.worker,
          ),
        ],
      );

      final previews = _previewsIn(parent);
      expect(previews, hasLength(2));
      expect(
        previews.map((preview) => preview.unitTypeForTesting),
        containsAll([GameUnitType.commander, GameUnitType.worker]),
      );
      expect(
        previews.every((preview) => preview.usesUnitGhostForTesting),
        isTrue,
      );
    });

    test(
      'syncMany can mute cost labels and reduce route emphasis per entry',
      () {
        final parent = Component();

        UnitMovePreviewLayer().syncMany(
          parent: parent,
          previews: [
            UnitMovePreviewLayerEntry(
              id: 'queued:worker',
              preview: _plan(),
              unitType: GameUnitType.worker,
              subdued: true,
              showCostLabel: false,
            ),
          ],
        );

        final preview = _singlePreviewIn(parent);
        expect(preview.subduedForTesting, isTrue);
        expect(_pillsIn(parent), isEmpty);
      },
    );

    test('route and popup use independent priorities above map sprites', () {
      final parent = Component();

      UnitMovePreviewLayer().syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'active:commander',
            preview: _plan(),
            unitType: GameUnitType.commander,
            showConfirmationHint: true,
            showTargetArrow: true,
          ),
        ],
      );

      final preview = _singlePreviewIn(parent);
      final pill = _singlePillIn(parent);
      expect(preview.priority, UnitMovePreviewLayer.routePriority);
      expect(pill.priority, UnitMovePreviewLayer.pillPriority);
      expect(pill.priority, greaterThan(preview.priority));
      expect(
        pill.priority,
        greaterThan(MapPriority.perTile(MapPriority.hudPin, col: 0, row: 99)),
      );
    });

    test('clear removes the current preview component', () {
      final parent = Component();
      UnitMovePreviewLayer()
        ..sync(parent: parent, preview: _plan())
        ..clear();

      expect(_previewsIn(parent), isEmpty);
      expect(_pillsIn(parent), isEmpty);
    });

    test('sync propagates cost label density visibility', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer()
        ..showCostLabel = false
        ..sync(parent: parent, preview: _plan());

      expect(layer.showCostLabel, isFalse);
      expect(_pillsIn(parent), isEmpty);

      layer.showCostLabel = true;

      expect(_singlePillIn(parent).labelForTesting, '1 turn');
    });

    test('sync propagates dimmed overlay emphasis', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer()
        ..sync(parent: parent, preview: _plan(), dimmed: true);

      final preview = _singlePreviewIn(parent);
      expect(layer.dimmed, isTrue);
      expect(preview.dimmedForTesting, isTrue);

      layer.dimmed = false;

      expect(preview.dimmedForTesting, isFalse);
    });

    test('sync propagates the confirmation label state', () {
      final parent = Component();
      UnitMovePreviewLayer(turnCostLabelBuilder: _turnCountLabel).sync(
        parent: parent,
        preview: _plan(totalCost: 6),
        unitType: GameUnitType.warrior,
        showConfirmationHint: true,
      );

      expect(_singlePillIn(parent).labelForTesting, '2 turns');
    });

    test('sync propagates target preview and confirmed target emphasis', () {
      final parent = Component();
      UnitMovePreviewLayer().sync(
        parent: parent,
        preview: _plan(),
        showTargetPulse: true,
        showTargetArrow: true,
        showConfirmedTarget: true,
      );

      final preview = _singlePreviewIn(parent);
      expect(preview.showTargetPulseForTesting, isTrue);
      expect(preview.showTargetArrowForTesting, isTrue);
      expect(preview.showConfirmedTargetForTesting, isTrue);
    });

    test('sync reuses preview component when only visual state changes', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer();
      final plan = _plan();

      layer.sync(parent: parent, preview: plan);
      final initial = _singlePreviewIn(parent);

      layer.sync(
        parent: parent,
        preview: plan,
        showConfirmationHint: true,
        showTargetArrow: true,
      );

      final updated = _singlePreviewIn(parent);
      expect(updated, same(initial));
      expect(updated.showTargetArrowForTesting, isTrue);
    });

    test('sync keeps cumulative costs for blue and red path segments', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer();
      final plan = _plan(
        targetCol: 6,
        totalCost: 6,
        availableMovementPoints: 5,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 5, row: 0, enterCost: 1, cumulativeCost: 5),
          UnitMovementStep(col: 6, row: 0, enterCost: 1, cumulativeCost: 6),
        ],
      );

      layer.sync(parent: parent, preview: plan);

      final preview = _singlePreviewIn(parent);
      expect(preview.canMoveNow, isFalse);
      expect(preview.cumulativeCosts, [0, 1, 5, 6]);
    });

    test('route dash phase moves forward along the planned path', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(100, 0)],
        cumulativeCosts: const [0, 1],
        totalCost: 1,
        availableMovementPoints: 3,
        canMoveNow: true,
      );

      final firstVisibleAtStart = preview
          .dashStartsForTesting(pathLength: 100, phase: 0)
          .where((distance) => distance >= 0)
          .first;
      final firstVisibleLater = preview
          .dashStartsForTesting(pathLength: 100, phase: 4)
          .where((distance) => distance >= 0)
          .first;

      expect(firstVisibleLater, greaterThan(firstVisibleAtStart));
    });

    test('movement route fades after two hexes, not two turns', () {
      final preview = UnitMovePreview(
        points: [
          Vector2(0, 0),
          Vector2(20, 0),
          Vector2(40, 0),
          Vector2(60, 0),
          Vector2(80, 0),
        ],
        cumulativeCosts: const [0, 5, 10, 15, 20],
        totalCost: 20,
        availableMovementPoints: 1,
        canMoveNow: false,
      );

      expect(preview.routePointMutedForTesting(1), isFalse);
      expect(preview.routePointMutedForTesting(2), isFalse);
      expect(preview.routePointMutedForTesting(3), isTrue);
      expect(preview.routePointMutedForTesting(4), isTrue);
    });

    test('movement route focus follows the travelled preview position', () {
      final preview = UnitMovePreview(
        points: [
          Vector2(0, 0),
          Vector2(20, 0),
          Vector2(40, 0),
          Vector2(60, 0),
          Vector2(80, 0),
        ],
        cumulativeCosts: const [0, 1, 2, 3, 4],
        totalCost: 4,
        availableMovementPoints: 1,
        canMoveNow: false,
        travelledUpToIndex: 1,
      );

      expect(preview.routePointMutedForTesting(2), isFalse);
      expect(preview.routePointMutedForTesting(3), isFalse);
      expect(preview.routePointMutedForTesting(4), isTrue);
    });

    test('route stroke tapers gently after the next two forward hexes', () {
      final preview = UnitMovePreview(
        points: [
          Vector2(0, 0),
          Vector2(20, 0),
          Vector2(40, 0),
          Vector2(60, 0),
          Vector2(80, 0),
          Vector2(100, 0),
        ],
        cumulativeCosts: const [0, 1, 2, 3, 4, 5],
        totalCost: 5,
        availableMovementPoints: 1,
        canMoveNow: false,
      );

      expect(preview.routeStrokeScaleForTesting(1), 1.0);
      expect(preview.routeStrokeScaleForTesting(2), 1.0);
      expect(preview.routeStrokeScaleForTesting(3), closeTo(0.94, 0.001));
      expect(preview.routeStrokeScaleForTesting(4), closeTo(0.88, 0.001));
      expect(preview.routeStrokeScaleForTesting(5), closeTo(0.82, 0.001));
    });

    test('route stroke tapers behind the travelled preview position', () {
      final preview = UnitMovePreview(
        points: [
          Vector2(0, 0),
          Vector2(20, 0),
          Vector2(40, 0),
          Vector2(60, 0),
          Vector2(80, 0),
        ],
        cumulativeCosts: const [0, 1, 2, 3, 4],
        totalCost: 4,
        availableMovementPoints: 1,
        canMoveNow: false,
        travelledUpToIndex: 3,
      );

      expect(preview.routeStrokeScaleForTesting(4), 1.0);
      expect(preview.routeStrokeScaleForTesting(3), closeTo(0.90, 0.001));
      expect(preview.routeStrokeScaleForTesting(2), closeTo(0.845, 0.001));
      expect(preview.routeStrokeScaleForTesting(1), closeTo(0.79, 0.001));
    });

    test('travelling unit marker samples the full planned route', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(50, 0), Vector2(100, 0)],
        cumulativeCosts: const [0, 1, 2],
        totalCost: 2,
        availableMovementPoints: 1,
        canMoveNow: false,
        unitType: GameUnitType.warrior,
      );

      final marker = preview.travellingMarkerPositionForTesting(phase: 80);

      expect(marker, isNotNull);
      expect(marker!.dx, greaterThan(50));
    });

    test('cost label estimates turns instead of movement points', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer(turnCostLabelBuilder: _turnCountLabel)
        ..syncMany(
          parent: parent,
          previews: [
            UnitMovePreviewLayerEntry(
              id: 'one',
              preview: _plan(totalCost: 4, availableMovementPoints: 9),
              unitType: GameUnitType.commander,
            ),
            UnitMovePreviewLayerEntry(
              id: 'two',
              preview: _plan(totalCost: 6, availableMovementPoints: 9),
              unitType: GameUnitType.warrior,
            ),
            UnitMovePreviewLayerEntry(
              id: 'five',
              preview: _plan(totalCost: 15, availableMovementPoints: 9),
              unitType: GameUnitType.warrior,
            ),
          ],
        );

      expect(layer.pillForTesting('one')?.labelForTesting, '1 turn');
      expect(layer.pillForTesting('two')?.labelForTesting, '2 turns');
      expect(layer.pillForTesting('five')?.labelForTesting, '5 turns');
    });

    test('cost popup adds confirm hint for active planning preview', () {
      final parent = Component();
      final layer =
          UnitMovePreviewLayer(
            turnCostLabelBuilder: _turnCountLabel,
            confirmationLabelBuilder: _confirmWithTurns,
            confirmationLabel: _confirmLabel,
          )..syncMany(
            parent: parent,
            previews: [
              UnitMovePreviewLayerEntry(
                id: 'active',
                preview: _plan(totalCost: 15, availableMovementPoints: 3),
                unitType: GameUnitType.warrior,
                showConfirmationHint: true,
                showTargetPulse: true,
                showTargetArrow: true,
              ),
            ],
          );

      final preview = _singlePreviewIn(parent);
      expect(
        layer.pillForTesting('active')?.labelForTesting,
        'Confirm (5 turns)',
      );
      expect(preview.showTargetPulseForTesting, isTrue);
      expect(preview.showTargetArrowForTesting, isTrue);

      layer.syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'active',
            preview: _plan(totalCost: 15, availableMovementPoints: 3),
            unitType: GameUnitType.warrior,
          ),
        ],
      );

      expect(layer.pillForTesting('active')?.labelForTesting, '5 turns');
      expect(_singlePreviewIn(parent).showTargetPulseForTesting, isFalse);
      expect(_singlePreviewIn(parent).showTargetArrowForTesting, isFalse);
    });

    test('map pill grows to fit localized confirmation labels', () {
      final size = MapPillPainter.measure(
        'Confirm (12 turns)',
        icon: GameIcons.move,
      );

      expect(size.x, greaterThan(104));
      expect(size.x, lessThanOrEqualTo(MapPillPainter.maxWidth));
    });

    test('sync uses shared HUD intent colors', () {
      final parent = Component();
      UnitMovePreviewLayer().sync(parent: parent, preview: _plan());

      final preview = _singlePreviewIn(parent);
      expect(preview.reachableColor, HudPalette.gold);
      expect(preview.unreachableColor, HudPalette.danger);
    });

    test('render draws the animated travel marker without throwing', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(54, 0), Vector2(92, 28)],
        cumulativeCosts: const [0, 1, 2],
        totalCost: 2,
        availableMovementPoints: 3,
        canMoveNow: true,
        unitType: GameUnitType.warrior,
        showTargetPulse: true,
        showTargetArrow: true,
        showConfirmedTarget: true,
      )..update(0.16);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      expect(preview.showStartMarkerForTesting, isTrue);
      expect(() => preview.render(canvas), returnsNormally);

      recorder.endRecording().dispose();
    });
  });
}
