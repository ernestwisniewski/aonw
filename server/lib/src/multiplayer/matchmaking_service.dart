import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:aonw_server/src/multiplayer/lobby_presence_policy.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_service.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/match_mutation_outcome.dart';
import 'package:aonw_server/src/multiplayer/match_request_validator.dart';
import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/matchmaking_policies.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_errors.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_limits.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_persistence.dart';
import 'package:aonw_server/src/multiplayer/player_seat_allocator.dart';
import 'package:serverpod/serverpod.dart';

part 'matchmaking_service_creation.dart';
part 'matchmaking_service_transactions.dart';

const _matchmakingLifecycleWireAdapter = MatchLifecycleWireAdapter();

final class MatchmakingService {
  MatchmakingService({
    required PlayerSeatAllocator seatAllocator,
    required MatchStateAccess stateAccess,
    required MatchBroadcaster broadcaster,
    required MatchLifecycleService lifecycle,
    required LobbyPresencePolicy presencePolicy,
    required DateTime Function() nowUtc,
    InviteCodeGenerator? inviteCodeGenerator,
    PresenceGenerationGenerator presenceGenerationGenerator =
        const UuidPresenceGenerationGenerator(),
    MatchRequestValidator requestValidator = const MatchRequestValidator(),
  }) : _seatAllocator = seatAllocator,
       _stateAccess = stateAccess,
       _broadcaster = broadcaster,
       _lifecycle = lifecycle,
       _presencePolicy = presencePolicy,
       _nowUtc = nowUtc,
       _requestValidator = requestValidator,
       _inviteCodeGenerator =
           inviteCodeGenerator ?? SecureInviteCodeGenerator(),
       _presenceGenerationGenerator = presenceGenerationGenerator;

  final PlayerSeatAllocator _seatAllocator;
  final MatchStateAccess _stateAccess;
  final MatchBroadcaster _broadcaster;
  final MatchLifecycleService _lifecycle;
  final LobbyPresencePolicy _presencePolicy;
  final DateTime Function() _nowUtc;
  final MatchRequestValidator _requestValidator;
  final InviteCodeGenerator _inviteCodeGenerator;
  final PresenceGenerationGenerator _presenceGenerationGenerator;

