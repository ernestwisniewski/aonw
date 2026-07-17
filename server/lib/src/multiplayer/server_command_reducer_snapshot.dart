part of 'server_command_reducer.dart';

final class DecodedMatchSnapshot {
  const DecodedMatchSnapshot(this.save, this.state, this.eventLogOffset);

  final GameSave save;
  final PersistentGameState state;
  final int eventLogOffset;

  DecodedMatchSnapshot withState(PersistentGameState state) =>
      DecodedMatchSnapshot(save, state, eventLogOffset);
}
