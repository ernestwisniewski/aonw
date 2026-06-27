part of 'technology_discovery_popup_overlay.dart';

TechnologyId? _technologyIdFromName(String? name) {
  if (name == null) return null;
  for (final technologyId in TechnologyId.values) {
    if (technologyId.name == name) return technologyId;
  }
  return null;
}

String _playerName(AppLocalizations l10n, GameSave? save, String playerId) {
  final player = save?.playerById(playerId);
  return player == null ? playerId : GameDisplayNames.player(l10n, player);
}
