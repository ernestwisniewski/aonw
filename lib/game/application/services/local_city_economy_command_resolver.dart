import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/accepted_engine_command_interaction_source.dart';
import 'package:aonw/game/application/services/local_city_economy_engine_projection.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class LocalCityEconomyCommandResolution {
  const LocalCityEconomyCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
    required this.accepted,
    this.rejectionReason,
  });

  final CanonicalGameSnapshot snapshot;
  final GameClientState state;
  final List<GameEvent> events;
  final bool accepted;
  final String? rejectionReason;
}

final class LocalCityEconomyCommandResolver {
  const LocalCityEconomyCommandResolver({
    required this.mapView,
    required this.ruleset,
  });

  final MapReadView mapView;
  final GameRuleset ruleset;

  LocalCityEconomyCommandResolution resolve({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (!context.canAct ||
        (!context.hasActor && !currentState.activePlayerCanAct)) {
      return _unchanged(
        baseSnapshot,
        currentState,
        savedAt,
        rejectionReason: 'command_cannot_act',
      );
    }
    final actorPlayerId = _actorPlayerId(
      snapshot: baseSnapshot,
      state: currentState,
      command: command,
      context: context,
    );
    final result = _applyEngine(
      baseSnapshot: baseSnapshot,
      command: command,
      context: context,
      actorPlayerId: actorPlayerId,
    );
    if (result is GameEngineRejected) {
      return _unchanged(
        baseSnapshot,
        currentState,
        savedAt,
        rejectionReason: result.reason,
      );
    }
    if (identical(result.snapshot, baseSnapshot.canonical)) {
      return _unchanged(baseSnapshot, currentState, savedAt, accepted: true);
    }
    final accepted = result as GameEngineAccepted;
    return _acceptedResolution(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: context,
      accepted: accepted,
      actorPlayerId: actorPlayerId,
    );
  }

  LocalCityEconomyCommandResolution _acceptedResolution({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    required GameEngineAccepted accepted,
    required String actorPlayerId,
  }) {
    final interactionSource = acceptedEngineCommandInteractionSource(
      currentState: currentState,
      command: command,
      family: GameEngine.commandFamily(command)!,
      domainActions: accepted.snapshot.domain.actions,
      actorPlayerId: actorPlayerId,
    );
    final projectedState = projectLocalCityEconomyEngineResult(
      currentState: interactionSource,
      result: accepted,
      command: command,
      mapTiles: mapView,
      ruleset: ruleset,
      paceBalance: context.paceBalance,
      actorPlayerId: actorPlayerId,
    );
    return LocalCityEconomyCommandResolution(
      snapshot: baseSnapshot.withEngineResult(
        resultSnapshot: accepted.snapshot,
        savedAt: savedAt,
      ),
      state: projectedState,
      events: accepted.events,
      accepted: true,
    );
  }

  GameEngineResult _applyEngine({
    required CanonicalGameSnapshot baseSnapshot,
    required DomainCommand command,
    required GameCommandContext context,
    required String actorPlayerId,
  }) => const GameEngine().apply(
    snapshot: baseSnapshot.canonical,
    command: command,
    context: GameEngineContext(
      actorPlayerId: actorPlayerId,
      mapView: mapView,
      ruleset: ruleset,
      commandTick: context.commandTick,
    ),
  );

  LocalCityEconomyCommandResolution _unchanged(
    CanonicalGameSnapshot snapshot,
    GameClientState state,
    DateTime savedAt, {
    bool accepted = false,
    String? rejectionReason,
  }) {
    return LocalCityEconomyCommandResolution(
      snapshot: snapshot.withEngineResult(
        resultSnapshot: snapshot.canonical,
        savedAt: savedAt,
      ),
      state: state,
      events: const [],
      accepted: accepted,
      rejectionReason: rejectionReason,
    );
  }

  String _actorPlayerId({
    required CanonicalGameSnapshot snapshot,
    required GameClientState state,
    required DomainCommand command,
    required GameCommandContext context,
  }) {
    final contextActor = context.actorPlayerId;
    if (contextActor != null && contextActor.isNotEmpty) return contextActor;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    return _unitOwner(snapshot, command) ??
        _cityOwner(snapshot, command) ??
        _explicitActor(command) ??
        '';
  }

  String? _unitOwner(CanonicalGameSnapshot snapshot, DomainCommand command) {
    return command is! UnitDomainCommand
        ? null
        : snapshot.domain.units.byId(command.unitId)?.ownerPlayerId;
  }

  String? _cityOwner(CanonicalGameSnapshot snapshot, DomainCommand command) {
    return command is! CityTargetDomainCommand
        ? null
        : snapshot.domain.cities.byId(command.cityId)?.ownerPlayerId;
  }

  String? _explicitActor(DomainCommand command) {
    return switch (command) {
      TradeArtifactCommand(:final playerId) ||
      OpenResourceTradeCommand(:final playerId) ||
      OpenResourceExchangeCommand(:final playerId) => playerId,
      _ => null,
    };
  }
}
