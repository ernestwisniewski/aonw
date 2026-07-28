part of 'game_event_notification_message.dart';

String _playerName(
  AppLocalizations l10n,
  _GameEventPlayerRoster? roster,
  String playerId,
) {
  final player = roster?.playerById(playerId);
  return player == null ? playerId : GameDisplayNames.player(l10n, player);
}

String _playerCountryName(
  AppLocalizations l10n,
  _GameEventPlayerRoster? roster,
  GameState state,
  String? playerId,
) {
  if (playerId == null || playerId.isEmpty) return '';
  final player = roster?.playerById(playerId);
  if (player != null) {
    return GameDisplayNames.playerCountry(l10n, player.country);
  }
  final stateCountry = state.playerCountries[playerId];
  if (stateCountry != null) {
    return GameDisplayNames.playerCountry(l10n, stateCountry);
  }
  return _playerName(l10n, roster, playerId);
}

PlayerCountry _playerCountry(
  _GameEventPlayerRoster? roster,
  GameState state,
  String playerId,
) {
  return roster?.playerById(playerId)?.country ??
      state.countryForPlayer(playerId);
}

final class _GameEventPlayerRoster {
  final Map<String, Player> _playersById;

  _GameEventPlayerRoster(Iterable<Player> players)
    : _playersById = {for (final player in players) player.id: player};

  Player? playerById(String playerId) => _playersById[playerId];
}
