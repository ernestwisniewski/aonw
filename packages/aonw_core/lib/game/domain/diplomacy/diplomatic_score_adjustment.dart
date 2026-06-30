part of 'diplomacy_state.dart';

final class DiplomaticScoreAdjustment {
  const DiplomaticScoreAdjustment({required this.state, required this.entry});

  final DiplomacyState state;
  final DiplomaticScoreEntry? entry;

  bool get applied => entry != null;
}
