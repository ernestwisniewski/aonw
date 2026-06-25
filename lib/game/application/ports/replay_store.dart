import 'package:aonw/game/application/ports/save_snapshot.dart';

abstract interface class ReplayStore {
  Future<SaveSnapshot?> initialSnapshot(String saveId);

  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot);

  Future<void> delete(String saveId);
}
