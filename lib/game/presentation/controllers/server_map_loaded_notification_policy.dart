abstract final class ServerMapLoadedNotificationPolicy {
  static bool shouldNotify({
    required bool multiplayer,
    required String saveId,
    required String? sentFor,
    required bool sessionConnected,
    required String? sessionMatchId,
  }) {
    if (!multiplayer || saveId.isEmpty) return false;
    if (sentFor == saveId) return false;
    return sessionConnected && sessionMatchId == saveId;
  }
}
