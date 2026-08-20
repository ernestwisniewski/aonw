import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/domain.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

part 'unit_move_preview_route_semantics_cases.dart';

void main() {
  group('UnitMovePreviewLayer', () {
    test('sync adds a preview component with projected path points', () {
      final parent = Component();
      UnitMovePreviewLayer().sync(parent: parent, preview: _plan());

      final preview = _singlePreviewIn(parent);
      final expectedStart = HexGeometry.projectedTopFaceCenter(
        col: 0,
        row: 0,
        perspectiveY: HexGrid.perspectiveY,
        hexRadius: MapConfig.defaultConfig.hexRadius,
      );
      expect(parent.children.query<UnitMovePreviewLayer>(), hasLength(1));
      expect(preview.routeColor, HudPalette.roadMarking);
      expect(preview.priority, UnitMovePreviewLayer.routePriority);
      expect(
        preview.priority,
        greaterThan(MapPriority.perTile(MapPriority.sprite, col: 99, row: 99)),
      );
      expect(preview.points, hasLength(2));
      expect(preview.reachablePoints, [isTrue, isTrue]);
      expect(preview.points.first.x, closeTo(expectedStart.x, 0.001));
      expect(preview.points.first.y, closeTo(expectedStart.y, 0.001));
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

    test('sync uses the localized turn estimate', () {
      final parent = Component();
      UnitMovePreviewLayer(turnCostLabelBuilder: _turnCountLabel).sync(
        parent: parent,
        preview: _confirmationEtaPlan(),
        unitType: GameUnitType.warrior,
      );

      expect(_singlePillIn(parent).labelForTesting, '2 turns');
    });

    test('sync propagates the target outline', () {
      final parent = Component();
      UnitMovePreviewLayer().sync(
        parent: parent,
        preview: _plan(),
        showTargetOutline: true,
      );

      final preview = _singlePreviewIn(parent);
      expect(preview.showTargetOutlineForTesting, isTrue);
      expect(preview.targetOutlineColor, HudPalette.roadMarking);
    });

    test('sync reuses preview component when only visual state changes', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer();
      final plan = _plan();

      layer.sync(parent: parent, preview: plan);
      final initial = _singlePreviewIn(parent);

      layer.sync(parent: parent, preview: plan, showTargetOutline: true);

      final updated = _singlePreviewIn(parent);
      expect(updated, same(initial));
      expect(updated.showTargetOutlineForTesting, isTrue);
    });

    test('sync uses domain reachability for route segments', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer();
      final plan = _plan(
        targetCol: 6,
        totalCost: 6,
        availableMovementUnits: 5,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 5, row: 0, enterCost: 1, cumulativeCost: 5),
          UnitMovementStep(col: 6, row: 0, enterCost: 1, cumulativeCost: 6),
        ],
      );

      layer.sync(parent: parent, preview: plan);

      final preview = _singlePreviewIn(parent);
      expect(preview.reachablePoints, [isTrue, isTrue, isTrue, isFalse]);
    });

    _registerGeneratedReachabilityPropertyTest();

    _registerRouteSemanticsTests();

    test('route dash phase moves forward along the planned path', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(100, 0)],
        reachablePoints: const [true, true],
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

    test('straight hex steps render as stable organic curves', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(100, 0)],
        reachablePoints: const [true, true],
      );

      final firstBounds = preview.routeSegmentBoundsForTesting(1);
      final firstLength = preview.routeSegmentLengthForTesting(1);
      final secondBounds = preview.routeSegmentBoundsForTesting(1);
      final secondLength = preview.routeSegmentLengthForTesting(1);

      expect(firstBounds.height, greaterThan(1));
      expect(firstLength, greaterThan(100));
      expect(secondBounds, firstBounds);
      expect(secondLength, firstLength);
    });

    test('road segments use the exact road centerline', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(100, 0), Vector2(200, 0)],
        reachablePoints: const [true, true, true],
        roadSegmentIndices: const {1},
      );

      expect(preview.routeSegmentFollowsRoadForTesting(1), isTrue);
      expect(preview.routeSegmentBoundsForTesting(1).height, 0);
      expect(preview.routeSegmentLengthForTesting(1), 100);
      expect(
        preview.travellingMarkerPositionForTesting(phase: 20)?.dy,
        closeTo(0, 0.001),
      );
      expect(preview.routeSegmentFollowsRoadForTesting(2), isFalse);
      expect(preview.routeSegmentBoundsForTesting(2).height, greaterThan(1));
    });

    test('route states separate history, this turn, and later turns', () {
      final preview = UnitMovePreview(
        points: [
          Vector2(0, 0),
          Vector2(40, 0),
          Vector2(80, 0),
          Vector2(120, 0),
        ],
        reachablePoints: const [true, true, true, false],
        travelledUpToIndex: 1,
      );

      expect(preview.routeSegmentAnimatedForTesting(1), isFalse);
      expect(preview.routeSegmentGlowingForTesting(1), isFalse);
      expect(preview.routeSegmentAnimatedForTesting(2), isTrue);
      expect(preview.routeSegmentGlowingForTesting(2), isTrue);
      expect(preview.routeSegmentAnimatedForTesting(3), isTrue);
      expect(preview.routeSegmentGlowingForTesting(3), isFalse);
      expect(preview.routeBoundaryPointIndicesForTesting, [1, 2]);
      expect(
        preview.routeBoundaryRadiusForTesting(2),
        greaterThan(preview.routeBoundaryRadiusForTesting(1)),
      );
      expect(preview.routeBoundaryHasBorderForTesting(2), isTrue);
      expect(preview.routeBoundaryHasBorderForTesting(1), isFalse);

      final phasesBefore = [
        for (var index = 1; index <= 3; index++)
          preview.routeSegmentDashPhaseForTesting(index),
      ];
      preview.update(0.25);
      final phasesAfter = [
        for (var index = 1; index <= 3; index++)
          preview.routeSegmentDashPhaseForTesting(index),
      ];
      expect(phasesAfter[0], phasesBefore[0]);
      expect(phasesAfter[1], isNot(phasesBefore[1]));
      expect(phasesAfter[2], isNot(phasesBefore[2]));
    });

    test('route boundary dots only mark transitions between route states', () {
      final preview = UnitMovePreview(
        points: [
          Vector2(0, 0),
          Vector2(30, 0),
          Vector2(60, 0),
          Vector2(90, 0),
          Vector2(120, 0),
          Vector2(150, 0),
        ],
        reachablePoints: const [true, true, true, true, false, false],
        travelledUpToIndex: 2,
      );

      expect(preview.routeBoundaryPointIndicesForTesting, [2, 3]);
      expect(
        preview.routeBoundaryRadiusForTesting(3),
        greaterThan(preview.routeBoundaryRadiusForTesting(2)),
      );
    });

    test('route boundary dots mark the end of every movement turn', () {
      final parent = Component();
      UnitMovePreviewLayer().syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'three-turn-route',
            preview: _linearPlan(totalCost: 8, availableMovementUnits: 3),
            maxMovementPointsPerTurn: 3,
          ),
        ],
      );

      final preview = _singlePreviewIn(parent);
      expect(preview.routeBoundaryPointIndicesForTesting, [3, 6]);
      expect(
        preview.routeBoundaryRadiusForTesting(3),
        greaterThan(preview.routeBoundaryRadiusForTesting(6)),
      );
    });

    test('travelling unit marker samples the full planned route', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(50, 0), Vector2(100, 0)],
        reachablePoints: const [true, true, false],
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
              preview: _linearPlan(totalCost: 8, availableMovementUnits: 10),
              unitType: GameUnitType.commander,
            ),
            UnitMovePreviewLayerEntry(
              id: 'two',
              preview: _linearPlan(totalCost: 12, availableMovementUnits: 6),
              unitType: GameUnitType.warrior,
            ),
            UnitMovePreviewLayerEntry(
              id: 'five',
              preview: _linearPlan(totalCost: 30, availableMovementUnits: 6),
              unitType: GameUnitType.warrior,
            ),
          ],
        );

      expect(layer.pillForTesting('one')?.labelForTesting, '1 turn');
      expect(layer.pillForTesting('two')?.labelForTesting, '2 turns');
      expect(layer.pillForTesting('five')?.labelForTesting, '5 turns');
    });

    test('target outline can change without rebuilding the route', () {
      final parent = Component();
      final layer = UnitMovePreviewLayer()
        ..syncMany(
          parent: parent,
          previews: [
            UnitMovePreviewLayerEntry(
              id: 'active',
              preview: _linearPlan(totalCost: 3, availableMovementUnits: 6),
              unitType: GameUnitType.warrior,
              showTargetOutline: true,
            ),
          ],
        );

      final preview = _singlePreviewIn(parent);
      expect(preview.showTargetOutlineForTesting, isTrue);

      layer.syncMany(
        parent: parent,
        previews: [
          UnitMovePreviewLayerEntry(
            id: 'active',
            preview: _linearPlan(totalCost: 3, availableMovementUnits: 6),
            unitType: GameUnitType.warrior,
          ),
        ],
      );

      expect(_singlePreviewIn(parent), same(preview));
      expect(preview.showTargetOutlineForTesting, isFalse);
    });

    test('map pill grows to fit localized confirmation labels', () {
      final size = MapPillPainter.measure(
        'Confirm (12 turns)',
        icon: GameIcons.move,
      );

      expect(size.x, greaterThan(104));
      expect(size.x, lessThanOrEqualTo(MapPillPainter.maxWidth));
    });

    test('sync uses white routes and target outline', () {
      final parent = Component();
      UnitMovePreviewLayer().sync(parent: parent, preview: _plan());

      final preview = _singlePreviewIn(parent);
      expect(preview.routeColor, HudPalette.roadMarking);
      expect(preview.targetOutlineColor, HudPalette.roadMarking);
    });

    test('render draws the animated travel marker without throwing', () {
      final preview = UnitMovePreview(
        points: [Vector2(0, 0), Vector2(54, 0), Vector2(92, 28)],
        reachablePoints: const [true, true, true],
        unitType: GameUnitType.warrior,
        showTargetOutline: true,
      )..update(0.16);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      expect(preview.showTargetOutlineForTesting, isTrue);
      expect(() => preview.render(canvas), returnsNormally);

      recorder.endRecording().dispose();
    });
  });
}
