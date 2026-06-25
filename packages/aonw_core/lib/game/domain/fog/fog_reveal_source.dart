import 'package:aonw_core/game/domain/hex.dart';

class FogRevealSource {
  final String playerId;
  final HexCoordinate origin;
  final int range;
  final int observerHeight;

  const FogRevealSource({
    required this.playerId,
    required this.origin,
    required this.range,
    this.observerHeight = 0,
  });
}
