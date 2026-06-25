import 'package:aonw_core/ai/game_view.dart';

final class MctsSearchBypassPolicy {
  const MctsSearchBypassPolicy();

  String? reasonFor(
    GameView view, {
    required bool canBypassDefaultSearch,
    required bool isBatterySaver,
  }) {
    if (!canBypassDefaultSearch) return null;
    if (!isBatterySaver) return null;
    if (!_isLateOrLargeView(view)) return null;
    if (_hasTargetablePendingCityAttackThreat(view)) return null;
    if (view.rememberedTargetableEnemyCities.isNotEmpty) return null;

    final targetableUnits = view.visibleTargetableEnemyUnits;
    if (targetableUnits.isEmpty) return 'no targetable tactical contact';
    if (targetableUnits.length == 1) return 'single-unit cleanup';
    return null;
  }

  bool _hasTargetablePendingCityAttackThreat(GameView view) {
    return view.pendingCityAttackThreats.any(
      (threat) => view.canTargetPlayer(threat.attackerPlayerId),
    );
  }

  bool _isLateOrLargeView(GameView view) {
    return view.turn >= 55 ||
        view.ownUnits.length + view.visibleEnemyUnits.length >= 36 ||
        view.ownCities.length + view.rememberedEnemyCities.length >= 8;
  }
}
