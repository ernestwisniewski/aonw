import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/transport/domain_transport_command_resolver.dart';

final class TransportInfrastructureEngineHandler {
  const TransportInfrastructureEngineHandler({
    this.resolver = const DomainTransportCommandResolver(),
  });

  final DomainTransportCommandResolver resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    if (command is! BuildRoadCommand) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      );
    }
    final result = resolver.buildRoad(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      mapTiles: context.mapView,
      paceBalance: context.ruleset.paceBalance,
    );
    return result.accepted
        ? GameEngineResult.accepted(
            snapshot: snapshot.copyWith(domain: result.state),
          )
        : GameEngineResult.rejected(
            snapshot: snapshot,
            reason: result.reason ?? 'command_rejected',
          );
  }
}
