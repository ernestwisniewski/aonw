import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/util/collection_equality.dart';

part 'domain_state_copying.dart';
part 'domain_state_value.dart';

/// The complete, canonical rule state of a running match.
///
/// Session lifecycle, client interaction, presentation, and persistence
/// metadata belong to their own state boundaries.
final class DomainState {
  factory DomainState.snapshot({
    required int turn,
    required MatchRules matchRules,
    required List<Player> participants,
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
  }) {
    final ownedParticipants = _ownDomainParticipants(participants);
    return DomainState._owned(
      turn: turn,
      matchRules: matchRules,
      participants: ownedParticipants,
      playerColors: _domainPlayerColors(ownedParticipants),
      playerCountries: _domainPlayerCountries(ownedParticipants),
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
    );
  }

  const DomainState._owned({
    required this.turn,
    required this.matchRules,
    required this.participants,
    required Map<String, int> playerColors,
    required Map<String, PlayerCountry> playerCountries,
    required this.playerGold,
    required this.playerWarWeariness,
    required this.playerStabilityNet,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fieldImprovements,
    required this.fogOfWar,
    required this.research,
    required this.wonderRegistry,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.resourceTradeAgreements,
    required this.dominationHoldTurnsByPlayerId,
    required this.culturalVictoryHoldTurnsByPlayerId,
    required this.mapObjectiveHoldStatesByObjectiveId,
  }) : _playerColors = playerColors,
       _playerCountries = playerCountries;

  final int turn;
  final MatchRules matchRules;
  final List<Player> participants;
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

  DomainState copyWith({
    int? turn,
    MatchRules? matchRules,
    List<Player>? participants,
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

List<T> _immutableDomainList<T>(List<T> source) =>
    source.isEmpty ? const [] : List.unmodifiable(source);

List<GameCity> _immutableDomainCities(List<GameCity> source) => source.isEmpty
    ? const []
    : List<GameCity>.unmodifiable(
        source.map((city) => city.immutableSnapshot()),
      );
