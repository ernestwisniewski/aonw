import 'package:aonw/game/application/ports/save_snapshot.dart';
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
  });

  final SaveSnapshot snapshot;
  final GameState state;
  final List<GameEvent> events;
}

final class LocalCityEconomyCommandResolver {
  const LocalCityEconomyCommandResolver({
    required this.mapView,
    required this.ruleset,
  });

  final MapReadView mapView;
  final GameRuleset ruleset;

  LocalCityEconomyCommandResolution resolve({
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
    final engineSnapshot = baseSnapshot.canonical.copyWith(
      interaction: PersistedInteractionState(
        cityFoundingDraft: currentState.cityFoundingDraft,
        pendingAction: currentState.pendingAction,
      ),
    );
    final result = const GameEngine().apply(
      snapshot: engineSnapshot,
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
      ),
    );
    if (result is GameEngineRejected ||
        identical(result.snapshot, engineSnapshot)) {
      return _unchanged(baseSnapshot, currentState, savedAt);
    }
    final accepted = result as GameEngineAccepted;
    return LocalCityEconomyCommandResolution(
      snapshot: baseSnapshot.withCityEconomyEngineProjection(
        resultSnapshot: accepted.snapshot,
        savedAt: savedAt,
      ),
      state: projectLocalCityEconomyEngineResult(
        currentState: currentState,
        result: accepted,
        command: command,
        mapTiles: mapView,
        ruleset: ruleset,
        paceBalance: context.paceBalance,
      ),
      events: accepted.events,
    );
  }

  LocalCityEconomyCommandResolution _unchanged(
    SaveSnapshot snapshot,
    GameState state,
    DateTime savedAt,
  ) {
    return LocalCityEconomyCommandResolution(
      snapshot: snapshot.withCityEconomyEngineProjection(
        resultSnapshot: snapshot.canonical,
        savedAt: savedAt,
      ),
      state: state,
      events: const [],
    );
  }

  String _actorPlayerId({
    required SaveSnapshot snapshot,
    required GameState state,
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

  String? _unitOwner(SaveSnapshot snapshot, DomainCommand command) {
    return command is! UnitDomainCommand
        ? null
        : snapshot.domain.units.byId(command.unitId)?.ownerPlayerId;
  }

  String? _cityOwner(SaveSnapshot snapshot, DomainCommand command) {
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
