import 'package:aonw_core/game/domain/combat/combat_command_resolver.dart';
import 'package:aonw_core/game/domain/combat/combat_command_result.dart';
import 'package:aonw_core/game/domain/combat/combat_command_state.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainCombatCommandResult {
  const DomainCombatCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final List<GameEvent> events;
  final String? reason;
}

/// Canonical-state adapter for the state-container-neutral combat resolver.
final class DomainCombatCommandResolver {
  const DomainCombatCommandResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  DomainCombatCommandResult resolve({
    required DomainState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int commandTick,
    required MapTileLookup mapTiles,
    GameRuleset ruleset = GameRuleset.defaults,
    bool ignoreFogOfWar = false,
  }) {
    final result = CombatCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: CombatCommandState(
            units: state.units,
            cities: state.cities,
            artifacts: state.artifacts,
            fogOfWar: state.fogOfWar,
            research: state.research,
            intendedAttacks: state.intendedAttacks,
            diplomacy: state.diplomacy,
            resourceTradeAgreements: state.resourceTradeAgreements,
            playerIds: state.participants.map((player) => player.id),
          ),
          command: command,
          actorPlayerId: actorPlayerId,
          turn: state.turn,
          commandTick: commandTick,
          mapTiles: mapTiles,
          ruleset: ruleset,
          ignoreFogOfWar: ignoreFogOfWar,
        );
    return _apply(state, result);
  }

  static DomainCombatCommandResult _apply(
    DomainState state,
    CombatCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainCombatCommandResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainCombatCommandResult(
      accepted: true,
      state: _stateAfterResult(state, result),
      events: result.events,
    );
  }

  static DomainState _stateAfterResult(
    DomainState state,
    CombatCommandResult result,
  ) {
    final units = _replacement(result.units, state.units);
    final cities = _replacement(result.cities, state.cities);
    final artifacts = _replacement(result.artifacts, state.artifacts);
    final fogOfWar = _replacement(result.fogOfWar, state.fogOfWar);
    final attacks = _replacement(result.intendedAttacks, state.intendedAttacks);
    final diplomacy = _replacement(result.diplomacy, state.diplomacy);
    final trades = _replacement(
      result.resourceTradeAgreements,
      state.resourceTradeAgreements,
    );
    if ([
      units,
      cities,
      artifacts,
      fogOfWar,
      attacks,
      diplomacy,
      trades,
    ].every((replacement) => replacement == null)) {
      return state;
    }
    return state.copyWith(
      units: units,
      cities: cities,
      artifacts: artifacts,
      fogOfWar: fogOfWar,
      intendedAttacks: attacks,
      diplomacy: diplomacy,
      resourceTradeAgreements: trades,
    );
  }
}

T? _replacement<T extends Object>(T next, T current) =>
    identical(next, current) ? null : next;
