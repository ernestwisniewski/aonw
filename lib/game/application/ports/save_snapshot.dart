import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

const _saveSnapshotAdapter = LegacyGameSnapshotAdapter();

/// Frozen, lossless application boundary for persisted and wire snapshots.
///
/// The raw save and persistent state remain the source of serialization.
/// [canonical] is a memoized semantic view and may infer values, such as a
/// multiplayer turn start, that were intentionally absent from the raw input.
final class SaveSnapshot {
  final GameSave save;
  final PersistentGameState _rawState;
  final int eventLogOffset;

  factory SaveSnapshot({
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
    GameRuntimeState runtimeState = GameRuntimeState.empty,
    int eventLogOffset = 0,
  }) {
    return SaveSnapshot._owned(
      save: _ownedSave(save),
      rawState: PersistentGameState.snapshot(
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
        runtimeState: runtimeState,
      ),
      eventLogOffset: eventLogOffset,
    );
  }

  SaveSnapshot._owned({
    required this.save,
    required PersistentGameState rawState,
    required this.eventLogOffset,
  }) : _rawState = rawState;

  factory SaveSnapshot.fromGameState({
    required GameSave save,
    required GameState state,
    int eventLogOffset = 0,
  }) {
    return SaveSnapshot.fromPersistentState(
      save: save,
      state: state.toPersistentState(),
      eventLogOffset: eventLogOffset,
    );
  }

  factory SaveSnapshot.fromPersistentState({
    required GameSave save,
    required PersistentGameState state,
    int eventLogOffset = 0,
  }) {
    return SaveSnapshot._owned(
      save: _ownedSave(save),
      rawState: state.immutableSnapshot(),
      eventLogOffset: eventLogOffset,
    );
  }

  factory SaveSnapshot.fromCanonical(CanonicalGameSnapshot snapshot) {
    final legacy = _saveSnapshotAdapter.toLegacy(snapshot);
    final candidate = SaveSnapshot._owned(
      save: _ownedSave(legacy.save),
      rawState: legacy.state.immutableSnapshot(),
      eventLogOffset: legacy.eventLogOffset,
    );
    if (candidate.canonical != snapshot) {
      throw ArgumentError.value(
        snapshot,
        'snapshot',
        'Canonical snapshot cannot be represented losslessly by legacy '
            'save/state',
      );
    }
    return candidate;
  }

  /// Exact owned state received from persistence or transport.
  ///
  /// Codecs must serialize this view instead of [persistentState] or
  /// [canonical], both of which may contain semantic roster defaults.
  PersistentGameState get rawPersistentState => _rawState;

  /// Legacy semantic projection retained for callers that expect countries
  /// from save metadata to fill missing raw roster entries.
  late final PersistentGameState persistentState = _stateWithCountryDefaults(
    save,
    _rawState,
  );

  Map<String, int> get playerColors => _rawState.playerColors;
  Map<String, PlayerCountry> get playerCountries => _rawState.playerCountries;
  Map<String, int> get playerGold => _rawState.playerGold;
  Map<String, int> get playerWarWeariness => _rawState.playerWarWeariness;
  Map<String, int> get playerStabilityNet => _rawState.playerStabilityNet;
  List<GameUnit> get units => _rawState.units;
  List<GameCity> get cities => _rawState.cities;
  List<WorldArtifact> get artifacts => _rawState.artifacts;
  List<FieldImprovement> get fieldImprovements => _rawState.fieldImprovements;
  FogOfWarState get fogOfWar => _rawState.fogOfWar;
  ResearchState get research => _rawState.research;
  WonderRegistry get wonderRegistry => _rawState.wonderRegistry;
  GameRuntimeState get runtimeState => _rawState.runtimeState;

  /// Exact persisted turn start without the canonical multiplayer fallback.
  DateTime? get persistedTurnStartedAt => _rawState.runtimeState.turnStartedAt;

  late final CanonicalGameSnapshot canonical = _saveSnapshotAdapter.toCanonical(
    save: save,
    state: _rawState,
    eventLogOffset: eventLogOffset,
  );

