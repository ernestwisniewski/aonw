import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

sealed class UiEffect {
  const UiEffect();
}

sealed class RendererEffect extends UiEffect {
  const RendererEffect();
}

sealed class OverlayEffect extends UiEffect {
  const OverlayEffect();
}

enum HudFeedbackReason {
  attackProtectedByTreaty,
  movementCityOccupied,
  movementEnemyOccupied,
  movementForeignCity,
  movementHiddenRouteTooFar,
  movementBlockedTerrain,
  movementInsufficientUnitMovement,
  movementNoRoute,
}

class ShowHudFeedbackEffect extends OverlayEffect {
  final HudFeedbackReason? reason;
  final String title;
  final String body;

  const ShowHudFeedbackEffect({this.reason, this.title = '', this.body = ''});
}

class AnimateUnitMoveEffect extends RendererEffect {
  final String unitId;
  final int fromCol;
  final int fromRow;
  final List<UnitMovementStep> steps;

  const AnimateUnitMoveEffect({
    required this.unitId,
    required this.fromCol,
    required this.fromRow,
    required this.steps,
  });
}

class PlayCombatAnimationEffect extends RendererEffect {
  final String attackerUnitId;
  final String defenderUnitId;
  final bool attackerKilled;
  final bool defenderKilled;

  const PlayCombatAnimationEffect({
    required this.attackerUnitId,
    required this.defenderUnitId,
    this.attackerKilled = false,
    this.defenderKilled = false,
  });
}

class ShakeCameraEffect extends RendererEffect {
  final double intensity;
  final double duration;

  const ShakeCameraEffect({this.intensity = 8.0, this.duration = 0.28});
}

enum ParticleBurstKind {
  cityFounded,
  hexClaimed,
  technologyResearched,
  unitProduced,
  unitKilled,
  cityAttacked,
}

class SpawnParticleBurstEffect extends RendererEffect {
  final ParticleBurstKind kind;
  final int col;
  final int row;
  final int colorValue;

  const SpawnParticleBurstEffect({
    required this.kind,
    required this.col,
    required this.row,
    required this.colorValue,
  });
}

enum FloatingTextPresentation { plain, bubble }

class ShowFloatingTextEffect extends RendererEffect {
  final String text;
  final int col;
  final int row;
  final int colorValue;
  final Duration delay;
  final FloatingTextPresentation presentation;

  const ShowFloatingTextEffect({
    required this.text,
    required this.col,
    required this.row,
    required this.colorValue,
    this.delay = Duration.zero,
    this.presentation = FloatingTextPresentation.plain,
  });
}

class ShowCityProductionBubbleEffect extends RendererEffect {
  final CityProductionTarget target;
  final int col;
  final int row;
  final int? turnsRemaining;
  final Duration delay;

  const ShowCityProductionBubbleEffect({
    required this.target,
    required this.col,
    required this.row,
    required this.turnsRemaining,
    this.delay = Duration.zero,
  });
}

enum CombatHexAlertKind { attacked, attacker }

class ShowCombatHexAlertEffect extends RendererEffect {
  final String id;
  final String ownerPlayerId;
  final int col;
  final int row;
  final CombatHexAlertKind kind;
  final int? turn;
  final bool ownerSubmittedAtAttack;
  final String? unitId;
  final String? cityId;

  const ShowCombatHexAlertEffect({
    required this.id,
    required this.ownerPlayerId,
    required this.col,
    required this.row,
    required this.kind,
    this.turn,
    this.ownerSubmittedAtAttack = false,
    this.unitId,
    this.cityId,
  });
}

class JumpCameraEffect extends RendererEffect {
  final int col;
  final int row;

  const JumpCameraEffect({required this.col, required this.row});
}

class SmoothCameraEffect extends RendererEffect {
  final int col;
  final int row;
  final double duration;

  const SmoothCameraEffect({
    required this.col,
    required this.row,
    this.duration = 0.48,
  });
}

class GameStateTransition {
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;

  const GameStateTransition({
    required this.state,
    this.events = const [],
    this.uiEffects = const [],
  });
}

extension UiEffectIterable on Iterable<UiEffect> {
  Iterable<RendererEffect> get rendererEffects => whereType<RendererEffect>();

  Iterable<OverlayEffect> get overlayEffects => whereType<OverlayEffect>();
}
