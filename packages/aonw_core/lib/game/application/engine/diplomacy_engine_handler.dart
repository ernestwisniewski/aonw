import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/domain_diplomacy_command_resolver.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Applies authoritative diplomacy commands.
final class DiplomacyEngineHandler {
  const DiplomacyEngineHandler({
    this.resolver = const DomainDiplomacyCommandResolver(),
  });

  final DomainDiplomacyCommandResolver resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    if (command is! DiplomaticCommand) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      );
    }
    final result = resolver.resolve(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      turn: snapshot.domain.turn,
    );
    if (!result.accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final domain = result.state == snapshot.domain
        ? snapshot.domain
        : result.state;
    return GameEngineResult.accepted(
      snapshot: identical(domain, snapshot.domain)
          ? snapshot
          : snapshot.copyWith(domain: domain),
      events: [for (final event in result.events) event as DomainEvent],
    );
  }
}