  GameSnapshotMetadata get metadata => canonical.metadata;
  DomainState get domain => canonical.domain;
  MatchSessionState get session => canonical.session;
  PersistedInteractionState get interaction => canonical.interaction;

  SaveSnapshot withGameState(GameState state) {
    return SaveSnapshot.fromGameState(
      save: save,
      state: state,
      eventLogOffset: eventLogOffset,
    );
  }

  GameState toGameState({
    String activePlayerId = '',
    bool activePlayerCanAct = true,
  }) {
    return GameState(
      playerColors: playerColors,
      playerCountries: effectivePlayerCountries,
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
      diplomacy: runtimeState.diplomacy,
      activePlayerId: activePlayerId,
      activePlayerCanAct: activePlayerCanAct,
      submittedPlayerIds: runtimeState.submittedPlayerIds,
      timeoutStreaksByPlayerId: runtimeState.timeoutStreaksByPlayerId,
      afkPlayerIds: runtimeState.afkPlayerIds,
      kickedPlayerIds: runtimeState.kickedPlayerIds,
      intendedAttacks: runtimeState.intendedAttacks,
      resourceTradeAgreements: runtimeState.resourceTradeAgreements,
      dominationHoldTurnsByPlayerId: runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          runtimeState.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          runtimeState.mapObjectiveHoldStatesByObjectiveId,
      turnStartedAt: runtimeState.turnStartedAt,
      interaction: GameInteractionState(
        cityFoundingDraft: runtimeState.cityFoundingDraft,
        pendingAction: runtimeState.pendingAction,
      ),
    );
  }

  SaveSnapshot copyWith({
    GameSave? save,
    Map<String, int>? playerColors,
    Map<String, PlayerCountry>? playerCountries,
    Map<String, int>? playerGold,
    Map<String, int>? playerWarWeariness,
    Map<String, int>? playerStabilityNet,
    List<GameUnit>? units,
    List<GameCity>? cities,
    List<WorldArtifact>? artifacts,
    List<FieldImprovement>? fieldImprovements,
    FogOfWarState? fogOfWar,
    ResearchState? research,
    WonderRegistry? wonderRegistry,
    GameRuntimeState? runtimeState,
    int? eventLogOffset,
  }) {
    return SaveSnapshot._owned(
      save: save == null ? this.save : _ownedSave(save),
      rawState: _rawState.copyWith(
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
        runtimeState: runtimeState,
      ),
      eventLogOffset: eventLogOffset ?? this.eventLogOffset,
    );
  }

  Map<String, PlayerCountry> get effectivePlayerCountries =>
      _withSaveCountryDefaults(save, playerCountries);

  static Map<String, PlayerCountry> _withSaveCountryDefaults(
    GameSave save,
    Map<String, PlayerCountry> playerCountries,
  ) {
    return {
      for (final player in save.players) player.id: player.country,
      ...playerCountries,
    };
  }
}

PersistentGameState _stateWithCountryDefaults(
  GameSave save,
  PersistentGameState rawState,
) {
  final effectiveCountries = SaveSnapshot._withSaveCountryDefaults(
    save,
    rawState.playerCountries,
  );
  if (_sameCountryEntries(effectiveCountries, rawState.playerCountries)) {
    return rawState;
  }
  return rawState.copyWith(playerCountries: effectiveCountries);
}

bool _sameCountryEntries(
  Map<String, PlayerCountry> left,
  Map<String, PlayerCountry> right,
) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

GameSave _ownedSave(GameSave source) {
  return GameSave(
    id: source.id,
    schemaVersion: source.schemaVersion,
    name: source.name,
    mapName: source.mapName,
    mapSource: source.mapSource,
    turn: source.turn,
    playerStates: Map.unmodifiable(source.playerStates),
    savedAt: source.savedAt,
    camera: source.camera,
    matchRules: source.matchRules,
    players: List.unmodifiable(source.players),
    gameMode: source.gameMode,
  );
}
