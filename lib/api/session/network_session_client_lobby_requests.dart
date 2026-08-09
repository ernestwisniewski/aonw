part of 'network_session_client.dart';

/// Lobby request mapping kept outside the session lifecycle implementation.
abstract class _NetworkSessionLobbyRequests {
  Future<T> _withToken<T>(
    AuthToken token,
    Future<T> Function(sp.Client client) run,
  );

  Future<WireMatch> createMatch({
    required AuthToken token,
    required CreateMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.createMatch(
        sp.CreateMatchRequest(
          name: request.name,
          mapName: request.mapName,
          maxPlayers: request.maxPlayers,
          minPlayers: request.minPlayers,
          private: false,
          countryId: request.country?.name,
        ),
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  Future<WireMatch> quickplay({
    required AuthToken token,
    required QuickplayMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.quickplay(
        sp.CreateMatchRequest(
          name: 'Quickplay',
          mapName: MapPlayerCapacityRules.quickplayLobbyMapName,
          maxPlayers: 4,
          minPlayers: 2,
          private: false,
          countryId: request.country?.name,
        ),
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  Future<WireMatch> createPrivateMatch({
    required AuthToken token,
    required CreatePrivateMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.createMatch(
        sp.CreateMatchRequest(
          name: 'Private match',
          mapName: request.mapName,
          maxPlayers: MapPlayerCapacityRules.maxPlayersForMapName(
            request.mapName,
          ),
          minPlayers: 2,
          private: true,
          countryId: request.country?.name,
        ),
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  Future<WireMatch> joinPrivateMatch({
    required AuthToken token,
    required JoinPrivateMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.joinPrivateMatch(
        request.inviteCode,
        countryId: request.country?.name,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  Future<WireMatch> joinMatch({
    required AuthToken token,
    required String matchId,
    PlayerCountry? country,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.joinMatch(
        matchId,
        countryId: country?.name,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }
}
