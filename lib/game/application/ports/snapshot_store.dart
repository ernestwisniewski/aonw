import 'package:aonw/game/application/ports/save_snapshot.dart';

class Snapshot {
  final CanonicalGameSnapshot state;
  final DateTime createdAt;

  const Snapshot({required this.state, required this.createdAt});

  int get offset => state.eventLogOffset;
}

abstract interface class SnapshotStore {
  Future<Snapshot?> latest(String saveId);

  Future<void> save(String saveId, Snapshot snapshot);
}
