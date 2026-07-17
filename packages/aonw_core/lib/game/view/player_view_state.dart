import 'package:aonw_core/game/domain/state.dart';

/// Recipient-specific game state that is safe to serialize at a player edge.
///
/// The projected persistent state deliberately remains private. Consumers can
/// carry this nominal proof or encode it for the wire, but cannot feed the
/// redacted view back into canonical game-state processing.
final class PlayerViewState {
  PlayerViewState({
    required PersistentGameState projectedState,
    required this.recipientPlayerId,
  }) : _projectedState = projectedState.immutableSnapshot();

  final String recipientPlayerId;
  final PersistentGameState _projectedState;
}

/// The only wire serializer for [PlayerViewState].
final class PlayerViewStateWireCodec {
  const PlayerViewStateWireCodec();

  Map<String, dynamic> encode(PlayerViewState state) {
    return state._projectedState.toJson();
  }
}
