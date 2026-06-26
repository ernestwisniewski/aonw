import 'dart:ui';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 4,
  rows: 2,
  tiles: [
    for (var row = 0; row < 2; row++)
      for (var col = 0; col < 4; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameUnit _unit({int col = 0, int row = 0}) =>
    GameUnit.startingCommander(ownerPlayerId: 'player_1', col: col, row: row);

GameUnit _worker({WorkerJob? job, WorkerAssignment? assignment}) => GameUnit(
  id: 'worker_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.worker,
  name: GameUnitType.worker.defaultNameToken,
  col: 1,
  row: 1,
  workerJob: job,
  workerAssignment: assignment,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnitMarkerLayer', () {
    test('commander walk sprite uses the sequence row for every direction', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      void expectWalkColumn(Vector2 to) {
        marker.playWalkToward(from: Vector2.zero(), to: to);
        expect(marker.spriteColumnForTesting, 0);
      }

      expectWalkColumn(Vector2(0, 10));
      expectWalkColumn(Vector2(-10, 10));
      expectWalkColumn(Vector2(-10, 0));
      expectWalkColumn(Vector2(-10, -10));
      expectWalkColumn(Vector2(0, -10));
      expectWalkColumn(Vector2(10, -10));
      expectWalkColumn(Vector2(10, 0));
      expectWalkColumn(Vector2(10, 10));
    });

    test('all sprite-backed units idle animate even when unselected', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
        selected: true,
      );
      final other = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      final originalPosition = marker.position.clone();

      expect(marker.animatesSpriteForTesting, isTrue);
      expect(other.animatesSpriteForTesting, isTrue);
      expect(marker.spriteColumnForTesting, 0);
      expect(other.spriteColumnForTesting, 0);

      marker.update(0.55);
      other.update(0.55);
      expect(marker.spriteColumnForTesting, 0);
      expect(other.spriteColumnForTesting, 0);

      marker.update(0.20);
      other.update(0.20);
      expect(marker.spriteColumnForTesting, 0);
      expect(other.spriteColumnForTesting, 0);

      marker.update(0.15);
      other.update(0.15);
      expect(marker.spriteColumnForTesting, 1);
      expect(other.spriteColumnForTesting, 1);
      expect(marker.position, originalPosition);

      marker.update(0.90);
      expect(marker.spriteColumnForTesting, 2);
      expect(marker.position, originalPosition);

      marker.update(0.90);
      expect(marker.spriteColumnForTesting, 3);
      expect(marker.position, originalPosition);
    });

    test('selected unit disables idle pauses while selected', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
        selected: true,
      );

      expect(marker.spriteIdlePausesEnabledForTesting, isFalse);

      marker.selected = false;
      expect(marker.spriteIdlePausesEnabledForTesting, isTrue);

      marker.selected = true;
      expect(marker.spriteIdlePausesEnabledForTesting, isFalse);
    });

    test('uses sprite-backed markers for available unit types', () {
      final settler = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.settler,
      );
      final warrior = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.warrior,
      );
      final worker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.worker,
      );

      expect(settler.spriteColumnForTesting, 0);
      expect(warrior.spriteColumnForTesting, 0);
      expect(worker.spriteColumnForTesting, 0);
    });

    test('replaces owner bar with a type icon badge for sprite units', () {
      final commander = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      final archer = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.archer,
      );

      expect(commander.usesTypeIconBadgeForTesting, isTrue);
      expect(archer.usesTypeIconBadgeForTesting, isTrue);
    });

    test('paints a compact ground shadow under unit sprites', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );

      expect(
        marker.spriteShadowRectForTesting,
        const Rect.fromLTWH(4, 21, 24, 8),
      );

      marker.onCity = true;

      expect(
        marker.spriteShadowRectForTesting,
        const Rect.fromLTWH(7, 20, 18, 6),
      );
    });

    test('accepts taps on the type icon above the marker body', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      final iconRect = marker.typeIconRectForTesting;

      expect(iconRect.bottom, lessThan(0));
      expect(
        marker.containsLocalPoint(
          Vector2(iconRect.center.dx, iconRect.center.dy),
        ),
        isTrue,
      );
    });

    test('shows an artifact carrier badge and accepts taps on it', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.scout,
        carryingArtifact: true,
      );
      final badgeRect = marker.artifactBadgeRectForTesting;

      expect(marker.carryingArtifactForTesting, isTrue);
      expect(marker.artifactBadgeBackgroundAlphaForTesting, 226);
      expect(badgeRect.center.dx, lessThan(16));
      expect(
        marker.containsLocalPoint(
          Vector2(badgeRect.center.dx, badgeRect.center.dy),
        ),
        isTrue,
      );
    });

    test('tactical zoom shrinks sprite and moves status toward hex center', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      final normalSize = marker.spriteRenderSizeForTesting!;
      final normalStatusTop = marker.spriteStatusTopForTesting;
      final normalTypeIcon = marker.typeIconRectForTesting;

      marker
        ..spriteScale = 0.68
        ..tacticalViewEmphasis = 1
        ..animateIdle = false;

      final tacticalSize = marker.spriteRenderSizeForTesting!;
      final tacticalStatusTop = marker.spriteStatusTopForTesting;
      final tacticalTypeIcon = marker.typeIconRectForTesting;

      expect(tacticalSize.width, closeTo(normalSize.width * 0.68, 0.001));
      expect(tacticalSize.height, closeTo(normalSize.height * 0.68, 0.001));
      expect(tacticalStatusTop, greaterThan(normalStatusTop));
      expect(
        (tacticalTypeIcon.center.dy - 16).abs(),
        lessThan((normalTypeIcon.center.dy - 16).abs()),
      );
      expect(marker.animatesSpriteForTesting, isFalse);

      marker.playWalkToward(from: Vector2.zero(), to: Vector2(10, 0));

      expect(marker.animatesSpriteForTesting, isTrue);
    });

    test('partial tactical zoom keeps the marker above the unit asset', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      final normalTypeIcon = marker.typeIconRectForTesting;

      marker
        ..spriteScale = 0.68
        ..tacticalViewEmphasis = 0.6;

      final tuckedStatusTop = marker.spriteStatusTopForTesting;
      final tuckedTypeIcon = marker.typeIconRectForTesting;

      marker.tacticalViewEmphasis = 1;

      final centeredStatusTop = marker.spriteStatusTopForTesting;
      final centeredTypeIcon = marker.typeIconRectForTesting;

      expect(tuckedTypeIcon.center.dy, greaterThan(normalTypeIcon.center.dy));
      expect(tuckedTypeIcon.center.dy, lessThan(0));
      expect(tuckedStatusTop, lessThan(centeredStatusTop));
      expect(centeredTypeIcon.center.dy, greaterThan(tuckedTypeIcon.center.dy));
    });

    test('pulses the type icon border while selected', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
        selected: true,
      );
      final initialPulse = marker.typeIconPulseForTesting;
      void advance(double seconds) => marker.update(seconds);

      advance(0.3);

      expect(marker.typeIconPulseForTesting, isNot(initialPulse));
      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
      expect(marker.selectionRingStrokeWidthForTesting, 0);
      expect(marker.selectionRingRectForTesting, Rect.zero);

      marker.selected = false;

      expect(marker.typeIconPulseForTesting, 0);
      expect(marker.hasSelectionRingForTesting, isFalse);
    });

    test('pulses the type icon border while attack targeted', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
        attackTarget: true,
      );
      final initialPulse = marker.typeIconPulseForTesting;

      marker.update(0.3);

      expect(marker.typeIconPulseForTesting, isNot(initialPulse));
      expect(marker.hasAttackTargetTintForTesting, isTrue);

      marker.attackTarget = false;

      expect(marker.typeIconPulseForTesting, 0);
      expect(marker.hasAttackTargetTintForTesting, isFalse);
    });

    test('keeps selection and pending cues static with reduce motion', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
        selected: true,
        pendingActionTarget: true,
        reduceMotion: true,
      );

      expect(marker.typeIconPulseForTesting, 0);
      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
      expect(marker.hasFocusPulseForTesting, isFalse);
      expect(marker.scale.x, closeTo(1.06, 0.0001));

      marker.update(0.3);

      expect(marker.typeIconPulseForTesting, 0);

      marker
        ..reduceMotion = false
        ..pendingActionTarget = false;

      expect(marker.hasSelectionTintForTesting, isFalse);
      expect(marker.hasSelectionRingForTesting, isFalse);
      expect(marker.hasFocusPulseForTesting, isTrue);
      expect(marker.scale.x, closeTo(1, 0.0001));
    });

    test('zooms selected units in and out like combat emphasis', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
        selected: true,
      );

      expect(marker.hasFocusPulseForTesting, isTrue);
      expect(marker.scale.x, closeTo(1, 0.0001));

      marker.update(0.55);

      expect(marker.scale.x, greaterThan(1));
      expect(marker.scale.y, closeTo(marker.scale.x, 0.0001));

      marker.update(0.35);

      expect(marker.scale.x, closeTo(1, 0.0001));

      marker.selected = false;

      expect(marker.hasFocusPulseForTesting, isFalse);
      expect(marker.scale.x, closeTo(1, 0.0001));
    });

    test('keeps sprite status controls lower than the raw sprite bounds', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.commander,
      );
      const centerY = 14.0;
      const spriteTop = centerY - 86 * 0.66;

      expect(marker.spriteStatusTopForTesting, greaterThan(spriteTop));
    });

    test('worker work animation advances at a slower cadence', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.worker,
      )..playWork();

      expect(marker.animatesSpriteForTesting, isTrue);
      expect(marker.spriteColumnForTesting, 0);

      marker.update(0.08);
      expect(marker.spriteColumnForTesting, 0);

      marker.update(0.08);
      expect(marker.spriteColumnForTesting, 0);

      marker.update(0.07);
      expect(marker.spriteColumnForTesting, 1);
    });

    test('worker work status follows the work frame geometry', () async {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.worker,
        selected: true,
      );
      await marker.onLoad();
      final idleStatusTop = marker.spriteStatusTopForTesting;

      marker.playWork();
      final workStatusTop = marker.spriteStatusTopForTesting;

      expect(marker.spriteActionForTesting, UnitSpriteAction.work);
      expect(
        workStatusTop,
        isNot(closeTo(idleStatusTop, 0.0001)),
        reason: 'work frames should recompute HUD anchors from their metadata',
      );

      marker.update(0.23);

      expect(marker.spriteColumnForTesting, 1);
      expect(
        marker.spriteStatusTopForTesting,
        isNot(closeTo(idleStatusTop, 0.0001)),
      );
    });

    test('reuses unit markers and updates priority when a unit moves', () {
      final parent = PositionComponent();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      );
      void syncUnit(GameUnit unit) {
        layer.sync(parent: parent, units: [unit], selectedUnitId: null);
      }

      syncUnit(_unit());
      expect(parent.children.query<UnitMarkerLayer>(), hasLength(1));
      final marker = parent.children.whereType<UnitMarker>().single;
      expect(
        marker.priority,
        MapPriority.perTileUnit(mapRows: _map().rows, col: 0, row: 0),
      );

      syncUnit(_unit(col: 2, row: 1));

      expect(parent.children.whereType<UnitMarker>().single, same(marker));
      expect(
        marker.priority,
        MapPriority.perTileUnit(mapRows: _map().rows, col: 2, row: 1),
      );
    });

    test('wires marker taps to unit selection callbacks', () {
      final parent = PositionComponent();
      String? tappedUnitId;
      final unit = _unit();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
        onUnitTapped: (unitId) => tappedUnitId = unitId,
      )..sync(parent: parent, units: [unit], selectedUnitId: null);

      expect(layer.isMarkerSelectedForTesting(unit.id), isFalse);
      parent.children.whereType<UnitMarker>().single.onTap?.call();

      expect(tappedUnitId, unit.id);
    });

    test('keeps a unit on a city above the city marker priority', () {
      final parent = PositionComponent();
      final unit = _unit(col: 2, row: 1);
      final layer =
          UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF)
            ..sync(
              parent: parent,
              units: [unit],
              selectedUnitId: null,
              cityTiles: const {(col: 2, row: 1)},
            );

      final marker = parent.children.whereType<UnitMarker>().single;
      final sameTileCityPriority = MapPriority.perTile(
        MapPriority.city,
        col: 2,
        row: 1,
      );
      expect(marker.priority, greaterThan(sameTileCityPriority));
      expect(layer.isMarkerSelectedForTesting(unit.id), isFalse);
    });

    test('places merchant on the opposite city side when stacked', () {
      final parent = PositionComponent();
      final warrior = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 1,
      );
      final merchant = GameUnit.produced(
        id: 'merchant_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.merchant,
        col: 2,
        row: 1,
      );
      final layer =
          UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF)
            ..sync(
              parent: parent,
              units: [warrior, merchant],
              selectedUnitId: null,
              cityTiles: const {(col: 2, row: 1)},
            );

      expect(
        layer.markerPositionForTesting(warrior.id),
        UnitMarkerLayer.worldPositionFor(2, 1, onCity: true),
      );
      expect(
        layer.markerPositionForTesting(merchant.id),
        UnitMarkerLayer.worldPositionFor(
          2,
          1,
          onCity: true,
          cityCompanionSide: true,
        ),
      );
      expect(
        layer.markerPositionForTesting(merchant.id),
        isNot(layer.markerPositionForTesting(warrior.id)),
      );
    });

    test('keeps units above city and improvement markers across rows', () {
      final map = _map();
      final parent = PositionComponent();
      final unitLayer = UnitMarkerLayer(
        mapData: map,
        colorForPlayer: (_) => 0xFF0000FF,
      )..sync(parent: parent, units: [_unit()], selectedUnitId: null);
      final cityLayer = CityMarkerLayer(colorForPlayer: (_) => 0xFF0000FF)
        ..sync(
          parent: parent,
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 2, row: 1),
            ),
          ],
          selectedCityId: null,
        );
      final improvementLayer = FieldImprovementMarkerLayer()
        ..sync(
          parent: parent,
          improvements: const [
            FieldImprovement(
              hex: CityHex(col: 2, row: 1),
              type: FieldImprovementType.farm,
            ),
          ],
          cities: const [],
        );

      final unitPriority = parent.children
          .whereType<UnitMarker>()
          .single
          .priority;
      final cityPriority = cityLayer.markerPriorityForTesting('city_1');
      final improvementPriority = improvementLayer.markerPriorityForTesting(
        2,
        1,
      );
      expect(cityPriority, isNotNull);
      expect(improvementPriority, isNotNull);
      expect(unitPriority, greaterThan(cityPriority!));
      expect(unitPriority, greaterThan(improvementPriority!));
      expect(unitLayer.isMarkerSelectedForTesting(_unit().id), isFalse);
    });

    test('sets unit health fraction from combat hit points', () {
      final parent = PositionComponent();
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
        hitPoints: 4,
      );
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      )..sync(parent: parent, units: [warrior], selectedUnitId: null);

      expect(
        layer.markerHealthFractionForTesting(warrior.id),
        closeTo(0.4, 0.0001),
      );
    });

    test('uses derived commander army max HP for unit health fraction', () {
      final parent = PositionComponent();
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
      ).copyWithHitPoints(6);
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      )..sync(parent: parent, units: [commander], selectedUnitId: null);

      expect(
        layer.markerHealthFractionForTesting(commander.id),
        closeTo(6 / 11, 0.0001),
      );
    });

    test('pins marker position until animateMove starts', () {
      final parent = PositionComponent();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      )..sync(parent: parent, units: [_unit()], selectedUnitId: null);
      final marker = parent.children.whereType<UnitMarker>().single;
      final originalPosition = marker.position.clone();

      layer
        ..pinPendingMovePositions({_unit().id})
        ..sync(
          parent: parent,
          units: [_unit(col: 2, row: 1)],
          selectedUnitId: _unit().id,
        );

      expect(
        marker.position,
        originalPosition,
        reason: 'sync must not move the marker for pending moves',
      );
      expect(
        marker.selected,
        isTrue,
        reason: 'pending moves should only pin position, not selection UI',
      );
    });

    test('jumps move animations to the final step with reduce motion', () {
      final parent = PositionComponent();
      final unit = _unit();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
        reduceMotion: true,
      )..sync(parent: parent, units: [unit], selectedUnitId: null);
      var completed = false;

      layer.animateMove(
        unitId: unit.id,
        fromCol: 0,
        fromRow: 0,
        steps: const [
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 2),
        ],
        onComplete: () => completed = true,
      );

      expect(completed, isTrue);
      expect(layer.animatingUnitIds, isEmpty);
      expect(
        layer.markerPositionForTesting(unit.id),
        UnitMarkerLayer.worldPositionFor(2, 1),
      );
      expect(
        parent.children
            .whereType<UnitMarker>()
            .single
            .children
            .whereType<SequenceEffect>(),
        isEmpty,
      );
    });

    test('pulses marker for the unit targeted by pending action', () {
      final parent = PositionComponent();
      final worker = _worker();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      );
      final pending = PendingWorkerActionSelection(
        ownerPlayerId: worker.ownerPlayerId,
        unitId: worker.id,
      );

      layer.sync(
        parent: parent,
        units: [worker],
        selectedUnitId: null,
        pendingActionUnitId: UnitMarkerLayer.pendingActionUnitId(pending),
      );

      expect(layer.isMarkerPendingActionTargetForTesting(worker.id), isTrue);
      expect(layer.markerHasFocusPulseForTesting(worker.id), isTrue);

      layer.sync(parent: parent, units: [worker], selectedUnitId: null);

      expect(layer.isMarkerPendingActionTargetForTesting(worker.id), isFalse);
      expect(layer.markerHasFocusPulseForTesting(worker.id), isFalse);
    });

    test('propagates reduce motion to pending action markers', () {
      final parent = PositionComponent();
      final worker = _worker();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
        reduceMotion: true,
      );
      final pending = PendingWorkerActionSelection(
        ownerPlayerId: worker.ownerPlayerId,
        unitId: worker.id,
      );

      layer.sync(
        parent: parent,
        units: [worker],
        selectedUnitId: null,
        pendingActionUnitId: UnitMarkerLayer.pendingActionUnitId(pending),
      );

      expect(layer.markerReduceMotionForTesting(worker.id), isTrue);
      expect(layer.isMarkerPendingActionTargetForTesting(worker.id), isTrue);
      expect(layer.markerHasFocusPulseForTesting(worker.id), isFalse);

      layer.reduceMotion = false;

      expect(layer.markerReduceMotionForTesting(worker.id), isFalse);
      expect(layer.markerHasFocusPulseForTesting(worker.id), isTrue);
    });

    test('syncs posture, skipped-turn, and exhausted state badges', () {
      final parent = PositionComponent();
      final fortified = GameUnit(
        id: 'fortified_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      );
      final healing = GameUnit(
        id: 'healing_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 1,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      ).copyWithHitPoints(7);
      final skipped = GameUnit(
        id: 'skipped_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 0,
        movementPoints: 0,
      );
      final exhausted = GameUnit(
        id: 'exhausted_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.archer,
        name: GameUnitType.archer.defaultNameToken,
        col: 2,
        row: 0,
        movementPoints: 0,
      );
      final ready = GameUnit(
        id: 'ready_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        name: GameUnitType.settler.defaultNameToken,
        col: 3,
        row: 0,
        movementPoints: 1,
      );
      final layer =
          UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF)
            ..sync(
              parent: parent,
              units: [fortified, healing, skipped, exhausted, ready],
              selectedUnitId: null,
              pendingAction: PendingUnitTurnSkip(
                ownerPlayerId: skipped.ownerPlayerId,
                unitId: skipped.id,
                restoreMovementPoints: 3,
              ),
            );

      expect(
        layer.markerStateBadgeForTesting(fortified.id),
        UnitMarkerStateBadge.fortified,
      );
      expect(
        layer.markerStateBadgeForTesting(healing.id),
        UnitMarkerStateBadge.healing,
      );
      expect(
        layer.markerStateBadgeForTesting(skipped.id),
        UnitMarkerStateBadge.skippedTurn,
      );
      expect(
        layer.markerStateBadgeForTesting(exhausted.id),
        UnitMarkerStateBadge.exhausted,
      );
      expect(layer.markerStateBadgeForTesting(ready.id), isNull);
      expect(layer.markerIsExhaustedForTesting(fortified.id), isTrue);
      expect(layer.markerIsExhaustedForTesting(healing.id), isTrue);
      expect(layer.markerIsExhaustedForTesting(skipped.id), isTrue);
      expect(layer.markerIsExhaustedForTesting(exhausted.id), isTrue);
      expect(layer.markerIsExhaustedForTesting(ready.id), isFalse);
    });

    test('syncs artifact carrying badge from unit state', () {
      final layer = UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0);
      final parent = Component();
      final carrier = _unit().copyWithCarriedArtifact('artifact_1');

      layer.sync(parent: parent, units: [carrier], selectedUnitId: null);

      expect(layer.markerCarriesArtifactForTesting(carrier.id), isTrue);

      layer.sync(parent: parent, units: [_unit()], selectedUnitId: null);

      expect(layer.markerCarriesArtifactForTesting(carrier.id), isFalse);
    });

    test('uses compact, subdued state and work badge styling', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.warrior,
        fortified: true,
      );

      expect(marker.stateBadgeForTesting, UnitMarkerStateBadge.fortified);
      expect(marker.stateBadgeRadiusForTesting, 5.5);
      expect(marker.stateBadgeBackgroundAlphaForTesting, 205);
      expect(marker.workBadgeBackgroundAlphaForTesting, 186);

      marker.onCity = true;

      expect(marker.stateBadgeRadiusForTesting, 5.0);
    });

    test('hides peripheral marker details at distant zoom', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.warrior,
        fortified: true,
        showPeripheralDetails: false,
      );

      expect(marker.paintsIdentityBadgeForTesting, isFalse);
      expect(marker.paintsHealthBarForTesting, isFalse);
      expect(marker.paintsStateBadgeForTesting, isFalse);
      expect(marker.paintsOwnerColorForTesting, isFalse);
      expect(marker.paintsTypeBadgeForTesting, isFalse);

      marker.healthFraction = 0.5;

      expect(marker.paintsIdentityBadgeForTesting, isFalse);
      expect(marker.paintsHealthBarForTesting, isTrue);
      expect(marker.paintsStateBadgeForTesting, isFalse);
      expect(marker.paintsOwnerColorForTesting, isFalse);
      expect(marker.paintsTypeBadgeForTesting, isFalse);

      marker.selected = true;

      expect(marker.paintsIdentityBadgeForTesting, isTrue);
      expect(marker.paintsHealthBarForTesting, isTrue);
      expect(marker.paintsStateBadgeForTesting, isTrue);
      expect(marker.paintsOwnerColorForTesting, isTrue);
      expect(marker.paintsTypeBadgeForTesting, isTrue);
    });

    test('supports independent marker detail visibility flags', () {
      final marker = UnitMarker(
        position: Vector2.zero(),
        colorValue: 0xFF0000FF,
        unitType: GameUnitType.warrior,
        fortified: true,
        showPeripheralDetails: false,
        showOwnerColor: true,
        showHealthBar: false,
        showTypeBadge: false,
        showStateBadge: true,
      );

      expect(marker.showPeripheralDetailsForTesting, isFalse);
      expect(marker.showOwnerColorForTesting, isTrue);
      expect(marker.showHealthBarForTesting, isFalse);
      expect(marker.showTypeBadgeForTesting, isFalse);
      expect(marker.showStateBadgeForTesting, isTrue);
      expect(marker.paintsOwnerColorForTesting, isTrue);
      expect(marker.paintsTypeBadgeForTesting, isFalse);
      expect(marker.paintsHealthBarForTesting, isFalse);
      expect(marker.paintsStateBadgeForTesting, isTrue);
    });

    test('tints attack targets with the selection pulse animation', () {
      final parent = PositionComponent();
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 2,
        row: 0,
      );
      final layer =
          UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFFFF0000)
            ..sync(
              parent: parent,
              units: [enemy],
              selectedUnitId: null,
              attackTargetUnitIds: {enemy.id},
            );

      expect(layer.isMarkerAttackTargetForTesting(enemy.id), isTrue);
      expect(layer.markerHasAttackTargetTintForTesting(enemy.id), isTrue);

      layer.sync(parent: parent, units: [enemy], selectedUnitId: null);

      expect(layer.isMarkerAttackTargetForTesting(enemy.id), isFalse);
      expect(layer.markerHasAttackTargetTintForTesting(enemy.id), isFalse);
    });

    test('completes combat immediately and releases retained markers', () {
      final parent = PositionComponent();
      final attacker = GameUnit(
        id: 'attacker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
      );
      final defender = GameUnit(
        id: 'defender_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 0,
      );
      final layer =
          UnitMarkerLayer(
            mapData: _map(),
            colorForPlayer: (_) => 0xFF0000FF,
            reduceMotion: true,
          )..sync(
            parent: parent,
            units: [attacker, defender],
            selectedUnitId: null,
          );
      var completed = false;

      layer
        ..retainPendingAnimationMarkers({attacker.id, defender.id})
        ..sync(parent: parent, units: [attacker], selectedUnitId: null);

      expect(layer.hasMarkerForTesting(defender.id), isTrue);

      layer
        ..animateCombat(
          attackerUnitId: attacker.id,
          defenderUnitId: defender.id,
          attackerKilled: false,
          defenderKilled: true,
          onComplete: () => completed = true,
        )
        ..sync(parent: parent, units: [attacker], selectedUnitId: null);

      expect(completed, isTrue);
      expect(layer.animatingUnitIds, isEmpty);
      expect(layer.hasMarkerForTesting(defender.id), isFalse);
    });

    test('worker job animates work pose and shrinks marker sprite', () {
      final parent = PositionComponent();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      );
      final worker = _worker(
        job: const WorkerJob(
          targetHex: CityHex(col: 1, row: 1),
          improvementType: FieldImprovementType.farm,
          remainingTurns: 2,
          totalTurns: 3,
        ),
      );

      layer.sync(parent: parent, units: [worker], selectedUnitId: null);

      expect(layer.markerActionForTesting('worker_1'), UnitSpriteAction.work);
      expect(layer.markerAnimatesSpriteForTesting('worker_1'), isTrue);
      expect(layer.markerCompactWorkVisualForTesting('worker_1'), isTrue);
      final compactSize = layer.markerSpriteRenderSizeForTesting('worker_1')!;
      expect(compactSize.width, closeTo(46.08, 0.001));
      expect(compactSize.height, closeTo(61.92, 0.001));
      expect(layer.markerWorkBadgeForTesting('worker_1'), '2t');

      layer.sync(parent: parent, units: [worker], selectedUnitId: worker.id);

      expect(layer.markerActionForTesting('worker_1'), UnitSpriteAction.work);
      expect(layer.markerAnimatesSpriteForTesting('worker_1'), isTrue);
      expect(layer.markerCompactWorkVisualForTesting('worker_1'), isTrue);
      expect(layer.markerWorkBadgeForTesting('worker_1'), '2t');

      layer.sync(parent: parent, units: [_worker()], selectedUnitId: worker.id);

      expect(layer.markerActionForTesting('worker_1'), UnitSpriteAction.idle);
      expect(layer.markerCompactWorkVisualForTesting('worker_1'), isFalse);
      final normalSize = layer.markerSpriteRenderSizeForTesting('worker_1')!;
      expect(normalSize.width, 64);
      expect(normalSize.height, 86);
    });

    test('layer applies tactical zoom settings to synced unit markers', () {
      final parent = PositionComponent();
      final layer =
          UnitMarkerLayer(mapData: _map(), colorForPlayer: (_) => 0xFF0000FF)
            ..spriteScale = 0.68
            ..tacticalViewEmphasis = 1
            ..animateIdle = false;
      final unit = _unit(col: 1, row: 1);

      layer.sync(parent: parent, units: [unit], selectedUnitId: null);

      expect(layer.markerSpriteScaleForTesting(unit.id), 0.68);
      expect(layer.markerTacticalViewEmphasisForTesting(unit.id), 1);
      expect(layer.markerAnimateIdleForTesting(unit.id), isFalse);
      expect(layer.markerAnimatesSpriteForTesting(unit.id), isFalse);

      layer.animateMove(
        unitId: unit.id,
        fromCol: 1,
        fromRow: 1,
        steps: const [
          UnitMovementStep(col: 1, row: 1, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
        ],
        onComplete: () {},
      );

      expect(layer.markerActionForTesting(unit.id), UnitSpriteAction.walk);
      expect(layer.markerAnimatesSpriteForTesting(unit.id), isTrue);
    });

    test('settler city founding job animates work pose', () {
      final parent = PositionComponent();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      );
      final settler =
          GameUnit.produced(
            id: 'settler_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.settler,
            col: 1,
            row: 1,
          ).copyWithCityFoundingJob(
            CityFoundingJob(
              center: const CityHex(col: 1, row: 1),
              controlledHexes: const [
                CityHex(col: 1, row: 0),
                CityHex(col: 2, row: 1),
              ],
              remainingTurns: 1,
              totalTurns: 1,
            ),
          );

      layer.sync(parent: parent, units: [settler], selectedUnitId: null);

      expect(layer.markerActionForTesting('settler_1'), UnitSpriteAction.work);
      expect(layer.markerAnimatesSpriteForTesting('settler_1'), isTrue);
      expect(layer.markerCompactWorkVisualForTesting('settler_1'), isTrue);
      expect(layer.markerWorkBadgeForTesting('settler_1'), '1t');
    });

    test('artifact excavation animates work pose with remaining turns', () {
      final parent = PositionComponent();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      );
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
      ).copyWithExcavatingArtifact('artifact_1');

      layer.sync(
        parent: parent,
        units: [warrior],
        selectedUnitId: null,
        artifactExcavationTurnsByUnitId: {warrior.id: 2},
      );

      expect(layer.markerCompactWorkVisualForTesting(warrior.id), isTrue);
      expect(layer.markerWorkBadgeForTesting(warrior.id), '2t');
    });

    test('assigned worker uses compact work pose and shows bonus badge', () {
      final parent = PositionComponent();
      final layer = UnitMarkerLayer(
        mapData: _map(),
        colorForPlayer: (_) => 0xFF0000FF,
      );
      final worker = _worker(
        assignment: const WorkerAssignment(targetHex: CityHex(col: 1, row: 1)),
      );

      layer.sync(parent: parent, units: [worker], selectedUnitId: null);

      expect(layer.markerActionForTesting('worker_1'), UnitSpriteAction.work);
      expect(layer.markerAnimatesSpriteForTesting('worker_1'), isTrue);
      expect(layer.markerCompactWorkVisualForTesting('worker_1'), isTrue);
      final compactSize = layer.markerSpriteRenderSizeForTesting('worker_1')!;
      expect(compactSize.width, closeTo(46.08, 0.001));
      expect(compactSize.height, closeTo(61.92, 0.001));
      expect(layer.markerWorkBadgeForTesting('worker_1'), '+50%');

      layer.sync(parent: parent, units: [worker], selectedUnitId: worker.id);

      expect(layer.markerActionForTesting('worker_1'), UnitSpriteAction.work);
      expect(layer.markerAnimatesSpriteForTesting('worker_1'), isTrue);
      expect(layer.markerCompactWorkVisualForTesting('worker_1'), isTrue);
    });
  });
}
