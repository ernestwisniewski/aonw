import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_combat_engine_projection.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class LocalCombatCommandResolution {
  const LocalCombatCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
    required this.uiEffects,
    required this.combatAnimations,
  });

  final CanonicalGameSnapshot snapshot;
  final GameClientState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final List<CombatAnimationFact> combatAnimations;
}

final class LocalCombatCommandResolver {
  const LocalCombatCommandResolver({
    required this.mapView,
    required this.ruleset,
  });

  final MapReadView mapView;
  final GameRuleset ruleset;

  LocalCombatCommandResolution resolve({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required AttackHexCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (!context.canAct ||
        (!context.hasActor && !currentState.activePlayerCanAct)) {
      return _unchanged(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        savedAt: savedAt,
      );
    }
    final result = _applyEngine(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      context: context,
    );
    if (result case final GameEngineRejected rejected) {
      return _unchanged(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        savedAt: savedAt,
        uiEffects: _rejectionEffects(
          currentState,
          command,
          rejected.reason,
          context,
        ),
      );
    }
    final accepted = result as GameEngineAccepted;
    return LocalCombatCommandResolution(
      snapshot: baseSnapshot.withCombatEngineProjection(
        resultSnapshot: accepted.snapshot,
        savedAt: savedAt,
      ),
      state: projectLocalCombatEngineResult(
        currentState: currentState,
        result: accepted,
        command: command,
        mapView: mapView,
      ),
      events: accepted.events,
      uiEffects: const [],
      combatAnimations: accepted.combatAnimations,
    );
  }

  GameEngineResult _applyEngine({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required AttackHexCommand command,
    required GameCommandContext context,
  }) {
    return const GameEngine().apply(
      snapshot: baseSnapshot.canonical,
      command: command,
      context: GameEngineContext(
        actorPlayerId: _actorPlayerId(
          snapshot: baseSnapshot,
          state: currentState,
          command: command,
          context: context,
        ),
        mapView: mapView,
        ruleset: ruleset,
        commandTick: context.commandTick,
        combatVisibilityMode: context.ignoreFogOfWar
            ? CombatCommandVisibilityMode.unrestricted
            : CombatCommandVisibilityMode.authoritative,
      ),
    );
  }

  LocalCombatCommandResolution _unchanged({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DateTime savedAt,
    List<UiEffect> uiEffects = const [],
  }) {
    return LocalCombatCommandResolution(
      snapshot: baseSnapshot.withCombatEngineProjection(
        resultSnapshot: baseSnapshot.canonical,
        savedAt: savedAt,
      ),
      state: currentState,
      events: const [],
      uiEffects: uiEffects,
      combatAnimations: const [],
    );
  }

  List<UiEffect> _rejectionEffects(
    GameClientState state,
    AttackHexCommand command,
    String reason,
    GameCommandContext context,
  ) {
    if (reason != 'attack_target_protected_by_treaty' ||
        !context
            .visibilityFor(state)
            .canSeeDynamicAt(command.defenderCol, command.defenderRow)) {
      return const [];
    }
    return const [
      ShowHudFeedbackEffect(reason: HudFeedbackReason.attackProtectedByTreaty),
    ];
  }

  String _actorPlayerId({
    required CanonicalGameSnapshot snapshot,
    required GameClientState state,
    required AttackHexCommand command,
    required GameCommandContext context,
  }) {
    final contextActor = context.actorPlayerId;
    if (contextActor != null && contextActor.isNotEmpty) return contextActor;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    return snapshot.domain.units.byId(command.attackerUnitId)?.ownerPlayerId ??
        '';
  }
}
