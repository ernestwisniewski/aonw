import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state.dart';

class PersistentDiplomacyResult {
  const PersistentDiplomacyResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}
