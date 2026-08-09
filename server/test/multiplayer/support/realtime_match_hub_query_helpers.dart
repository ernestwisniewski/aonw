import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

bool isActiveTestMatch(WireMatch match) =>
    match.state == 'open' || match.state == 'running';

bool isAfterRunningTestCursor(WireMatch match, RunningMatchCursor? cursor) {
  if (cursor == null) return true;
  final createdAtOrder = match.createdAt.compareTo(cursor.createdAt);
  return createdAtOrder > 0 ||
      (createdAtOrder == 0 && match.id.compareTo(cursor.publicId) > 0);
}

int compareTestMatchesNewestFirst(WireMatch first, WireMatch second) {
  final createdAtOrder = second.createdAt.compareTo(first.createdAt);
  if (createdAtOrder != 0) return createdAtOrder;
  return second.id.compareTo(first.id);
}
