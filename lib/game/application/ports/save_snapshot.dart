import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

class SaveSnapshot {
  final GameSave save;
  final Map<String, int> playerColors;
  final Map<String, PlayerCountry> playerCountries;
  final Map<String, int> playerGold;
  final Map<String, int> playerWarWeariness;
  final Map<String, int> playerStabilityNet;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final FogOfWarState fogOfWar;
  final ResearchState research;
  final WonderRegistry wonderRegistry;
  final GameRuntimeState runtimeState;
  final int eventLogOffset;

  const SaveSnapshot({
    required this.save,
    this.playerColors = const {},
    this.playerCountries = const {},
    this.playerGold = const {},
    this.playerWarWeariness = const {},
    this.playerStabilityNet = const {},
    this.units = const [],
    this.cities = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.fogOfWar = FogOfWarState.empty,
    this.research = ResearchState.empty,
    this.wonderRegistry = WonderRegistry.empty,
    this.runtimeState = GameRuntimeState.empty,
    this.eventLogOffset = 0,
  });

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
    final snapshot = state.immutableSnapshot();
    return SaveSnapshot(
      save: save,
      playerColors: snapshot.playerColors,
      playerCountries: _withSaveCountryDefaults(save, snapshot.playerCountries),
      playerGold: snapshot.playerGold,
      playerWarWeariness: snapshot.playerWarWeariness,
      playerStabilityNet: snapshot.playerStabilityNet,
      units: snapshot.units,
      cities: snapshot.cities,
      artifacts: snapshot.artifacts,
      fieldImprovements: snapshot.fieldImprovements,
      fogOfWar: snapshot.fogOfWar,
      research: snapshot.research,
      wonderRegistry: snapshot.wonderRegistry,
      runtimeState: snapshot.runtimeState,
      eventLogOffset: eventLogOffset,
    );
  }

  PersistentGameState get persistentState => PersistentGameState.snapshot(
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
    runtimeState: runtimeState,
  );

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
    return SaveSnapshot(
      save: save ?? this.save,
      playerColors: playerColors ?? this.playerColors,
      playerCountries: playerCountries ?? this.playerCountries,
      playerGold: playerGold ?? this.playerGold,
      playerWarWeariness: playerWarWeariness ?? this.playerWarWeariness,
      playerStabilityNet: playerStabilityNet ?? this.playerStabilityNet,
      units: units ?? this.units,
      cities: cities ?? this.cities,
      artifacts: artifacts ?? this.artifacts,
      fieldImprovements: fieldImprovements ?? this.fieldImprovements,
      fogOfWar: fogOfWar ?? this.fogOfWar,
      research: research ?? this.research,
      wonderRegistry: wonderRegistry ?? this.wonderRegistry,
      runtimeState: runtimeState ?? this.runtimeState,
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
