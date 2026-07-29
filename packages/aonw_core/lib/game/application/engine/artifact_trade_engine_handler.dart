import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/artifact/domain_artifact_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade/domain_resource_trade_command_resolver.dart';

/// Applies authoritative artifact and resource-trade commands.
final class ArtifactTradeEngineHandler {
  const ArtifactTradeEngineHandler({
    this.artifactResolver = const DomainArtifactCommandResolver(),
    this.resourceTradeResolver = const DomainResourceTradeCommandResolver(),
  });

  final DomainArtifactCommandResolver artifactResolver;
  final DomainResourceTradeCommandResolver resourceTradeResolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    return switch (command) {
      final StartArtifactExcavationCommand value => _artifactResult(
        snapshot,
        artifactResolver.startExcavation(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
        ),
      ),
      final StoreArtifactInCityCommand value => _artifactResult(
        snapshot,
        artifactResolver.storeInCity(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
        ),
      ),
      final TradeArtifactCommand value => _artifactResult(
        snapshot,
        artifactResolver.tradeArtifact(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
        ),
      ),
      final OpenResourceTradeCommand value => _resourceTradeResult(
        snapshot,
        resourceTradeResolver.openGoldForResourceTrade(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
          mapTiles: context.mapView,
        ),
      ),
      final OpenResourceExchangeCommand value => _resourceTradeResult(
        snapshot,
        resourceTradeResolver.openResourceForResourceTrade(
          state: snapshot.domain,
          command: value,
          actorPlayerId: context.actorPlayerId,
          mapTiles: context.mapView,
        ),
      ),
      _ => GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      ),
    };
  }

  GameEngineResult _artifactResult(
    CanonicalGameSnapshot snapshot,
    DomainArtifactCommandResult result,
  ) => _result(
    snapshot,
    accepted: result.accepted,
    state: result.state,
    reason: result.reason,
  );

  GameEngineResult _resourceTradeResult(
    CanonicalGameSnapshot snapshot,
    DomainResourceTradeCommandResult result,
  ) => _result(
    snapshot,
    accepted: result.accepted,
    state: result.state,
    reason: result.reason,
  );

  GameEngineResult _result(
    CanonicalGameSnapshot snapshot, {
    required bool accepted,
    required DomainState state,
    required String? reason,
  }) {
    if (!accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: reason ?? 'command_rejected',
      );
    }
    return GameEngineResult.accepted(
      snapshot: identical(state, snapshot.domain)
          ? snapshot
          : snapshot.copyWith(domain: state),
    );
  }
}
