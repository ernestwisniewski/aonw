import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_command_context.freezed.dart';

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
@freezed
abstract class GameCommandContext
    with _$GameCommandContext
    implements
        CommandAuthorizer,
        CommandCombatSeed,
        CommandPacing,
        CommandVisibilityProvider {
  const GameCommandContext._();

  const factory GameCommandContext({
    String? actorPlayerId,
    @Default(true) bool canAct,
    @Default(0) int combatSeedTurn,
    @Default(0) int commandTick,
    @Default(PaceBalance.unlimited) PaceBalance paceBalance,
    @Default(VictoryRules.standard) VictoryRules victoryRules,
    @Default(false) bool ignoreFogOfWar,
  }) = _GameCommandContext;

  @override
  bool get hasActor => actorPlayerId != null && actorPlayerId!.isNotEmpty;

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
