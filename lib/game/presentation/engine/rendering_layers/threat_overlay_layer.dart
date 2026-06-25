import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/threat_overlay.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';

class ThreatOverlayLayer extends Component with LayerAttachment {
  ThreatOverlay? _component;
  List<ThreatOverlayHex> _overlayHexes = const [];

  ThreatOverlayLayer() {
    priority = MapPriority.contextOverlay;
  }

  List<ThreatOverlayHex> get overlayHexesForTesting => _overlayHexes;

  void sync({
    required Component parent,
    required GameState state,
    required MapData mapData,
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    bool dimmed = false,
  }) {
    ensureAttachedTo(parent);

    final selectedUnit = state.selectedUnit;
    if (selectedUnit == null || !state.canControlUnit(selectedUnit)) {
      clear();
      return;
    }

    final hexes = _threatenedHexes(
      selectedUnit: selectedUnit,
      state: state,
      mapData: mapData,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    if (hexes.isEmpty) {
      clear();
      return;
    }

    _overlayHexes = hexes;
    final existing = _component;
    if (existing != null) {
      existing.updateHexes(hexes: hexes, dimmed: dimmed);
      return;
    }

    final component = ThreatOverlay(hexes: hexes, dimmed: dimmed);
    _component = component;
    unawaited(Future<void>.value(add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
    _overlayHexes = const [];
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  ThreatOverlay? get componentForTesting => _component;

  List<ThreatOverlayHex> _threatenedHexes({
    required GameUnit selectedUnit,
    required GameState state,
    required MapData mapData,
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    final visibility = state.activePlayerVisibility;
    final threatCounts = <CityHex, int>{};

    for (final enemy in state.unitsVisibleToActivePlayer) {
      if (enemy.ownerPlayerId == selectedUnit.ownerPlayerId) continue;
      if (enemy.isWorking || enemy.movementPoints <= 0) continue;

      final enemyTile = mapData.tileAt(enemy.col, enemy.row);
      if (enemyTile == null) continue;

      final stats = UnitCombatStats.derive(enemy, ruleset: combatRuleset)
          .applyAll(
            CombatModifierCollector.forAttacker(
              unit: enemy,
              tile: enemyTile,
              research: state.research.forPlayer(enemy.ownerPlayerId),
              ruleset: combatRuleset,
              technologyRuleset: technologyRuleset,
            ),
          );
      if (stats.attack <= 0 || stats.range <= 0) continue;

      final origin = HexCoordinate(col: enemy.col, row: enemy.row);
      for (final tile in mapData.tiles) {
        if (visibility.isEnabled && !visibility.canInspectTile(tile)) continue;
        final hex = CityHex(col: tile.col, row: tile.row);
        final distance = HexDistance.between(
          origin,
          HexCoordinate(col: tile.col, row: tile.row),
        );
        if (distance > stats.range) continue;
        threatCounts[hex] = (threatCounts[hex] ?? 0) + 1;
      }
    }

    if (threatCounts.isEmpty) return const [];

    final selectedHex = CityHex(col: selectedUnit.col, row: selectedUnit.row);
    final result =
        [
          for (final entry in threatCounts.entries)
            ThreatOverlayHex(
              hex: entry.key,
              threatCount: entry.value,
              selectedUnitTile: entry.key == selectedHex,
            ),
        ]..sort((a, b) {
          final selectedCompare = b.selectedUnitTile.toString().compareTo(
            a.selectedUnitTile.toString(),
          );
          if (selectedCompare != 0) return selectedCompare;
          final colCompare = a.hex.col.compareTo(b.hex.col);
          if (colCompare != 0) return colCompare;
          return a.hex.row.compareTo(b.hex.row);
        });

    return List.unmodifiable(result);
  }
}
