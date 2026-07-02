part of 'game_event.dart';

final class StabilityBandChangedEvent extends GameEvent {
  const StabilityBandChangedEvent({
    required this.playerId,
    required this.previousBand,
    required this.newBand,
    required this.net,
  });

  final String playerId;
  final StabilityBand previousBand;
  final StabilityBand newBand;
  final int net;
}
