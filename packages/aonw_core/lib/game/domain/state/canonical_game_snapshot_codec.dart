import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/state/game_snapshot_metadata.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

part 'canonical_game_snapshot_json.dart';

/// Current-version JSON representation used by persistence and transport.
///
/// The event offset occurs exactly once. The current wire/persistence halves
/// are decoded directly into a canonical snapshot; no second game state is
/// materialized.
final class CanonicalGameSnapshotData {
  CanonicalGameSnapshotData({
    required Map<String, dynamic> save,
    required Map<String, dynamic> state,
    required this.eventLogOffset,
  }) : save = _ownedJsonMap(save),
       state = _ownedJsonMap(state) {
    if (eventLogOffset < 0) {
      throw ArgumentError.value(
        eventLogOffset,
        'eventLogOffset',
        'Must not be negative',
      );
    }
  }

  final Map<String, dynamic> save;
  final Map<String, dynamic> state;
  final int eventLogOffset;
}

/// Fail-closed current-version snapshot codec.
abstract final class CanonicalGameSnapshotCodec {
  /// Decodes the canonical domain portion without creating a persistence
  /// envelope. This is the single JSON-to-domain mapping used by fixtures and
  /// current-version protocol adapters.
  static DomainState decodeDomainState(
    Map<String, dynamic> state, {
    int turn = 0,
    MatchRules matchRules = MatchRules.standard,
    GameMode gameMode = GameMode.hotSeat,
    Map<String, PlayerTurnState> turnStatesByPlayerId = const {},
  }) {
    final decoded = _decodeState(state);
    final participants = _participantsWithoutSave(decoded);
    return _domainFromDecoded(
      decoded,
      turn: turn,
      matchRules: matchRules,
      participants: participants,
      gameMode: gameMode,
      turnStatesByPlayerId: turnStatesByPlayerId,
    );
  }

  static CanonicalGameSnapshot decode(CanonicalGameSnapshotData data) {
    final save = GameSave.fromJson(_mutableJsonMap(data.save));
    final decoded = _decodeState(data.state);
    final participants = _participants(save, decoded);
    return CanonicalGameSnapshot.snapshot(
      domain: _domainFromDecoded(
        decoded,
        turn: save.turn,
        matchRules: save.matchRules,
        participants: participants,
        gameMode: save.gameMode,
        turnStatesByPlayerId: save.playerStates,
        turnStartedAt: decoded.turnStartedAt,
      ),
      metadata: GameSnapshotMetadata(
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
        origin: save.origin,
      ),
      eventLogOffset: data.eventLogOffset,
    );
  }

  static CanonicalGameSnapshotData encode(CanonicalGameSnapshot snapshot) {
    final domain = snapshot.domain;
    final metadata = snapshot.metadata;
    return CanonicalGameSnapshotData(
      save: GameSave(
        id: metadata.id,
        schemaVersion: metadata.schemaVersion,
        name: metadata.name,
        mapName: metadata.world.name,
        mapSource: metadata.world.source,
        turn: domain.turn,
        playerStates: domain.turnStatesByPlayerId,
        savedAt: metadata.savedAtUtc,
        camera: CameraState(
          x: metadata.camera.x,
          y: metadata.camera.y,
          zoom: metadata.camera.zoom,
        ),
        matchRules: domain.matchRules,
        players: domain.participants,
        gameMode: domain.gameMode,
        origin: metadata.origin,
      ).toJson(),
      state: encodeDomainState(domain),
      eventLogOffset: snapshot.eventLogOffset,
    );
  }

  static Map<String, dynamic> encodeDomainState(DomainState domain) => {
    'playerColors': {...domain.playerColors},
    'playerCountries': domain.playerCountries.map(
      (playerId, country) => MapEntry(playerId, country.name),
    ),
    'playerGold': {...domain.playerGold},
    'playerWarWeariness': {...domain.playerWarWeariness},
    'playerStabilityNet': {...domain.playerStabilityNet},
    if (domain.strategicResources.byPlayerId.isNotEmpty)
      'strategicResources': domain.strategicResources.toJson(),
    if (!domain.initialResourceDistribution.isEmpty)
      'initialResourceDistribution': domain.initialResourceDistribution
          .toJson(),
    'units': [for (final unit in domain.units) unit.toJson()],
    'cities': [for (final city in domain.cities) city.toJson()],
    'artifacts': [for (final artifact in domain.artifacts) artifact.toJson()],
    'fieldImprovements': [
      for (final improvement in domain.fieldImprovements) improvement.toJson(),
    ],
    'transportNetwork': domain.transportNetwork.toJson(),
    'fogOfWar': domain.fogOfWar.toJson(),
    'research': domain.research.toJson(),
    'lifecycle': _encodeLifecycle(domain: domain),
    if (domain.wonderRegistry.completedBy.isNotEmpty)
      'wonderRegistry': domain.wonderRegistry.toJson(),
  };
}

