import 'package:aonw/game/application/ports/save_snapshot.dart';

class Snapshot {
  final int offset;
  final SaveSnapshot state;
  final DateTime createdAt;

  const Snapshot({
    required this.offset,
    required this.state,
    required this.createdAt,
  });
}

abstract interface class SnapshotStore {
  Future<Snapshot?> latest(String saveId);

  Future<void> save(String saveId, Snapshot snapshot);
}
