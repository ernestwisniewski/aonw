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
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

export 'package:aonw_core/game/domain/state.dart' show CanonicalGameSnapshot;

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
    domain: state.copyWith(
      turn: save.turn,
      matchRules: save.matchRules,
      participants: save.players,
      gameMode: save.gameMode,
      turnStatesByPlayerId: save.playerStates,
    ),
    metadata: _metadataFromSave(save),
    eventLogOffset: eventLogOffset,
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
    domain: state.domain.copyWith(
      turn: domain.turn,
      matchRules: domain.matchRules,
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

  CanonicalGameSnapshot withUnitActionEngineProjection({
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required DomainActionState interaction,
    required DateTime savedAt,
  }) {
    return copyWith(
      domain: domain.copyWith(units: units, artifacts: artifacts),
      metadata: metadata.copyWith(savedAtUtc: savedAt.toUtc()),
      actions: interaction,
    );
  }

  CanonicalGameSnapshot withMovementEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) => _savedEngineResult(resultSnapshot, savedAt);

  CanonicalGameSnapshot withCityEconomyEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) => _savedEngineResult(resultSnapshot, savedAt);

  CanonicalGameSnapshot withCombatEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) => _savedEngineResult(resultSnapshot, savedAt);

  CanonicalGameSnapshot withResearchDiplomacyEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) => _savedEngineResult(resultSnapshot, savedAt);

  CanonicalGameSnapshot withEventLogOffset(int eventLogOffset) {
    return copyWith(eventLogOffset: eventLogOffset);
  }
}

CanonicalGameSnapshot _savedEngineResult(
  CanonicalGameSnapshot result,
  DateTime savedAt,
) {
  return result.copyWith(
    metadata: result.metadata.copyWith(savedAtUtc: savedAt.toUtc()),
  );
}

CanonicalGameSnapshot _withGameSave(
  CanonicalGameSnapshot snapshot,
  GameSave save,
) {
  return snapshot.copyWith(
    domain: snapshot.domain.copyWith(
      turn: save.turn,
      matchRules: save.matchRules,
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
  camera: GameSnapshotCamera(
    x: save.camera.x,
    y: save.camera.y,
    zoom: save.camera.zoom,
  ),
);
