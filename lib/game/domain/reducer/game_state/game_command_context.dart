import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract interface class CommandAuthorizer {
  String? get actorPlayerId;
  bool get canAct;
  bool get hasActor;

  bool canControlUnit(GameState state, GameUnit unit);
  bool canControlCity(GameState state, GameCity city);
}

abstract interface class CommandCombatSeed {
  int get combatSeedTurn;
  int get commandTick;
}

abstract interface class CommandPacing {
  PaceBalance get paceBalance;
}

abstract interface class CommandVisibilityProvider {
  bool get ignoreFogOfWar;

  FogVisibilityQuery visibilityFor(GameState state);
}

/// Runtime metadata for command authorization.
///
/// Hotseat can omit [actorPlayerId] and keep using [GameState.activePlayerId].
/// Online multiplayer can pass the player issuing a command without mutating
/// the shared game state just to validate that single command.
class GameCommandContext
    implements
        CommandAuthorizer,
        CommandCombatSeed,
        CommandPacing,
        CommandVisibilityProvider {
  @override
  final String? actorPlayerId;
  @override
  final bool canAct;
  @override
  final int combatSeedTurn;
  @override
  final int commandTick;
  @override
  final PaceBalance paceBalance;
  @override
  final bool ignoreFogOfWar;

  const GameCommandContext({
    this.actorPlayerId,
    this.canAct = true,
    this.combatSeedTurn = 0,
    this.commandTick = 0,
    this.paceBalance = PaceBalance.unlimited,
    this.ignoreFogOfWar = false,
  });

  @override
  bool get hasActor => actorPlayerId != null && actorPlayerId!.isNotEmpty;

  GameCommandContext copyWith({
    String? actorPlayerId,
    bool? canAct,
    int? combatSeedTurn,
    int? commandTick,
    PaceBalance? paceBalance,
    bool? ignoreFogOfWar,
  }) {
    return GameCommandContext(
      actorPlayerId: actorPlayerId ?? this.actorPlayerId,
      canAct: canAct ?? this.canAct,
      combatSeedTurn: combatSeedTurn ?? this.combatSeedTurn,
      commandTick: commandTick ?? this.commandTick,
      paceBalance: paceBalance ?? this.paceBalance,
      ignoreFogOfWar: ignoreFogOfWar ?? this.ignoreFogOfWar,
    );
  }

  @override
  bool canControlUnit(GameState state, GameUnit unit) {
    if (!canAct) return false;
    if (hasActor) return unit.ownerPlayerId == actorPlayerId;
    return state.canControlUnit(unit);
  }

  @override
  bool canControlCity(GameState state, GameCity city) {
    if (!canAct) return false;
    if (hasActor) return city.ownerPlayerId == actorPlayerId;
    return state.canControlCity(city);
  }

  @override
  FogVisibilityQuery visibilityFor(GameState state) {
    if (ignoreFogOfWar) {
      return FogVisibilityQuery(playerId: '', state: state.fogOfWar);
    }
    if (!hasActor) return state.activePlayerVisibility;
    return FogVisibilityQuery(playerId: actorPlayerId!, state: state.fogOfWar);
  }
}
