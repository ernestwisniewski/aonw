part of 'local_command_transport_test.dart';

class _MemorySnapshotStore implements SnapshotStore {
  Snapshot? latestSnapshot;
  var accessCalls = 0;

  @override
  Future<Snapshot?> latest(String saveId) async {
    accessCalls++;
    return latestSnapshot;
  }

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    accessCalls++;
    latestSnapshot = snapshot;
  }
}

final class _MemoryReplayStore implements ReplayStore {
  _MemoryReplayStore(this.snapshot);

  SaveSnapshot? snapshot;

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async => snapshot;

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> delete(String saveId) async {
    snapshot = null;
  }
}
