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

final class ShowWorkerAutomationNoTargetEffect extends ShowHudFeedbackEffect {
  const ShowWorkerAutomationNoTargetEffect() : super();
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
  final int? attackerFromCol;
  final int? attackerFromRow;
  final int? attackerToCol;
  final int? attackerToRow;
  final bool attackerKilled;
  final bool defenderKilled;
  final bool defenderRetaliated;

  const PlayCombatAnimationEffect({
    required this.attackerUnitId,
    required this.defenderUnitId,
    this.attackerFromCol,
    this.attackerFromRow,
    this.attackerToCol,
    this.attackerToRow,
    this.attackerKilled = false,
    this.defenderKilled = false,
    this.defenderRetaliated = true,
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

sealed class FloatingTextAnchor {
  const FloatingTextAnchor();

  const factory FloatingTextAnchor.tile() = TileFloatingTextAnchor;

  const factory FloatingTextAnchor.unit(String unitId) = UnitFloatingTextAnchor;

  const factory FloatingTextAnchor.city(String cityId) = CityFloatingTextAnchor;
}

final class TileFloatingTextAnchor extends FloatingTextAnchor {
  const TileFloatingTextAnchor();
}

final class UnitFloatingTextAnchor extends FloatingTextAnchor {
  final String unitId;

  const UnitFloatingTextAnchor(this.unitId) : assert(unitId != '');
}

final class CityFloatingTextAnchor extends FloatingTextAnchor {
  final String cityId;

  const CityFloatingTextAnchor(this.cityId) : assert(cityId != '');
}

class ShowFloatingTextEffect extends RendererEffect {
  final String text;
  final int col;
  final int row;
  final int colorValue;
  final Duration delay;
  final FloatingTextPresentation presentation;
  final FloatingTextAnchor anchor;

  const ShowFloatingTextEffect({
    required this.text,
    required this.col,
    required this.row,
    required this.colorValue,
    this.delay = Duration.zero,
    this.presentation = FloatingTextPresentation.plain,
    this.anchor = const FloatingTextAnchor.tile(),
  });
}

class ShowCityProductionBubbleEffect extends RendererEffect {
  final String cityId;
  final CityProductionTarget target;
  final int col;
  final int row;
  final int? turnsRemaining;
  final Duration delay;

  const ShowCityProductionBubbleEffect({
    required this.cityId,
    required this.target,
    required this.col,
    required this.row,
    required this.turnsRemaining,
    this.delay = Duration.zero,
  });

  ShowCityProductionBubbleEffect.forCity({
    required GameCity city,
    required this.target,
    required this.turnsRemaining,
    this.delay = Duration.zero,
  }) : cityId = city.id,
       col = city.center.col,
       row = city.center.row;
}

enum CombatHexAlertKind { attacked, attacker, fortificationThreat }

class ShowCombatHexAlertEffect extends RendererEffect {
  final String id;
  final String ownerPlayerId;
  final int col;
  final int row;
  final CombatHexAlertKind kind;
  final int? turn;
  final double? expiresAfter;
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
    this.expiresAfter,
    this.ownerSubmittedAtAttack = false,
    this.unitId,
    this.cityId,
  });
}

/// Briefly marks the full map hex of an action target.
///
/// This is transient presentation state. It is never persisted or sent as a
/// domain event.
class ShowActionTargetFocusEffect extends RendererEffect {
  final int col;
  final int row;
  final Duration duration;

  const ShowActionTargetFocusEffect({
    required this.col,
    required this.row,
    this.duration = const Duration(seconds: 2),
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
  final GameClientState state;
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
