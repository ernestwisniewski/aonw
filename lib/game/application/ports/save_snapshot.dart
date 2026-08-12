import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/util/collection_equality.dart';

/// Composes the canonical persistence envelope directly from application
/// inputs. It does not materialize a second authoritative state model.
abstract final class GameSnapshotFactory {
  static CanonicalGameSnapshot create({
    required GameSave save,
    Map<String, int> playerColors = const {},
    Map<String, PlayerCountry> playerCountries = const {},
    Map<String, int> playerGold = const {},
    Map<String, int> playerWarWeariness = const {},
    Map<String, int> playerStabilityNet = const {},
    List<GameUnit> units = const [],
    List<GameCity> cities = const [],
    List<WorldArtifact> artifacts = const [],
    List<FieldImprovement> fieldImprovements = const [],
    TransportNetworkState transportNetwork = TransportNetworkState.empty,
    FogOfWarState fogOfWar = FogOfWarState.empty,
    ResearchState research = ResearchState.empty,
    WonderRegistry wonderRegistry = WonderRegistry.empty,
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
    Set<String> submittedPlayerIds = const {},
    Map<String, int> timeoutStreaksByPlayerId = const {},
    Set<String> afkPlayerIds = const {},
    Set<String> kickedPlayerIds = const {},
    List<IntendedAttack> intendedAttacks = const [],
    DiplomacyState diplomacy = DiplomacyState.empty,
    List<ResourceTradeAgreement> resourceTradeAgreements = const [],
    Map<String, int> dominationHoldTurnsByPlayerId = const {},
    Map<String, int> culturalVictoryHoldTurnsByPlayerId = const {},
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
    DateTime? turnStartedAt,
    int eventLogOffset = 0,
  }) => fromDomainState(
    save: save,
    state: (() {
      return DomainState.snapshot(
        turn: save.turn,
        matchRules: save.matchRules,
        participants: save.players,
        gameMode: save.gameMode,
        turnStatesByPlayerId: save.playerStates,
        submittedPlayerIds: submittedPlayerIds,
        timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
        afkPlayerIds: afkPlayerIds,
        kickedPlayerIds: kickedPlayerIds,
        turnStartedAt: turnStartedAt,
        actions: DomainActionState(
          cityFoundingDraft: cityFoundingDraft,
          pendingAction: pendingAction,
        ),
        playerColors: playerColors,
        playerCountries: playerCountries,
        playerGold: playerGold,
        playerWarWeariness: playerWarWeariness,
        playerStabilityNet: playerStabilityNet,
        units: units,
        cities: cities,
        artifacts: artifacts,
        fieldImprovements: fieldImprovements,
        transportNetwork: transportNetwork,
        fogOfWar: fogOfWar,
        research: research,
        wonderRegistry: wonderRegistry,
        intendedAttacks: intendedAttacks,
        diplomacy: diplomacy,
        resourceTradeAgreements: resourceTradeAgreements,
        dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
        mapObjectiveHoldStatesByObjectiveId:
            mapObjectiveHoldStatesByObjectiveId,
      );
    })(),
    eventLogOffset: eventLogOffset,
  );

  static CanonicalGameSnapshot fromClientState({
    required GameSave save,
    required GameClientState state,
    int eventLogOffset = 0,
  }) => fromDomainState(
    save: save,
    state: state.domain,
    eventLogOffset: eventLogOffset,
  );

  static CanonicalGameSnapshot fromDomainState({
    required GameSave save,
    required DomainState state,
    int eventLogOffset = 0,
  }) => CanonicalGameSnapshot.snapshot(
    domain: _domainAlignedWithSave(state, save),
    metadata: _metadataFromSave(save),
    eventLogOffset: eventLogOffset,
  );
}

DomainState _domainAlignedWithSave(DomainState state, GameSave save) {
  if (state.turn == save.turn &&
      state.matchRules == save.matchRules &&
      listEquals(state.participants, save.players) &&
      state.gameMode == save.gameMode &&
      mapEquals(state.turnStatesByPlayerId, save.playerStates)) {
    return state;
  }
  return state
      .withMatchRules(save.matchRules)
      .copyWith(
        turn: save.turn,
        participants: save.players,
        gameMode: save.gameMode,
        turnStatesByPlayerId: save.playerStates,
      );
}

/// Client-side operations on the one canonical persistence envelope.
extension CanonicalGameSnapshotApplication on CanonicalGameSnapshot {
  CanonicalGameSnapshot get canonical => this;

  GameSave get save =>
      GameSave.fromJson(CanonicalGameSnapshotCodec.encode(this).save);