DomainState _domainFromDecoded(
  _DecodedState decoded, {
  required int turn,
  required MatchRules matchRules,
  required List<Player> participants,
  required GameMode gameMode,
  required Map<String, PlayerTurnState> turnStatesByPlayerId,
  DateTime? turnStartedAt,
}) => DomainState.snapshot(
  turn: turn,
  matchRules: matchRules,
  participants: participants,
  gameMode: gameMode,
  turnStatesByPlayerId: turnStatesByPlayerId,
  submittedPlayerIds: decoded.submittedPlayerIds,
  timeoutStreaksByPlayerId: decoded.timeoutStreaksByPlayerId,
  afkPlayerIds: decoded.afkPlayerIds,
  kickedPlayerIds: decoded.kickedPlayerIds,
  turnStartedAt: turnStartedAt ?? decoded.turnStartedAt,
  actions: DomainActionState(
    cityFoundingDraft: decoded.cityFoundingDraft,
    pendingAction: decoded.pendingAction,
  ),
  playerGold: decoded.playerGold,
  playerWarWeariness: decoded.playerWarWeariness,
  playerStabilityNet: decoded.playerStabilityNet,
  strategicResources: decoded.strategicResources,
  initialResourceDistribution: decoded.initialResourceDistribution,
  units: decoded.units,
  cities: decoded.cities,
  artifacts: decoded.artifacts,
  fieldImprovements: decoded.fieldImprovements,
  transportNetwork: decoded.transportNetwork,
  fogOfWar: decoded.fogOfWar,
  research: decoded.research,
  wonderRegistry: decoded.wonderRegistry,
  intendedAttacks: decoded.intendedAttacks,
  diplomacy: decoded.diplomacy,
  resourceTradeAgreements: decoded.resourceTradeAgreements,
  dominationHoldTurnsByPlayerId: decoded.dominationHoldTurnsByPlayerId,
  culturalVictoryHoldTurnsByPlayerId:
      decoded.culturalVictoryHoldTurnsByPlayerId,
  mapObjectiveHoldStatesByObjectiveId:
      decoded.mapObjectiveHoldStatesByObjectiveId,
);

final class _DecodedState {
  const _DecodedState({
    required this.playerColors,
    required this.playerCountries,
    required this.playerGold,
    required this.playerWarWeariness,
    required this.playerStabilityNet,
    required this.strategicResources,
    required this.initialResourceDistribution,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fieldImprovements,
    required this.transportNetwork,
    required this.fogOfWar,
    required this.research,
    required this.wonderRegistry,
    required this.cityFoundingDraft,
    required this.pendingAction,
    required this.submittedPlayerIds,
    required this.timeoutStreaksByPlayerId,
    required this.afkPlayerIds,
    required this.kickedPlayerIds,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.dominationHoldTurnsByPlayerId,
    required this.culturalVictoryHoldTurnsByPlayerId,
    required this.mapObjectiveHoldStatesByObjectiveId,
    required this.resourceTradeAgreements,
    required this.turnStartedAt,
  });

  final Map<String, int> playerColors;
  final Map<String, PlayerCountry> playerCountries;
  final Map<String, int> playerGold;
  final Map<String, int> playerWarWeariness;
  final Map<String, int> playerStabilityNet;
  final StrategicResourceAccounts strategicResources;
  final InitialResourceDistribution initialResourceDistribution;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final TransportNetworkState transportNetwork;
  final FogOfWarState fogOfWar;
  final ResearchState research;
  final WonderRegistry wonderRegistry;
  final CityFoundingDraft? cityFoundingDraft;
  final PendingPlayerAction? pendingAction;
  final Set<String> submittedPlayerIds;
  final Map<String, int> timeoutStreaksByPlayerId;
  final Set<String> afkPlayerIds;
  final Set<String> kickedPlayerIds;
  final List<IntendedAttack> intendedAttacks;
  final DiplomacyState diplomacy;
  final Map<String, int> dominationHoldTurnsByPlayerId;
  final Map<String, int> culturalVictoryHoldTurnsByPlayerId;
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final DateTime? turnStartedAt;
}

