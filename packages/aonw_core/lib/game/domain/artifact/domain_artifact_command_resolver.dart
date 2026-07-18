import 'package:aonw_core/game/domain/artifact/artifact_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

final class DomainArtifactCommandResult {
  const DomainArtifactCommandResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral artifact resolver.
final class DomainArtifactCommandResolver {
  const DomainArtifactCommandResolver();

  DomainArtifactCommandResult startExcavation({
    required DomainState state,
    required StartArtifactExcavationCommand command,
    required String actorPlayerId,
  }) {
    return _applyUnit(
      state,
      ArtifactCommandResolver.startExcavation(
        units: state.units,
        artifacts: state.artifacts,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  DomainArtifactCommandResult storeInCity({
    required DomainState state,
    required StoreArtifactInCityCommand command,
    required String actorPlayerId,
  }) {
    return _applyUnit(
      state,
      ArtifactCommandResolver.storeInCity(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  DomainArtifactCommandResult tradeArtifact({
    required DomainState state,
    required TradeArtifactCommand command,
    required String actorPlayerId,
  }) {
    return _applyTrade(
      state,
      ArtifactCommandResolver.tradeArtifact(
        cities: state.cities,
        artifacts: state.artifacts,
        playerGold: state.playerGold,
        diplomacy: state.diplomacy,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  static DomainArtifactCommandResult _applyUnit(
    DomainState state,
    ArtifactUnitCommandResult result,
  ) {
    if (!result.accepted) return _reject(state, result.reason);
    return DomainArtifactCommandResult(
      accepted: true,
      state: state.copyWith(units: result.units, artifacts: result.artifacts),
    );
  }

  static DomainArtifactCommandResult _applyTrade(
    DomainState state,
    ArtifactTradeCommandResult result,
  ) {
    if (!result.accepted) return _reject(state, result.reason);
    return DomainArtifactCommandResult(
      accepted: true,
      state: state.copyWith(
        artifacts: result.artifacts,
        playerGold: result.playerGold,
      ),
    );
  }

  static DomainArtifactCommandResult _reject(
    DomainState state,
    String? reason,
  ) {
    return DomainArtifactCommandResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }
}
