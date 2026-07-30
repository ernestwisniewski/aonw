import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade/domain_resource_trade_command_resolver.dart';
import 'package:aonw_core/game/domain/unit.dart';

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
    events: result.accepted
        ? _artifactEvents(snapshot.domain, result.state)
        : const [],
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
    List<DomainEvent> events = const [],
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
      events: events,
    );
  }

  List<DomainEvent> _artifactEvents(DomainState previous, DomainState next) {
    final events = <DomainEvent>[];
    for (final artifact in next.artifacts) {
      final before = _artifactOf(previous, artifact.id);
      if (before == null || before.location == artifact.location) continue;
      final location = artifact.location;
      if (location.isBeingExcavated) {
        final unit = _unitOf(next, location.unitId ?? '');
        events.add(
          ArtifactExcavationStartedEvent(
            artifactId: artifact.id,
            ownerPlayerId: unit?.ownerPlayerId ?? '',
            unitId: location.unitId ?? '',
            col: location.col ?? unit?.col ?? 0,
            row: location.row ?? unit?.row ?? 0,
          ),
        );
      } else if (location.isCarried) {
        final unit = _unitOf(next, location.unitId ?? '');
        events.add(
          ArtifactCarriedEvent(
            artifactId: artifact.id,
            ownerPlayerId: unit?.ownerPlayerId ?? '',
            unitId: location.unitId ?? '',
            col: unit?.col ?? 0,
            row: unit?.row ?? 0,
          ),
        );
      } else if (location.isStored) {
        final city = _cityOf(next, location.cityId ?? '');
        final previousUnit = _carrierOf(previous, artifact.id);
        events.add(
          ArtifactStoredEvent(
            artifactId: artifact.id,
            ownerPlayerId: city?.ownerPlayerId ?? '',
            unitId: previousUnit?.id,
            cityId: location.cityId ?? '',
            col: city?.center.col ?? 0,
            row: city?.center.row ?? 0,
          ),
        );
      }
    }
    return events;
  }

  GameUnit? _carrierOf(DomainState state, String artifactId) {
    for (final unit in state.units) {
      if (unit.carriedArtifactId == artifactId) return unit;
    }
    return null;
  }

  WorldArtifact? _artifactOf(DomainState state, String artifactId) {
    for (final artifact in state.artifacts) {
      if (artifact.id == artifactId) return artifact;
    }
    return null;
  }

  GameUnit? _unitOf(DomainState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  GameCity? _cityOf(DomainState state, String cityId) {
    for (final city in state.cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }
}
