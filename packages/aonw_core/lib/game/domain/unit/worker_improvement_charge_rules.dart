import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

abstract final class WorkerImprovementChargeRules {
  static const int defaultWorkerCharges = 1;

  static int startingChargesFor(GameUnitType type) {
    return type == GameUnitType.worker ? defaultWorkerCharges : 0;
  }

  static int normalize({required GameUnitType type, required int? charges}) {
    final resolved = charges ?? startingChargesFor(type);
    if (type != GameUnitType.worker) return 0;
    return resolved < 0 ? 0 : resolved;
  }

  static int remainingAfterImprovement(int currentCharges) {
    if (currentCharges <= 0) return 0;
    return currentCharges - 1;
  }
}
