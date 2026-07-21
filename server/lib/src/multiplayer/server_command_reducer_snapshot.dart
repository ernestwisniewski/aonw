part of 'server_command_reducer.dart';

final class DecodedMatchSnapshot {
  DecodedMatchSnapshot(this.save, this.state, this.eventLogOffset);

  final GameSave save;
  final PersistentGameState state;
  final int eventLogOffset;

  late final CanonicalGameSnapshot _canonicalSnapshotValue = _canonicalSnapshot(
    save: save,
    state: state,
    eventLogOffset: eventLogOffset,
  );

  CanonicalGameSnapshot toCanonical() => _canonicalSnapshotValue;

  DecodedMatchSnapshot withState(PersistentGameState state) =>
      DecodedMatchSnapshot(save, state, eventLogOffset);
}