_DecodedState _decodeState(Map<String, dynamic> state) {
  final runtime = _optionalJsonObject(state['lifecycle']);
  return _DecodedState(
    playerColors: _intMap(state['playerColors']),
    playerCountries: _countryMap(state['playerCountries']),
    playerGold: _intMap(state['playerGold']),
    playerWarWeariness: _intMap(state['playerWarWeariness']),
    playerStabilityNet: _intMap(state['playerStabilityNet']),
    strategicResources: StrategicResourceAccounts.fromJson(
      state['strategicResources'],
    ),
    initialResourceDistribution: InitialResourceDistribution.fromJson(
      state['initialResourceDistribution'],
    ),
    units: _decodeJsonList(state['units'], GameUnit.fromJson),
    cities: _decodeJsonList(state['cities'], GameCity.fromJson),
    artifacts: _decodeJsonList(state['artifacts'], WorldArtifact.fromJson),
    fieldImprovements: _decodeJsonList(
      state['fieldImprovements'],
      FieldImprovement.fromJson,
    ),
    transportNetwork: TransportNetworkState.fromJson(state['transportNetwork']),
    fogOfWar: _decodeFogOfWar(state['fogOfWar']),
    research: _decodeResearch(state['research']),
    wonderRegistry: WonderRegistry.fromJson(state['wonderRegistry']),
    cityFoundingDraft: _decodeOptional(
      runtime['cityFoundingDraft'],
      CityFoundingDraft.fromJson,
    ),
    pendingAction: _decodeOptional(
      runtime['pendingAction'],
      PendingPlayerAction.fromJson,
    ),
    submittedPlayerIds: _stringSet(runtime['submittedPlayerIds']),
    timeoutStreaksByPlayerId: _intMap(runtime['timeoutStreaksByPlayerId']),
    afkPlayerIds: _stringSet(runtime['afkPlayerIds']),
    kickedPlayerIds: _stringSet(runtime['kickedPlayerIds']),
    intendedAttacks: _decodeJsonList(
      runtime['intendedAttacks'],
      IntendedAttack.fromJson,
    ),
    diplomacy: DiplomacyState.fromJson(runtime['diplomacy']),
    dominationHoldTurnsByPlayerId: _intMap(
      runtime['dominationHoldTurnsByPlayerId'],
    ),
    culturalVictoryHoldTurnsByPlayerId: _intMap(
      runtime['culturalVictoryHoldTurnsByPlayerId'],
    ),
    mapObjectiveHoldStatesByObjectiveId: _decodeObjectiveHolds(
      runtime['mapObjectiveHoldStates'],
    ),
    resourceTradeAgreements: _decodeJsonList(
      runtime['resourceTradeAgreements'],
      ResourceTradeAgreement.fromJson,
    ),
    turnStartedAt: _dateTime(runtime['turnStartedAt']),
  );
}

List<Player> _participants(GameSave save, _DecodedState state) {
  final participants = [
    for (final player in save.players)
      player.copyWith(
        colorValue: state.playerColors[player.id] ?? player.colorValue,
        country: state.playerCountries[player.id] ?? player.country,
      ),
  ];
  final included = participants.map((player) => player.id).toSet();
  final missing = _knownPlayerIds(save, state).difference(included).toList()
    ..sort();
  for (final playerId in missing) {
    participants.add(
      Player(
        id: playerId,
        name: playerId,
        colorValue:
            state.playerColors[playerId] ??
            Player.palette[participants.length % Player.palette.length],
        country: state.playerCountries[playerId] ?? PlayerCountry.poland,
      ),
    );
  }
  return participants;
}

List<Player> _participantsWithoutSave(_DecodedState state) {
  final ordered = _statePlayerIds(state).toList()..sort();
  return [
    for (var index = 0; index < ordered.length; index++)
      Player(
        id: ordered[index],
        name: ordered[index],
        colorValue:
            state.playerColors[ordered[index]] ??
            Player.palette[index % Player.palette.length],
        country: state.playerCountries[ordered[index]] ?? PlayerCountry.poland,
      ),
  ];
}

Set<String> _knownPlayerIds(GameSave save, _DecodedState state) {
  return <String>{...save.playerStates.keys, ..._statePlayerIds(state)}
    ..removeWhere((playerId) => playerId.isEmpty);
}

