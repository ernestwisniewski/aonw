part of 'game_command.dart';

final class StartArtifactExcavationCommand extends GameCommand {
  const StartArtifactExcavationCommand(this.unitId);

  final String unitId;

  @override
  bool operator ==(Object other) =>
      other is StartArtifactExcavationCommand && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(StartArtifactExcavationCommand, unitId);
}

final class StoreArtifactInCityCommand extends GameCommand {
  const StoreArtifactInCityCommand(this.unitId, {this.cityId});

  final String unitId;
  final String? cityId;

  @override
  bool operator ==(Object other) =>
      other is StoreArtifactInCityCommand &&
      other.unitId == unitId &&
      other.cityId == cityId;

  @override
  int get hashCode => Object.hash(StoreArtifactInCityCommand, unitId, cityId);
}

final class TradeArtifactCommand extends GameCommand {
  const TradeArtifactCommand({
    required this.playerId,
    required this.targetPlayerId,
    required this.offeredArtifactId,
    this.requestedArtifactId,
    this.offeredGold = 0,
    this.requestedGold = 0,
  });

  final String playerId;
  final String targetPlayerId;
  final String offeredArtifactId;
  final String? requestedArtifactId;
  final int offeredGold;
  final int requestedGold;

  @override
  bool operator ==(Object other) =>
      other is TradeArtifactCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId &&
      other.offeredArtifactId == offeredArtifactId &&
      other.requestedArtifactId == requestedArtifactId &&
      other.offeredGold == offeredGold &&
      other.requestedGold == requestedGold;

  @override
  int get hashCode => Object.hash(
    TradeArtifactCommand,
    playerId,
    targetPlayerId,
    offeredArtifactId,
    requestedArtifactId,
    offeredGold,
    requestedGold,
  );
}
