import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state/game_mode.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/util/collection_equality.dart';

part 'domain_state_copying.dart';
part 'domain_state_value.dart';
part 'domain_state_values.dart';

/// Rule-relevant state of a multi-command action.
final class DomainActionState {
  static const Object _unset = Object();
  static const empty = DomainActionState._owned();

  factory DomainActionState({
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
  }) => DomainActionState._owned(
    cityFoundingDraft: _ownedCityFoundingDraft(cityFoundingDraft),
    pendingAction: pendingAction,
  );

  const DomainActionState._owned({this.cityFoundingDraft, this.pendingAction});

  final CityFoundingDraft? cityFoundingDraft;
  final PendingPlayerAction? pendingAction;

  DomainActionState copyWith({
    Object? cityFoundingDraft = _unset,
    Object? pendingAction = _unset,
  }) {
    final draft = identical(cityFoundingDraft, _unset)
        ? this.cityFoundingDraft
        : cityFoundingDraft as CityFoundingDraft?;
    return DomainActionState._owned(
      cityFoundingDraft: identical(draft, this.cityFoundingDraft)
          ? draft
          : _ownedCityFoundingDraft(draft),
      pendingAction: identical(pendingAction, _unset)
          ? this.pendingAction
          : pendingAction as PendingPlayerAction?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainActionState &&
          other.cityFoundingDraft == cityFoundingDraft &&
          other.pendingAction == pendingAction;

  @override
  int get hashCode => Object.hash(cityFoundingDraft, pendingAction);
}

const Object _unsetDomainValue = Object();

/// The complete, canonical rule state of a running match.
///
/// Client interaction, presentation, and persistence metadata belong to their
/// own state boundaries. Authoritative match lifecycle belongs here because it
/// participates in rule evaluation.
final class DomainState {
  factory DomainState.snapshot({
    int turn = 0,
    MatchRules matchRules = MatchRules.standard,
    List<Player> participants = const [],
    GameMode gameMode = GameMode.hotSeat,
    Map<String, PlayerTurnState> turnStatesByPlayerId = const {},
    Set<String> submittedPlayerIds = const {},
    Map<String, int> timeoutStreaksByPlayerId = const {},
    Set<String> afkPlayerIds = const {},
    Set<String> kickedPlayerIds = const {},
    DateTime? turnStartedAt,
    DomainActionState actions = DomainActionState.empty,
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
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
    List<IntendedAttack> intendedAttacks = const [],
    DiplomacyState diplomacy = DiplomacyState.empty,
    List<ResourceTradeAgreement> resourceTradeAgreements = const [],
    Map<String, int> dominationHoldTurnsByPlayerId = const {},
    Map<String, int> culturalVictoryHoldTurnsByPlayerId = const {},
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
  }) => (() {
    final ownedParticipants = _ownDomainParticipantsWithIdentityOverrides(
      participants,
      playerColors: playerColors,
      playerCountries: playerCountries,
    );
    return DomainState._owned(
      identity: _DomainStateIdentity(
        turn: turn,
        matchRules: matchRules,
        participants: ownedParticipants,
        gameMode: gameMode,
        turnStatesByPlayerId: _immutableDomainMap(turnStatesByPlayerId),
        submittedPlayerIds: _immutableDomainSet(submittedPlayerIds),
        timeoutStreaksByPlayerId: _immutableDomainMap(timeoutStreaksByPlayerId),
        afkPlayerIds: _immutableDomainSet(afkPlayerIds),
        kickedPlayerIds: _immutableDomainSet(kickedPlayerIds),
        turnStartedAt: turnStartedAt?.toUtc(),
        actions: cityFoundingDraft == null && pendingAction == null
            ? actions
            : DomainActionState(
                cityFoundingDraft: cityFoundingDraft,
                pendingAction: pendingAction,
              ),
        playerColors: _domainPlayerColors(ownedParticipants),
        playerCountries: _domainPlayerCountries(ownedParticipants),
      ),
      content: _DomainStateContent(
        playerGold: _immutableDomainMap(playerGold),
        playerWarWeariness: _immutableDomainMap(playerWarWeariness),
        playerStabilityNet: _immutableDomainMap(playerStabilityNet),
        units: _immutableDomainList(units),
        cities: _immutableDomainCities(cities),
        artifacts: _immutableDomainList(artifacts),
        fieldImprovements: _immutableDomainList(fieldImprovements),
        fogOfWar: fogOfWar,
        research: research,
        wonderRegistry: wonderRegistry,
        intendedAttacks: _immutableDomainList(intendedAttacks),
        diplomacy: diplomacy,
        resourceTradeAgreements: _immutableDomainList(resourceTradeAgreements),
        dominationHoldTurnsByPlayerId: _immutableDomainMap(
          dominationHoldTurnsByPlayerId,
        ),
        culturalVictoryHoldTurnsByPlayerId: _immutableDomainMap(
          culturalVictoryHoldTurnsByPlayerId,
        ),
        mapObjectiveHoldStatesByObjectiveId: _immutableDomainMap(
          mapObjectiveHoldStatesByObjectiveId,
        ),
      ),
    );
  })();

  DomainState._owned({
    required _DomainStateIdentity identity,
    required _DomainStateContent content,
  }) : turn = identity.turn,
       matchRules = identity.matchRules,
       participants = identity.participants,
       gameMode = identity.gameMode,
       turnStatesByPlayerId = identity.turnStatesByPlayerId,
       submittedPlayerIds = identity.submittedPlayerIds,
       timeoutStreaksByPlayerId = identity.timeoutStreaksByPlayerId,
       afkPlayerIds = identity.afkPlayerIds,
       kickedPlayerIds = identity.kickedPlayerIds,
       turnStartedAt = identity.turnStartedAt,
       actions = identity.actions,
       _playerColors = identity.playerColors,
       _playerCountries = identity.playerCountries,
       playerGold = content.playerGold,
       playerWarWeariness = content.playerWarWeariness,
       playerStabilityNet = content.playerStabilityNet,
       units = content.units,
       cities = content.cities,
       artifacts = content.artifacts,
       fieldImprovements = content.fieldImprovements,
       fogOfWar = content.fogOfWar,
       research = content.research,
       wonderRegistry = content.wonderRegistry,
       intendedAttacks = content.intendedAttacks,
       diplomacy = content.diplomacy,
       resourceTradeAgreements = content.resourceTradeAgreements,
       dominationHoldTurnsByPlayerId = content.dominationHoldTurnsByPlayerId,
       culturalVictoryHoldTurnsByPlayerId =
           content.culturalVictoryHoldTurnsByPlayerId,
       mapObjectiveHoldStatesByObjectiveId =
           content.mapObjectiveHoldStatesByObjectiveId {
    _validateLifecycleParticipants(
      participants: participants,
      turnStatesByPlayerId: turnStatesByPlayerId,
      submittedPlayerIds: submittedPlayerIds,
      timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
      afkPlayerIds: afkPlayerIds,
      kickedPlayerIds: kickedPlayerIds,
    );
  }

  final int turn;
  final MatchRules matchRules;
  final List<Player> participants;
  final GameMode gameMode;
  final Map<String, PlayerTurnState> turnStatesByPlayerId;
  final Set<String> submittedPlayerIds;
  final Map<String, int> timeoutStreaksByPlayerId;
  final Set<String> afkPlayerIds;
  final Set<String> kickedPlayerIds;
  final DateTime? turnStartedAt;
  final DomainActionState actions;
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
  final List<IntendedAttack> intendedAttacks;
  final DiplomacyState diplomacy;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final Map<String, int> dominationHoldTurnsByPlayerId;
  final Map<String, int> culturalVictoryHoldTurnsByPlayerId;
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;

  final Map<String, int> _playerColors;
  final Map<String, PlayerCountry> _playerCountries;

  /// Player colors are derived exclusively from the ordered participants.
  Map<String, int> get playerColors => _playerColors;

  /// Player countries are derived exclusively from the ordered participants.
  Map<String, PlayerCountry> get playerCountries => _playerCountries;

  PlayerCountry countryForPlayer(String playerId) {
    return _playerCountries[playerId] ?? PlayerCountry.poland;
  }

  bool hasSubmitted(String playerId) => submittedPlayerIds.contains(playerId);

  bool isAfk(String playerId) => afkPlayerIds.contains(playerId);

  bool isKicked(String playerId) => kickedPlayerIds.contains(playerId);

  Set<String> get knownPlayerIds => <String>{
    for (final participant in participants) participant.id,
    ...playerGold.keys,
    ...playerWarWeariness.keys,
    ...playerStabilityNet.keys,
    ...fogOfWar.playerIds,
    ...research.players.keys,
    ...wonderRegistry.completedBy.values,
    ...dominationHoldTurnsByPlayerId.keys,
    ...culturalVictoryHoldTurnsByPlayerId.keys,
    for (final unit in units) unit.ownerPlayerId,
    for (final city in cities) city.ownerPlayerId,
    for (final city in cities) ?city.foundingOwnerPlayerId,
    for (final relation in diplomacy.relations.values) ...[
      relation.playerAId,
      relation.playerBId,
    ],
  }..removeWhere((playerId) => playerId.isEmpty);

  DomainState copyWith({
    int? turn,
    MatchRules? matchRules,
    List<Player>? participants,
    GameMode? gameMode,
    Map<String, PlayerTurnState>? turnStatesByPlayerId,
    Set<String>? submittedPlayerIds,
    Map<String, int>? timeoutStreaksByPlayerId,
    Set<String>? afkPlayerIds,
    Set<String>? kickedPlayerIds,
    Object? turnStartedAt = _unsetDomainValue,
    DomainActionState? actions,
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
    List<IntendedAttack>? intendedAttacks,
    DiplomacyState? diplomacy,
    List<ResourceTradeAgreement>? resourceTradeAgreements,
    Map<String, int>? dominationHoldTurnsByPlayerId,
    Map<String, int>? culturalVictoryHoldTurnsByPlayerId,
    Map<String, MapObjectiveHoldState>? mapObjectiveHoldStatesByObjectiveId,
  }) => _copyDomainState(this, (
    turn: turn,
    matchRules: matchRules,
    participants: participants,
    gameMode: gameMode,
    turnStatesByPlayerId: turnStatesByPlayerId,
    submittedPlayerIds: submittedPlayerIds,
    timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
    afkPlayerIds: afkPlayerIds,
    kickedPlayerIds: kickedPlayerIds,
    turnStartedAt: turnStartedAt,
    actions: actions,
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
    mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
  ));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainState && _sameDomainState(this, other);

  @override
  int get hashCode => _domainStateHash(this);
}

List<Player> _ownDomainParticipantsWithIdentityOverrides(
  List<Player> source, {
  required Map<String, int> playerColors,
  required Map<String, PlayerCountry> playerCountries,
}) {
  final participants = [
    for (final player in source)
      player.copyWith(
        colorValue: playerColors[player.id] ?? player.colorValue,
        country: playerCountries[player.id] ?? player.country,
      ),
  ];
  final includedIds = participants.map((player) => player.id).toSet();
  final missingIds = <String>{
    ...playerColors.keys,
    ...playerCountries.keys,
  }.difference(includedIds).toList()..sort();
  for (final playerId in missingIds) {
    participants.add(
      Player(
        id: playerId,
        name: playerId,
        colorValue:
            playerColors[playerId] ??
            Player.palette[participants.length % Player.palette.length],
        country: playerCountries[playerId] ?? PlayerCountry.poland,
      ),
    );
  }
  return _ownDomainParticipants(participants);
}

List<Player> _ownDomainParticipants(List<Player> source) {
  final participants = _immutableDomainList(source);
  final seenIds = <String>{};
  for (final participant in participants) {
    if (participant.id.isEmpty) {
      throw ArgumentError.value(
        participant.id,
        'participants',
        'Participant ids must not be empty',
      );
    }
    if (!seenIds.add(participant.id)) {
      throw ArgumentError.value(
        participant.id,
        'participants',
        'Participant ids must be unique',
      );
    }
  }
  return participants;
}

Map<String, int> _domainPlayerColors(List<Player> participants) {
  if (participants.isEmpty) return const {};
  return Map.unmodifiable({
    for (final participant in participants)
      participant.id: participant.colorValue,
  });
}

Map<String, PlayerCountry> _domainPlayerCountries(List<Player> participants) {
  if (participants.isEmpty) return const {};
  return Map.unmodifiable({
    for (final participant in participants) participant.id: participant.country,
  });
}

Map<K, V> _immutableDomainMap<K, V>(Map<K, V> source) =>
    source.isEmpty ? const {} : Map.unmodifiable(source);

Set<T> _immutableDomainSet<T>(Set<T> source) =>
    source.isEmpty ? const {} : Set.unmodifiable(source);

List<T> _immutableDomainList<T>(List<T> source) =>
    source.isEmpty ? const [] : List.unmodifiable(source);

List<GameCity> _immutableDomainCities(List<GameCity> source) => source.isEmpty
    ? const []
    : List<GameCity>.unmodifiable(
        source.map((city) => city.immutableSnapshot()),
      );

CityFoundingDraft? _ownedCityFoundingDraft(CityFoundingDraft? source) {
  if (source == null) return null;
  return CityFoundingDraft(
    unitId: source.unitId,
    ownerPlayerId: source.ownerPlayerId,
    center: source.center,
    controlledHexes: source.controlledHexes,
  );
}

void _validateLifecycleParticipants({
  required List<Player> participants,
  required Map<String, PlayerTurnState> turnStatesByPlayerId,
  required Set<String> submittedPlayerIds,
  required Map<String, int> timeoutStreaksByPlayerId,
  required Set<String> afkPlayerIds,
  required Set<String> kickedPlayerIds,
}) {
  final participantIds = {
    for (final participant in participants) participant.id,
  };
  final lifecyclePlayerIds = <String>{
    ...turnStatesByPlayerId.keys,
    ...submittedPlayerIds,
    ...timeoutStreaksByPlayerId.keys,
    ...afkPlayerIds,
    ...kickedPlayerIds,
  }..removeWhere((playerId) => playerId.isEmpty);
  final unknownPlayerIds =
      lifecyclePlayerIds.difference(participantIds).toList()..sort();
  if (unknownPlayerIds.isEmpty) return;
  throw ArgumentError.value(
    unknownPlayerIds,
    'lifecyclePlayerIds',
    'Lifecycle player ids must belong to domain participants',
  );
}
