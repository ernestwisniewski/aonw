import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw_core/protocol.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multiplayer_connection_status_provider.freezed.dart';
part 'multiplayer_connection_status_provider.g.dart';

@freezed
abstract class MultiplayerConnectionStatusSnapshot
    with _$MultiplayerConnectionStatusSnapshot {
  const MultiplayerConnectionStatusSnapshot._();

  const factory MultiplayerConnectionStatusSnapshot({
    required String saveId,
    required NetworkConnectionStatus status,
    required DateTime changedAt,
    String? message,
  }) = _MultiplayerConnectionStatusSnapshot;
}

@riverpod
class MultiplayerConnectionStatusNotifier
    extends _$MultiplayerConnectionStatusNotifier {
  @override
  MultiplayerConnectionStatusSnapshot? build() => null;

  void setStatus(MultiplayerConnectionStatusSnapshot snapshot) {
    state = snapshot;
  }

  void clear(String saveId) {
    if (state?.saveId == saveId) state = null;
  }
}

@riverpod
class MultiplayerMatchNotifier extends _$MultiplayerMatchNotifier {
  @override
  Map<String, WireMatch> build() => const {};

  void upsert(WireMatch match) {
    state = {...state, match.id: match};
  }

  void clear(String matchId) {
    if (!state.containsKey(matchId)) return;
    state = {...state}..remove(matchId);
  }
}
