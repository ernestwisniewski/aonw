part of 'diplomacy_state.dart';

abstract final class DiplomaticGoldGiftRules {
  static const int minimumAmount = 5;
  static const int cooldownTurns = 5;
  static const int maxRelationDelta = 12;

  static int relationDeltaFor(int amount) {
    if (amount < minimumAmount) return 0;
    final scaled = amount ~/ minimumAmount;
    return scaled > maxRelationDelta ? maxRelationDelta : scaled;
  }
}
