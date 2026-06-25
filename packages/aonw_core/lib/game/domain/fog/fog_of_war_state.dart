import 'package:aonw_core/game/domain/fog/fog_visibility.dart';
import 'package:aonw_core/game/domain/fog/player_fog_of_war.dart';
import 'package:aonw_core/game/domain/hex.dart';

class FogOfWarState {
  final Map<String, PlayerFogOfWar> players;

  const FogOfWarState({this.players = const {}});

  static const empty = FogOfWarState();

  factory FogOfWarState.fromJson(List<dynamic> json) {
    final fogs = json.map(
      (value) => PlayerFogOfWar.fromJson(value as Map<String, dynamic>),
    );
    return FogOfWarState(players: {for (final fog in fogs) fog.playerId: fog});
  }

  List<Map<String, dynamic>> toJson() {
    final values = players.values.toList()
      ..sort((a, b) => a.playerId.compareTo(b.playerId));
    return values.map((fog) => fog.toJson()).toList();
  }

  Iterable<String> get playerIds => players.keys;

  PlayerFogOfWar fogForPlayer(String playerId) {
    return players[playerId] ?? PlayerFogOfWar(playerId: playerId);
  }

  FogVisibility visibilityFor(String playerId, HexCoordinate hex) {
    return fogForPlayer(playerId).visibilityFor(hex);
  }

  bool isKnown(String playerId, HexCoordinate hex) {
    return fogForPlayer(playerId).isKnown(hex);
  }

  bool isVisible(String playerId, HexCoordinate hex) {
    return fogForPlayer(playerId).isVisible(hex);
  }

  FogOfWarState updatePlayer(PlayerFogOfWar fog) {
    return FogOfWarState(players: {...players, fog.playerId: fog});
  }

  FogOfWarState updatePlayers(Iterable<PlayerFogOfWar> fogs) {
    final updated = Map<String, PlayerFogOfWar>.of(players);
    for (final fog in fogs) {
      updated[fog.playerId] = fog;
    }
    return FogOfWarState(players: updated);
  }

  @override
  bool operator ==(Object other) {
    if (other is! FogOfWarState || other.players.length != players.length) {
      return false;
    }
    for (final entry in players.entries) {
      if (other.players[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    final sortedKeys = players.keys.toList()..sort();
    return Object.hashAll([
      for (final key in sortedKeys) Object.hash(key, players[key]),
    ]);
  }
}
