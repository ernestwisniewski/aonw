import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class LocalResearchDiplomacyCommandResolution {
  const LocalResearchDiplomacyCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
  });

  final SaveSnapshot snapshot;
  final GameState state;
  final List<GameEvent> events;
}

/// Local composition boundary for authoritative research and diplomacy.
final class LocalResearchDiplomacyCommandResolver {
  const LocalResearchDiplomacyCommandResolver({
    required this.mapView,
    required this.ruleset,
  });

  final MapReadView mapView;
  final GameRuleset ruleset;

  LocalResearchDiplomacyCommandResolution resolve({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (!context.canAct ||
        (!context.hasActor && !currentState.activePlayerCanAct)) {
      return _unchanged(baseSnapshot, currentState, savedAt);
    }
    final engineInput = baseSnapshot.canonical.copyWith(
      interaction: PersistedInteractionState(
        cityFoundingDraft: currentState.cityFoundingDraft,
        pendingAction: currentState.pendingAction,
      ),
    );
    final result = const GameEngine().apply(
      snapshot: engineInput,
      command: command,
      context: GameEngineContext(
        actorPlayerId: _actorPlayerId(command, currentState, context),
        mapView: mapView,
        ruleset: ruleset,
        commandTick: context.commandTick,
      ),
    );
    if (result is GameEngineRejected) {
      return _unchanged(baseSnapshot, currentState, savedAt);
    }
    final accepted = result as GameEngineAccepted;
    return LocalResearchDiplomacyCommandResolution(
      snapshot: baseSnapshot.withResearchDiplomacyEngineProjection(
        resultSnapshot: accepted.snapshot,
        savedAt: savedAt,
      ),
      state: _projectState(currentState, accepted.snapshot),
      events: accepted.events,
    );
  }

  LocalResearchDiplomacyCommandResolution _unchanged(
    SaveSnapshot snapshot,
    GameState state,
    DateTime savedAt,
  ) {
    return LocalResearchDiplomacyCommandResolution(
      snapshot: snapshot.withResearchDiplomacyEngineProjection(
        resultSnapshot: snapshot.canonical,
        savedAt: savedAt,
      ),
      state: state,
      events: const [],
    );
  }

  String _actorPlayerId(
    DomainCommand command,
    GameState state,
    GameCommandContext context,
  ) {
    final contextActor = context.actorPlayerId;
    if (contextActor != null && contextActor.isNotEmpty) return contextActor;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    return switch (command) {
      SelectTechnologyCommand(:final playerId) => playerId,
      DiplomaticCommand(:final playerId) => playerId,
      _ => '',
    };
  }

  GameState _projectState(
    GameState state,
    CanonicalGameSnapshot resultSnapshot,
  ) {
    final domain = resultSnapshot.domain;
    final domainChanged =
        !identical(domain.playerGold, state.playerGold) ||
        !identical(domain.research, state.research) ||
        !identical(domain.diplomacy, state.diplomacy) ||
        !identical(domain.intendedAttacks, state.intendedAttacks) ||
        !identical(
          domain.resourceTradeAgreements,
          state.resourceTradeAgreements,
        );
    final domainState = domainChanged
        ? state.copyWith(
            playerGold: domain.playerGold,
            research: domain.research,
            diplomacy: domain.diplomacy,
            intendedAttacks: domain.intendedAttacks,
            resourceTradeAgreements: domain.resourceTradeAgreements,
          )
        : state;
    final interaction = resultSnapshot.interaction;
    if (domainState.cityFoundingDraft == interaction.cityFoundingDraft &&
        domainState.pendingAction == interaction.pendingAction) {
      return domainState;
    }
    return domainState.copyWithInteraction(
      cityFoundingDraft: interaction.cityFoundingDraft,
      pendingAction: interaction.pendingAction,
    );
  }
}
