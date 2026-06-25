part of 'technology_discovery_popup_overlay.dart';

TechnologyId? _technologyIdFromName(String? name) {
  if (name == null) return null;
  for (final technologyId in TechnologyId.values) {
    if (technologyId.name == name) return technologyId;
  }
  return null;
}

String _playerName(AppLocalizations l10n, GameSave? save, String playerId) {
  final player = _playerById(save, playerId);
  return player == null ? playerId : GameDisplayNames.player(l10n, player);
}

Player? _playerById(GameSave? save, String playerId) {
  if (save == null) return null;
  for (final player in save.players) {
    if (player.id == playerId) return player;
  }
  return null;
}
