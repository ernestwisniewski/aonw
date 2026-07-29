import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement/domain_unit_action_command_resolver.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// Applies map-independent unit actions to a canonical snapshot.
final class UnitActionEngineHandler {
  const UnitActionEngineHandler({
    DomainUnitActionCommandResolver resolver =
        const DomainUnitActionCommandResolver(),
  }) : _resolver = resolver;

  final DomainUnitActionCommandResolver _resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    final result = switch (command) {
      final SkipUnitTurnCommand value => _resolver.skipUnitTurn(
        state: snapshot.domain,
        interaction: snapshot.interaction,
        command: value,
        actorPlayerId: context.actorPlayerId,
      ),
      final FortifyUnitCommand value => _resolver.fortifyUnit(
        state: snapshot.domain,
        interaction: snapshot.interaction,
        command: value,
        actorPlayerId: context.actorPlayerId,
      ),
      _ => null,
    };
    if (result == null) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      );
    }
    if (!result.accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final domainChanged = !identical(result.state, snapshot.domain);
    final interactionChanged = !identical(
      result.interaction,
      snapshot.interaction,
    );
    return GameEngineResult.accepted(
      snapshot: domainChanged || interactionChanged
          ? snapshot.copyWith(
              domain: domainChanged ? result.state : null,
              interaction: interactionChanged ? result.interaction : null,
            )
          : snapshot,
    );
  }
}
