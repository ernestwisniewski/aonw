import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';

final class LobbyControllerMemorySessionStore extends NetworkSessionStore {
  LobbyControllerMemorySessionStore({
    required this.displayName,
    this.saveError,
  });

  String displayName;
  final Object? saveError;
  StoredNetworkSession? stored;
  final savedMatchIds = <String?>[];
  var cleared = false;
  var clearCount = 0;

  @override
  Future<StoredNetworkSession?> load() async => stored;

  @override
  Future<String> loadDisplayName() async => displayName;

  @override
  Future<void> save(StoredNetworkSession session) async {
    final error = saveError;
    if (error != null) throw error;
    stored = session;
    displayName = session.displayName;
  }

  @override
  Future<void> saveDisplayName(String displayName) async {
    this.displayName = displayName;
  }

  @override
  Future<void> saveMatchId(String? matchId) async {
    savedMatchIds.add(matchId);
    stored = stored?.copyWith(matchId: matchId);
  }

  @override
  Future<void> clear() async {
    cleared = true;
    clearCount += 1;
    stored = null;
  }
}
