import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';

abstract final class CombatHexAlertEffectFactory {
  static ShowCombatHexAlertEffect build({
    required String id,
    required String ownerPlayerId,
    required int col,
    required int row,
    required CombatHexAlertKind kind,
    required GameState state,
    required int? turn,
    String? unitId,
    String? cityId,
  }) {
    return ShowCombatHexAlertEffect(
      id: id,
      unitId: unitId,
      cityId: cityId,
      ownerPlayerId: ownerPlayerId,
      col: col,
      row: row,
      kind: kind,
      turn: turn,
      ownerSubmittedAtAttack: state.submittedPlayerIds.contains(ownerPlayerId),
    );
  }
}
