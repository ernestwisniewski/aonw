import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/combat_hex_alert_effect_factory.dart';
import 'package:aonw/game/presentation/services/map_focus_visibility.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class GameEventRendererCombatEffects {
  static const int _damageTextColor = 0xFFF87171;

  static List<RendererEffect> combatResolvedEffects(
    GameState state,
    GameState? previousState,
    CombatResolvedEvent event, {
    String? viewerPlayerId,
    int? turn,
    CombatAnimationFact? animationFact,
  }) {
    final attacker =
        (previousState ?? state).unitById(event.attackerUnitId) ??
        state.unitById(event.attackerUnitId);
    final defender =
        (previousState ?? state).unitById(event.defenderUnitId) ??
        state.unitById(event.defenderUnitId);
    final attackerAlertUnit = state.unitById(event.attackerUnitId);
    final defenderAlertUnit = state.unitById(event.defenderUnitId);
    final defenderCity =
        (previousState ?? state).cityById(event.defenderUnitId) ??
        state.cityById(event.defenderUnitId);

    final attackerVisible = _unitCanRenderTransientAtEither(
      state,
      previousState,
      attacker,
      viewerPlayerId: viewerPlayerId,
    );
    final combatVisible =
        attackerVisible ||
        (defender != null &&
            _canRenderTransientAtEither(
              state,
              previousState,
              defender.col,
              defender.row,
              viewerPlayerId: viewerPlayerId,
            )) ||
        (defenderCity != null &&
            _canRenderTransientAtEither(
              state,
              previousState,
              defenderCity.center.col,
              defenderCity.center.row,
              viewerPlayerId: viewerPlayerId,
            ));
    if (!combatVisible) return const [];

    final effects = <RendererEffect>[
      ..._combatAnimationEffects(event, animationFact),
      const ShakeCameraEffect(),
    ];
    var defenderDamage = 0;
    var attackerDamage = 0;
    for (final step in event.outcome.steps) {
      switch (step) {
        case AttackStep(:final damage):
          defenderDamage += damage;
        case RetaliationStep(:final damage):
          attackerDamage += damage;
        case ModifierAppliedStep() || RollStep():
          break;
      }
    }

    if (attackerAlertUnit != null &&
        _canRenderTransientAtEither(
          state,
          previousState,
          attackerAlertUnit.col,
          attackerAlertUnit.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        CombatHexAlertEffectFactory.build(
          id: 'attacker:${event.attackerUnitId}',
          unitId: event.attackerUnitId,
          ownerPlayerId: attackerAlertUnit.ownerPlayerId,
          col: attackerAlertUnit.col,
          row: attackerAlertUnit.row,
          kind: CombatHexAlertKind.attacker,
          state: state,
          turn: turn,
        ),
      );
    }

    if (defenderAlertUnit != null &&
        _canRenderTransientAtEither(
          state,
          previousState,
          defenderAlertUnit.col,
          defenderAlertUnit.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        CombatHexAlertEffectFactory.build(
          id: 'defender:${event.defenderUnitId}',
          unitId: event.defenderUnitId,
          ownerPlayerId: defenderAlertUnit.ownerPlayerId,
          col: defenderAlertUnit.col,
          row: defenderAlertUnit.row,
          kind: CombatHexAlertKind.attacked,
          state: state,
          turn: turn,
        ),
      );
    } else if (defenderCity != null &&
        _canRenderTransientAtEither(
          state,
          previousState,
          defenderCity.center.col,
          defenderCity.center.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        CombatHexAlertEffectFactory.build(
          id: 'city:${defenderCity.id}',
          cityId: defenderCity.id,
          ownerPlayerId: defenderCity.ownerPlayerId,
          col: defenderCity.center.col,
          row: defenderCity.center.row,
          kind: CombatHexAlertKind.attacked,
          state: state,
          turn: turn,
        ),
      );
    }

    if (defenderDamage > 0) {
      if (defender != null &&
          _canRenderTransientAtEither(
            state,
            previousState,
            defender.col,
            defender.row,
            viewerPlayerId: viewerPlayerId,
          )) {
        effects.add(_damageTextEffect(defender, defenderDamage));
      } else if (defenderCity != null) {
        _addCityDamageEffects(
          effects,
          state,
          previousState,
          defenderCity,
          defenderDamage,
          viewerPlayerId: viewerPlayerId,
          focusBeforeCombat: !attackerVisible,
        );
      }
    }

    if (attackerDamage > 0 &&
        attacker != null &&
        _canRenderTransientAtEither(
          state,
          previousState,
          attacker.col,
          attacker.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(_damageTextEffect(attacker, attackerDamage));
    }

    final previousDefender = previousState?.unitById(event.defenderUnitId);
    final nextDefender = state.unitById(event.defenderUnitId);
    if (event.outcome.defenderRetreated &&
        previousDefender != null &&
        nextDefender != null &&
        (previousDefender.col != nextDefender.col ||
            previousDefender.row != nextDefender.row) &&
        _canRenderTransientAtEither(
          state,
          previousState,
          previousDefender.col,
          previousDefender.row,
          viewerPlayerId: viewerPlayerId,
        )) {
      effects.add(
        AnimateUnitMoveEffect(
          unitId: event.defenderUnitId,
          fromCol: previousDefender.col,
          fromRow: previousDefender.row,
          steps: [
            UnitMovementStep(
              col: nextDefender.col,
              row: nextDefender.row,
              enterCost: 0,
              cumulativeCost: 0,
            ),
          ],
        ),
      );
    }

    return effects;
  }

  static void _addCityDamageEffects(
    List<RendererEffect> effects,
    GameState state,
    GameState? previousState,
    GameCity city,
    int damage, {
    String? viewerPlayerId,
    required bool focusBeforeCombat,
  }) {
    final cityVisible = _canRenderTransientAtEither(
      state,
      previousState,
      city.center.col,
      city.center.row,
      viewerPlayerId: viewerPlayerId,
    );
    if (focusBeforeCombat &&
        _isViewerCity(state, city, viewerPlayerId: viewerPlayerId)) {
      effects.insert(
        0,
        SmoothCameraEffect(
          col: city.center.col,
          row: city.center.row,
          duration: 0.36,
        ),
      );
    }
    if (cityVisible) {
      effects
        ..add(
          SpawnParticleBurstEffect(
            kind: ParticleBurstKind.cityAttacked,
            col: city.center.col,
            row: city.center.row,
            colorValue: _damageTextColor,
          ),
        )
        ..add(_cityDamageTextEffect(city, damage));
    }
  }

  static ShowFloatingTextEffect _damageTextEffect(GameUnit unit, int damage) {
    return ShowFloatingTextEffect(
      text: '-$damage HP',
      col: unit.col,
      row: unit.row,
      colorValue: _damageTextColor,
    );
  }

  static ShowFloatingTextEffect _cityDamageTextEffect(
    GameCity city,
    int damage,
  ) {
    return ShowFloatingTextEffect(
      text: '-$damage HP',
      col: city.center.col,
      row: city.center.row,
      colorValue: _damageTextColor,
    );
  }

  static bool _isViewerCity(
    GameState state,
    GameCity city, {
    String? viewerPlayerId,
  }) {
    final playerId = viewerPlayerId ?? state.activePlayerId;
    return playerId.isNotEmpty && city.ownerPlayerId == playerId;
  }

  static bool _canRenderTransientAt(
    GameState state,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    return MapFocusVisibility.canRenderTransientAt(
      state,
      col,
      row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static bool _unitCanRenderTransientAtEither(
    GameState state,
    GameState? previousState,
    GameUnit? unit, {
    String? viewerPlayerId,
  }) {
    if (unit == null) return false;
    return _canRenderTransientAtEither(
      state,
      previousState,
      unit.col,
      unit.row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static bool _canRenderTransientAtEither(
    GameState state,
    GameState? previousState,
    int col,
    int row, {
    String? viewerPlayerId,
  }) {
    if (_canRenderTransientAt(
      state,
      col,
      row,
      viewerPlayerId: viewerPlayerId,
    )) {
      return true;
    }
    if (previousState == null) return false;
    return _canRenderTransientAt(
      previousState,
      col,
      row,
      viewerPlayerId: viewerPlayerId,
    );
  }

  static int colorForPlayer(GameState state, String playerId) {
    return PlayerColorTheme.resolveValue(
      state.colorForPlayer(playerId) ?? Player.palette.first,
    );
  }
}

List<RendererEffect> _combatAnimationEffects(
  CombatResolvedEvent event,
  CombatAnimationFact? animationFact,
) {
  if (animationFact == null) return const [];
  return [_combatAnimationEffect(event, animationFact)];
}

PlayCombatAnimationEffect _combatAnimationEffect(
  CombatResolvedEvent event,
  CombatAnimationFact animationFact,
) {
  return PlayCombatAnimationEffect(
    attackerUnitId: event.attackerUnitId,
    defenderUnitId: event.defenderUnitId,
    attackerFromCol: animationFact.attackerFromCol,
    attackerFromRow: animationFact.attackerFromRow,
    attackerToCol: animationFact.attackerToCol,
    attackerToRow: animationFact.attackerToRow,
    attackerKilled: event.outcome.attackerKilled,
    defenderKilled: event.outcome.defenderKilled,
    defenderRetaliated: event.outcome.steps.any(
      (step) => step is RetaliationStep,
    ),
  );
}