Set<String> _statePlayerIds(_DecodedState state) {
  return <String>{
    ...state.playerColors.keys,
    ...state.playerCountries.keys,
    ...state.playerGold.keys,
    ...state.playerWarWeariness.keys,
    ...state.playerStabilityNet.keys,
    ...state.strategicResources.byPlayerId.keys,
    ...state.fogOfWar.playerIds,
    ...state.research.players.keys,
    ...state.submittedPlayerIds,
    ...state.timeoutStreaksByPlayerId.keys,
    ...state.afkPlayerIds,
    ...state.kickedPlayerIds,
    ...state.wonderRegistry.completedBy.values,
    ...state.dominationHoldTurnsByPlayerId.keys,
    ...state.culturalVictoryHoldTurnsByPlayerId.keys,
    for (final unit in state.units) unit.ownerPlayerId,
    for (final city in state.cities) city.ownerPlayerId,
    for (final city in state.cities) ?city.foundingOwnerPlayerId,
    for (final segment in state.transportNetwork.segments)
      segment.builtByPlayerId,
    for (final relation in state.diplomacy.relations.values) ...[
      relation.playerAId,
      relation.playerBId,
    ],
    for (final attack in state.intendedAttacks) attack.declaringPlayerId,
    for (final hold in state.mapObjectiveHoldStatesByObjectiveId.values)
      hold.playerId,
    for (final trade in state.resourceTradeAgreements) ...[
      trade.exporterPlayerId,
      trade.importerPlayerId,
    ],
    ?state.cityFoundingDraft?.ownerPlayerId,
    ?state.pendingAction?.ownerPlayerId,
  }..removeWhere((playerId) => playerId.isEmpty);
}

Map<String, dynamic> _encodeLifecycle({required DomainState domain}) {
  return {
    ..._encodeActionLifecycle(domain),
    ..._encodeTurnLifecycle(domain),
    ..._encodeRuleLifecycle(domain),
  };
}

Map<String, dynamic> _encodeActionLifecycle(DomainState domain) {
  return {
    if (domain.actions.cityFoundingDraft != null)
      'cityFoundingDraft': domain.actions.cityFoundingDraft!.toJson(),
    if (domain.actions.pendingAction != null)
      'pendingAction': domain.actions.pendingAction!.toJson(),
  };
}

Map<String, dynamic> _encodeTurnLifecycle(DomainState domain) {
  return {
    if (domain.submittedPlayerIds.isNotEmpty)
      'submittedPlayerIds': _sortedStrings(domain.submittedPlayerIds),
    if (domain.timeoutStreaksByPlayerId.isNotEmpty)
      'timeoutStreaksByPlayerId': _sortedIntMap(
        domain.timeoutStreaksByPlayerId,
      ),
    if (domain.afkPlayerIds.isNotEmpty)
      'afkPlayerIds': _sortedStrings(domain.afkPlayerIds),
    if (domain.kickedPlayerIds.isNotEmpty)
      'kickedPlayerIds': _sortedStrings(domain.kickedPlayerIds),
    if (domain.turnStartedAt != null)
      'turnStartedAt': domain.turnStartedAt!.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> _encodeRuleLifecycle(DomainState domain) {
  final objectiveHolds =
      domain.mapObjectiveHoldStatesByObjectiveId.values.toList()
        ..sort((left, right) => left.objectiveId.compareTo(right.objectiveId));
  final trades = domain.resourceTradeAgreements.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return {
    if (domain.intendedAttacks.isNotEmpty)
      'intendedAttacks': [
        for (final attack in domain.intendedAttacks) attack.toJson(),
      ],
    if (domain.diplomacy.isNotEmpty) 'diplomacy': domain.diplomacy.toJson(),
    if (domain.dominationHoldTurnsByPlayerId.isNotEmpty)
      'dominationHoldTurnsByPlayerId': _sortedIntMap(
        domain.dominationHoldTurnsByPlayerId,
      ),
    if (domain.culturalVictoryHoldTurnsByPlayerId.isNotEmpty)
      'culturalVictoryHoldTurnsByPlayerId': _sortedIntMap(
        domain.culturalVictoryHoldTurnsByPlayerId,
      ),
    if (objectiveHolds.isNotEmpty)
      'mapObjectiveHoldStates': [
        for (final hold in objectiveHolds) hold.toJson(),
      ],
    if (trades.isNotEmpty)
      'resourceTradeAgreements': [for (final trade in trades) trade.toJson()],
  };
}