  Map<String, int> get playerColors => domain.playerColors;
  Map<String, PlayerCountry> get playerCountries => domain.playerCountries;
  Map<String, int> get playerGold => domain.playerGold;
  Map<String, int> get playerWarWeariness => domain.playerWarWeariness;
  Map<String, int> get playerStabilityNet => domain.playerStabilityNet;
  List<GameUnit> get units => domain.units;
  List<GameCity> get cities => domain.cities;
  List<WorldArtifact> get artifacts => domain.artifacts;
  List<FieldImprovement> get fieldImprovements => domain.fieldImprovements;
  TransportNetworkState get transportNetwork => domain.transportNetwork;
  FogOfWarState get fogOfWar => domain.fogOfWar;
  ResearchState get research => domain.research;
  WonderRegistry get wonderRegistry => domain.wonderRegistry;
  DateTime? get persistedTurnStartedAt => domain.turnStartedAt;
  List<Player> get persistedPlayers => domain.participants;
  Map<String, PlayerCountry> get effectivePlayerCountries =>
      domain.playerCountries;

  CanonicalGameSnapshot withClientState(
    GameClientState state, {
    int? eventLogOffset,
  }) => copyWith(
    domain: state.domain
        .withMatchRules(domain.matchRules)
        .copyWith(
          turn: domain.turn,
          participants: domain.participants,
          gameMode: domain.gameMode,
          turnStatesByPlayerId: domain.turnStatesByPlayerId,
        ),
    eventLogOffset: eventLogOffset,
  );

  CanonicalGameSnapshot withSavedAt(DateTime savedAt) {
    return copyWith(metadata: metadata.copyWith(savedAtUtc: savedAt.toUtc()));
  }

  CanonicalGameSnapshot withCamera(CameraState camera, {DateTime? savedAt}) {
    return copyWith(
      metadata: metadata.copyWith(
        savedAtUtc: savedAt?.toUtc(),
        camera: GameSnapshotCamera(x: camera.x, y: camera.y, zoom: camera.zoom),
      ),
    );
  }

  CanonicalGameSnapshot withPlayerUnsubmitted(String playerId) {
    if (!domain.submittedPlayerIds.contains(playerId)) return this;
    return copyWith(
      domain: domain.copyWith(
        submittedPlayerIds: {
          for (final submittedPlayerId in domain.submittedPlayerIds)
            if (submittedPlayerId != playerId) submittedPlayerId,
        },
      ),
    );
  }

  CanonicalGameSnapshot withPlayerFinished(String playerId) {
    final nextSave = save.withPlayerFinished(playerId);
    if (nextSave == save) return this;
    return withGameSave(nextSave);
  }

  CanonicalGameSnapshot withGameSave(GameSave save, {int? eventLogOffset}) =>
      _withGameSave(this, save).copyWith(eventLogOffset: eventLogOffset);

  CanonicalGameSnapshot withReplayPlayerTurnsReset() {
    final playerIds = domain.participants
        .map((player) => player.id)
        .where((playerId) => playerId.isNotEmpty);
    return copyWith(
      domain: domain.copyWith(
        turnStatesByPlayerId: {
          for (final playerId in playerIds) playerId: PlayerTurnState.active,
        },
      ),
    );
  }

  GameClientState toClientState({
    String activePlayerId = '',
    bool activePlayerCanAct = true,
  }) => GameClientState.fromDomain(
    domain: domain,
    activePlayerId: activePlayerId,
    activePlayerCanAct: activePlayerCanAct,
    interaction: InteractionState(
      cityFoundingDraft: domain.actions.cityFoundingDraft,
      pendingAction: domain.actions.pendingAction,
    ),
  );

  CanonicalGameSnapshot withEngineResult({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) => _savedEngineResult(this, resultSnapshot, savedAt);

  CanonicalGameSnapshot withEventLogOffset(int eventLogOffset) {
    return copyWith(eventLogOffset: eventLogOffset);
  }
}

CanonicalGameSnapshot _savedEngineResult(
  CanonicalGameSnapshot source,
  CanonicalGameSnapshot result,
  DateTime savedAt,
) {
  return result.copyWith(
    domain: result.domain == source.domain ? source.domain : result.domain,
    metadata: result.metadata.copyWith(savedAtUtc: savedAt.toUtc()),
  );
}

CanonicalGameSnapshot _withGameSave(
  CanonicalGameSnapshot snapshot,
  GameSave save,
) {
  return snapshot.copyWith(
    domain: snapshot.domain
        .withMatchRules(save.matchRules)
        .copyWith(
          turn: save.turn,
          participants: save.players,
          gameMode: save.gameMode,
          turnStatesByPlayerId: save.playerStates,
        ),
    metadata: _metadataFromSave(save),
  );
}

GameSnapshotMetadata _metadataFromSave(GameSave save) => GameSnapshotMetadata(
  id: save.id,
  schemaVersion: save.schemaVersion,
  name: save.name,
  world: WorldReference(name: save.mapName, source: save.mapSource),
  savedAtUtc: save.savedAt,
  origin: save.origin,
  camera: GameSnapshotCamera(
    x: save.camera.x,
    y: save.camera.y,
    zoom: save.camera.zoom,
  ),
);
