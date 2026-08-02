import 'package:aonw_core/game/domain/state.dart';

abstract interface class ReplayStore {
  Future<CanonicalGameSnapshot?> initialSnapshot(String saveId);

  Future<void> saveInitialSnapshot(
    String saveId,
    CanonicalGameSnapshot snapshot,
  );

  Future<void> delete(String saveId);
}
