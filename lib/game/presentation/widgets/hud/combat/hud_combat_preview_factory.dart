import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/combat/hud_combat_preview_model.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'hud_combat_preview_resolver.dart';
part 'hud_combat_preview_target_selector.dart';

abstract final class HudCombatPreviewFactory {
  static HudCombatPreview? from({
    required GameState? gameState,
    required MapData mapData,
    required int turn,
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final state = gameState;
    if (state == null ||
        combatRuleset.resolutionMode != CombatResolutionMode.instant) {
      return null;
    }
    final request = _PreviewRequest.create(
      state: state,
      mapData: mapData,
      turn: turn,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    if (request == null) return null;

    final target = _PreviewTargetSelector(request).select();
    if (target == null) return null;
    return _CombatPreviewResolver(request).resolve(target);
  }
}

final class _PreviewRequest {
  const _PreviewRequest({
    required this.state,
    required this.mapData,
    required this.pendingAction,
    required this.attacker,
    required this.attackerTile,
    required this.attackerBase,
    required this.targetSearchRange,
    required this.turn,
    required this.combatRuleset,
    required this.technologyRuleset,
  });

  static _PreviewRequest? create({
    required GameState state,
    required MapData mapData,
    required int turn,
    required CombatRuleset combatRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    final pendingAction = state.pendingAction;
    if (pendingAction is! PendingAttackTargeting) return null;

    final attacker = state.unitById(pendingAction.attackerUnitId);
    if (!_canPreviewAttack(state, attacker)) return null;
    final attackerTile = mapData.tileAt(attacker!.col, attacker.row);
    if (attackerTile == null) return null;

    final attackerBase = UnitCombatStats.derive(
      attacker,
      ruleset: combatRuleset,
    );
    final searchModifiers = CombatModifierCollector.forAttacker(
      unit: attacker,
      tile: attackerTile,
      research: state.research.forPlayer(attacker.ownerPlayerId),
      ruleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    final searchStats = attackerBase.applyAll(searchModifiers);
    if (searchStats.attack <= 0) return null;

    return _PreviewRequest(
      state: state,
      mapData: mapData,
      pendingAction: pendingAction,
      attacker: attacker,
      attackerTile: attackerTile,
      attackerBase: attackerBase,
      targetSearchRange: searchStats.range,
      turn: turn,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  static bool _canPreviewAttack(GameState state, GameUnit? attacker) {
    return attacker != null &&
        state.canControlUnit(attacker) &&
        !attacker.isWorking &&
        attacker.movementPoints > 0;
  }

  final GameState state;
  final MapData mapData;
  final PendingAttackTargeting pendingAction;
  final GameUnit attacker;
  final TileData attackerTile;
  final CombatStats attackerBase;
  final int targetSearchRange;
  final int turn;
  final CombatRuleset combatRuleset;
  final TechnologyRuleset technologyRuleset;
}
