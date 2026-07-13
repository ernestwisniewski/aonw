import 'package:aonw_core/map/domain/map_player_capacity.dart';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';

final class MatchRequestValidator {
  const MatchRequestValidator();

  static const int maxNameLength = 80;
  static const int maxMapNameLength = 64;

  static final RegExp _mapNamePattern = RegExp(r'^[a-z0-9][a-z0-9_-]*$');
  static final RegExp _controlCharacterPattern = RegExp(
    r'[\u0000-\u001f\u007f]',
  );

  CreateMatchRequest validate(
    CreateMatchRequest request, {
    bool enforceMapCapacity = true,
  }) {
    final name = request.name.trim();
    if (name.isEmpty ||
        name.runes.length > maxNameLength ||
        _controlCharacterPattern.hasMatch(name)) {
      throw multiplayerException(
        'invalid_match_name',
        'Match name must contain 1 to $maxNameLength visible characters.',
      );
    }

    final mapName = request.mapName.trim().toLowerCase();
    if (mapName.isEmpty ||
        mapName.length > maxMapNameLength ||
        !_mapNamePattern.hasMatch(mapName)) {
      throw multiplayerException('invalid_map_name', 'Map name is invalid.');
    }
    if (MapPlayerCapacityRules.profileForMapName(mapName) == null) {
      throw multiplayerException(
        'map_not_available',
        'Map is not available on this server.',
      );
    }

    final maxPlayers = request.maxPlayers;
    final minPlayers = request.minPlayers;
    final mapMaxPlayers = enforceMapCapacity
        ? MapPlayerCapacityRules.maxPlayersForMapName(mapName)
        : MapPlayerCapacityRules.absoluteMaxPlayers;
    if (minPlayers < MapPlayerCapacityRules.minPlayers ||
        maxPlayers > mapMaxPlayers ||
        minPlayers > maxPlayers) {
      throw multiplayerException(
        'invalid_player_count',
        'Player count must be between '
            '${MapPlayerCapacityRules.minPlayers} and $mapMaxPlayers.',
      );
    }

    return request.copyWith(name: name, mapName: mapName);
  }
}
