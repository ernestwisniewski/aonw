import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/game_snapshot_metadata.dart';
import 'package:aonw_core/game/view/player_view_state.dart';

/// Recipient-scoped snapshot intended only for client sync and rendering.
///
/// This type is deliberately unrelated to [CanonicalGameSnapshot]. It cannot
/// be passed to the authoritative engine and it contains the visible event
/// offset exactly once.
final class RecipientSnapshot {
  factory RecipientSnapshot({
    required GameSnapshotMetadata metadata,
    required PlayerViewState state,
    required int visibleOffset,
  }) {
    if (visibleOffset < 0) {
      throw ArgumentError.value(
        visibleOffset,
        'visibleOffset',
        'Must not be negative',
      );
    }
    return RecipientSnapshot._(
      metadata: metadata,
      state: state,
      visibleOffset: visibleOffset,
    );
  }

  const RecipientSnapshot._({
    required this.metadata,
    required this.state,
    required this.visibleOffset,
  });

  final GameSnapshotMetadata metadata;
  final PlayerViewState state;
  final int visibleOffset;
}
