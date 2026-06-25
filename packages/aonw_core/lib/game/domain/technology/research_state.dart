import 'package:aonw_core/game/domain/technology/player_research_state.dart';
import 'package:aonw_core/util/collection_equality.dart';

class ResearchState {
  static const empty = ResearchState._(
    players: <String, PlayerResearchState>{},
  );

  final Map<String, PlayerResearchState> players;

  factory ResearchState({Map<String, PlayerResearchState> players = const {}}) {
    return ResearchState._(players: Map.unmodifiable(players));
  }

  const ResearchState._({required this.players});

  factory ResearchState.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as Map<String, dynamic>;
    return ResearchState(
      players: playersJson.map(
        (playerId, value) => MapEntry(
          playerId,
          PlayerResearchState.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'players': {
      for (final entry in _sortedPlayerEntries())
        entry.key: entry.value.toJson(),
    },
  };

  PlayerResearchState forPlayer(String playerId) {
    return players[playerId] ?? PlayerResearchState.empty;
  }

  ResearchState updatePlayer(
    String playerId,
    PlayerResearchState playerResearch,
  ) {
    return ResearchState(players: {...players, playerId: playerResearch});
  }

  Iterable<MapEntry<String, PlayerResearchState>> _sortedPlayerEntries() {
    final entries = players.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  @override
  bool operator ==(Object other) =>
      other is ResearchState && mapEquals(other.players, players);

  @override
  int get hashCode => Object.hashAll(
    _sortedPlayerEntries().map((entry) => Object.hash(entry.key, entry.value)),
  );
}
