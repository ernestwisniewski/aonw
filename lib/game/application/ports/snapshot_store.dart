import 'package:aonw_core/game/domain/state.dart';

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
