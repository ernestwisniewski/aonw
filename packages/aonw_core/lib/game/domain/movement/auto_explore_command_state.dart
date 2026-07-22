import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// Borrowed slices required by auto-explore command resolution.
///
/// Movement inputs stay composed as their existing canonical view so the
/// higher-level command cannot grow a second copy of that boundary.
final class AutoExploreCommandState {
  const AutoExploreCommandState({
    required this.movement,
    required this.interaction,
  });

  final MovementCommandState movement;
  final PersistedInteractionState interaction;
}