  Future<WireMatch> _createMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
    bool quickplay = false,
    String? inviteCode,
  }) async {
    final matchId = 'match-${const Uuid().v4()}';
    final now = _nowUtc();
    final owner = _createHumanPlayer(
      userIdentifier: userIdentifier,
      displayName: displayName,
      index: 0,
      ready: false,
      requestedCountryId: request.countryId,
      existingPlayers: const [],
    );
    final match = WireMatch(
      id: matchId,
      ownerUserId: userIdentifier,
      name: request.name,
      mapName: request.mapName,
      players: [owner],
      maxPlayers: request.maxPlayers,
      minPlayers: request.minPlayers,
      quickplay: quickplay,
      turn: 0,
      state: _matchmakingLifecycleWireAdapter.encodeState(
        const OpenMatchLifecycleState(),
      ),
      createdAt: now,
      inviteCode: inviteCode,
    );
    final snapshot = WireSnapshot(
      matchId: matchId,
      offset: 0,
      save: const {},
      state: {'phase': 'lobby', 'mapName': request.mapName},
    );
    final ownerLease = _presencePolicy.initialLease(
      userIdentifier: userIdentifier,
      connectionGeneration: _presenceGenerationGenerator.next(),
      nowUtc: now,
    );
    await store.createState(
      StoredMatchState(
        match: match,
        snapshot: snapshot,
        presenceLeases: {userIdentifier: ownerLease},
      ),
    );
    return match;
  }

  Future<MatchMutationOutcome<StoredMatchState>> _joinState({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
    String? displayName,
    String? countryId,
    bool broadcast = true,
  }) async {
    final existingIndex = state.match.players.indexWhere(
      (player) => player.userId == userIdentifier,
    );
    if (existingIndex != -1) {
      return _joinExistingPlayer(
        store: store,
        state: state,
        playerIndex: existingIndex,
        displayName: displayName,
        countryId: countryId,
        broadcast: broadcast,
      );
    }
    return _joinNewPlayer(
      store: store,
      state: state,
      userIdentifier: userIdentifier,
      displayName: displayName,
      countryId: countryId,
      broadcast: broadcast,
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _joinExistingPlayer({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required int playerIndex,
    required String? displayName,
    required String? countryId,
    required bool broadcast,
  }) async {
    final reserved = await _reserveExistingPlayer(
      store: store,
      state: state,
      playerIndex: playerIndex,
    );
    final updated = await _updateExistingPlayerSeat(
      store: store,
      state: reserved,
      playerIndex: playerIndex,
      displayName: displayName,
      countryId: countryId,
      broadcast: false,
    );
    return MatchMutationOutcome(
      updated.value,
      notifications: broadcast
          ? MatchNotificationPlan.broadcastState(updated.value)
          : const MatchNotificationPlan.empty(),
    );
  }

  Future<MatchMutationOutcome<StoredMatchState>> _joinNewPlayer({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required String userIdentifier,
    required String? displayName,
    required String? countryId,
    required bool broadcast,
  }) async {
    if (state.match.players.length >= state.match.maxPlayers) {
      throw multiplayerException('match_full', 'Match is full.');
    }
    final player = _createHumanPlayer(
      userIdentifier: userIdentifier,
      displayName: displayName,
      index: state.match.players.length,
      ready: false,
      requestedCountryId: countryId,
      existingPlayers: state.match.players,
    );
    final updated = state.copyWith(
      match: state.match.copyWith(players: [...state.match.players, player]),
      presenceLeases: {
        ...state.presenceLeases,
        userIdentifier: _presencePolicy.initialLease(
          userIdentifier: userIdentifier,
          connectionGeneration: _presenceGenerationGenerator.next(),
          nowUtc: _nowUtc(),
        ),
      },
    );
    await store.saveState(updated);
    await store.upsertPresenceLease(
      matchId: updated.match.id,
      lease: updated.presenceLeases[userIdentifier]!,
    );
    return MatchMutationOutcome(
      updated,
      notifications: broadcast
          ? MatchNotificationPlan.broadcastState(updated)
          : const MatchNotificationPlan.empty(),
    );
  }

  Future<StoredMatchState> _reserveExistingPlayer({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required int playerIndex,
  }) async {
    final player = state.match.players[playerIndex];
    final currentLease = state.presenceLeases[player.userId];
    if (player.connectionState == WirePlayerConnectionState.connected &&
        currentLease != null &&
        !currentLease.isExpiredAt(_nowUtc())) {
      return state;
    }
    final lease = _presencePolicy.initialLease(
      userIdentifier: player.userId,
      connectionGeneration: _presenceGenerationGenerator.next(),
      nowUtc: _nowUtc(),
    );
    final players = [...state.match.players];
    players[playerIndex] = player.copyWith(
      connectionState: WirePlayerConnectionState.connecting,
    );
    final reserved = state.copyWith(
      match: state.match.copyWith(players: players),
      presenceLeases: {...state.presenceLeases, player.userId: lease},
    );
    await store.saveState(reserved);
    await store.upsertPresenceLease(matchId: state.match.id, lease: lease);
    return reserved;
  }

  Future<MatchMutationOutcome<StoredMatchState>> _updateExistingPlayerSeat({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required int playerIndex,
    String? displayName,
    String? countryId,
    bool broadcast = true,
  }) async {
    final players = state.match.players;
    final player = players[playerIndex];
    var updatedPlayer = player;
    final normalizedName = displayName?.trim();
    if (normalizedName != null &&
        normalizedName.isNotEmpty &&
        normalizedName != player.name) {
      updatedPlayer = updatedPlayer.copyWith(name: normalizedName);
    }
    final requestedCountry = _requestedCountry(countryId);
    if (requestedCountry != null && requestedCountry != player.country) {
      final taken = players.any(
        (other) =>
            other.userId != player.userId && other.country == requestedCountry,
      );
      if (taken) {
        throw multiplayerException(
          'country_unavailable',
          'Selected civilization is already taken.',
        );
      }
      updatedPlayer = updatedPlayer.copyWith(country: requestedCountry);
    }
    if (updatedPlayer == player) return MatchMutationOutcome(state);

    final updatedPlayers = [...players];
    updatedPlayers[playerIndex] = updatedPlayer;
    final updated = state.copyWith(
      match: state.match.copyWith(players: updatedPlayers),
    );
    await store.saveState(updated);
    return MatchMutationOutcome(
      updated,
      notifications: broadcast
          ? MatchNotificationPlan.broadcastState(updated)
          : const MatchNotificationPlan.empty(),
    );
  }

  WirePlayer _createHumanPlayer({
    required String userIdentifier,
    required int index,
    required List<WirePlayer> existingPlayers,
    String? displayName,
    String? requestedCountryId,
    bool ready = false,
  }) {
    try {
      return _seatAllocator.createHumanPlayer(
        userIdentifier: userIdentifier,
        index: index,
        existingPlayers: existingPlayers,
        displayName: displayName,
        requestedCountryId: requestedCountryId,
        ready: ready,
      );
    } on PlayerSeatAllocationFailure catch (error) {
      throw multiplayerException(error.code, error.message);
    }
  }

  PlayerCountry? _requestedCountry(String? countryId) {
    try {
      return _seatAllocator.countryFromId(countryId);
    } on PlayerSeatAllocationFailure catch (error) {
      throw multiplayerException(error.code, error.message);
    }
  }

  void _requireLiveHostedOwner(StoredMatchState state) {
    if (state.match.quickplay ||
        _presencePolicy.hasLiveConnectedOwner(state, nowUtc: _nowUtc())) {
      return;
    }
    throw multiplayerException(
      'match_not_found',
      'The lobby is no longer available.',
    );
  }
}
