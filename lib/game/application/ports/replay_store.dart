import 'package:aonw/game/application/ports/save_snapshot.dart';

abstract interface class ReplayStore {
  Future<CanonicalGameSnapshot?> initialSnapshot(String saveId);

  Future<void> saveInitialSnapshot(
    String saveId,
    CanonicalGameSnapshot snapshot,
  );

  Future<void> delete(String saveId);
}
