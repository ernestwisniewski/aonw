import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/util/collection_equality.dart';

part 'game_runtime_state_codec.dart';
part 'pending_player_action.dart';

class GameRuntimeState {
  static const empty = GameRuntimeState();

  const GameRuntimeState({
    this.cityFoundingDraft,
    this.pendingAction,
    this.submittedPlayerIds = const {},
    this.timeoutStreaksByPlayerId = const {},
    this.afkPlayerIds = const {},
    this.kickedPlayerIds = const {},
    this.intendedAttacks = const [],
    this.diplomacy = DiplomacyState.empty,
    this.dominationHoldTurnsByPlayerId = const {},
    this.culturalVictoryHoldTurnsByPlayerId = const {},
    this.mapObjectiveHoldStatesByObjectiveId = const {},
    this.resourceTradeAgreements = const [],
    this.turnStartedAt,
  });

  factory GameRuntimeState.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty;
    return GameRuntimeState(
      cityFoundingDraft: switch (json['cityFoundingDraft']) {
        final Map<String, dynamic> value => CityFoundingDraft.fromJson(value),
        _ => null,
      },
      pendingAction: switch (json['pendingAction']) {
        final Map<String, dynamic> value => PendingPlayerAction.fromJson(value),
        _ => null,
      },
      submittedPlayerIds: _readStringSet(
        json['submittedPlayerIds'],
        'submittedPlayerIds',
      ),
      timeoutStreaksByPlayerId: _readNonNegativeIntMap(
        json['timeoutStreaksByPlayerId'],
        'timeoutStreaksByPlayerId',
      ),
      afkPlayerIds: _readStringSet(json['afkPlayerIds'], 'afkPlayerIds'),
      kickedPlayerIds: _readStringSet(
        json['kickedPlayerIds'],
        'kickedPlayerIds',
      ),
      intendedAttacks: _readIntendedAttacks(json['intendedAttacks']),
      diplomacy: DiplomacyState.fromJson(json['diplomacy']),
      dominationHoldTurnsByPlayerId: _readNonNegativeIntMap(
        json['dominationHoldTurnsByPlayerId'],
        'dominationHoldTurnsByPlayerId',
      ),
      culturalVictoryHoldTurnsByPlayerId: _readNonNegativeIntMap(
        json['culturalVictoryHoldTurnsByPlayerId'],
        'culturalVictoryHoldTurnsByPlayerId',
      ),
      mapObjectiveHoldStatesByObjectiveId: _readMapObjectiveHoldStates(
        json['mapObjectiveHoldStates'],
      ),
      resourceTradeAgreements: _readResourceTradeAgreements(
        json['resourceTradeAgreements'],
      ),
      turnStartedAt: _readOptionalUtcDateTime(json['turnStartedAt']),
    );
  }

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

  bool hasSubmitted(String playerId) => submittedPlayerIds.contains(playerId);
  bool isAfk(String playerId) => afkPlayerIds.contains(playerId);
  bool isKicked(String playerId) => kickedPlayerIds.contains(playerId);

  GameRuntimeState withoutClientInteractionState() {
    return GameRuntimeState(
      submittedPlayerIds: submittedPlayerIds,
      timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
      afkPlayerIds: afkPlayerIds,
      kickedPlayerIds: kickedPlayerIds,
      intendedAttacks: intendedAttacks,
      diplomacy: diplomacy,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
      resourceTradeAgreements: resourceTradeAgreements,
      turnStartedAt: turnStartedAt,
    );
  }

  GameRuntimeState copyWith({
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
    Set<String>? submittedPlayerIds,
    Map<String, int>? timeoutStreaksByPlayerId,
    Set<String>? afkPlayerIds,
    Set<String>? kickedPlayerIds,
    List<IntendedAttack>? intendedAttacks,
    DiplomacyState? diplomacy,
    Map<String, int>? dominationHoldTurnsByPlayerId,
    Map<String, int>? culturalVictoryHoldTurnsByPlayerId,
    Map<String, MapObjectiveHoldState>? mapObjectiveHoldStatesByObjectiveId,
    List<ResourceTradeAgreement>? resourceTradeAgreements,
    DateTime? turnStartedAt,
  }) {
    return GameRuntimeState(
      cityFoundingDraft: cityFoundingDraft ?? this.cityFoundingDraft,
      pendingAction: pendingAction ?? this.pendingAction,
      submittedPlayerIds: submittedPlayerIds ?? this.submittedPlayerIds,
      timeoutStreaksByPlayerId:
          timeoutStreaksByPlayerId ?? this.timeoutStreaksByPlayerId,
      afkPlayerIds: afkPlayerIds ?? this.afkPlayerIds,
      kickedPlayerIds: kickedPlayerIds ?? this.kickedPlayerIds,
      intendedAttacks: intendedAttacks ?? this.intendedAttacks,
      diplomacy: diplomacy ?? this.diplomacy,
      dominationHoldTurnsByPlayerId:
          dominationHoldTurnsByPlayerId ?? this.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          culturalVictoryHoldTurnsByPlayerId ??
          this.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          mapObjectiveHoldStatesByObjectiveId ??
          this.mapObjectiveHoldStatesByObjectiveId,
      resourceTradeAgreements:
          resourceTradeAgreements ?? this.resourceTradeAgreements,
      turnStartedAt: turnStartedAt ?? this.turnStartedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    if (cityFoundingDraft != null)
      'cityFoundingDraft': cityFoundingDraft!.toJson(),
    if (pendingAction != null) 'pendingAction': pendingAction!.toJson(),
    if (submittedPlayerIds.isNotEmpty)
      'submittedPlayerIds': [...submittedPlayerIds]..sort(),
    if (timeoutStreaksByPlayerId.isNotEmpty)
      'timeoutStreaksByPlayerId': _sortedIntMap(timeoutStreaksByPlayerId),
    if (afkPlayerIds.isNotEmpty) 'afkPlayerIds': [...afkPlayerIds]..sort(),
    if (kickedPlayerIds.isNotEmpty)
      'kickedPlayerIds': [...kickedPlayerIds]..sort(),
    if (intendedAttacks.isNotEmpty)
      'intendedAttacks': intendedAttacks
          .map((attack) => attack.toJson())
          .toList(),
    if (diplomacy.isNotEmpty) 'diplomacy': diplomacy.toJson(),
    if (dominationHoldTurnsByPlayerId.isNotEmpty)
      'dominationHoldTurnsByPlayerId': _sortedIntMap(
        dominationHoldTurnsByPlayerId,
      ),
    if (culturalVictoryHoldTurnsByPlayerId.isNotEmpty)
      'culturalVictoryHoldTurnsByPlayerId': _sortedIntMap(
        culturalVictoryHoldTurnsByPlayerId,
      ),
    if (mapObjectiveHoldStatesByObjectiveId.isNotEmpty)
      'mapObjectiveHoldStates': _sortedMapObjectiveHoldStates(
        mapObjectiveHoldStatesByObjectiveId,
      ),
    if (resourceTradeAgreements.isNotEmpty)
      'resourceTradeAgreements': _sortedResourceTradeAgreements(
        resourceTradeAgreements,
      ),
    if (turnStartedAt != null)
      'turnStartedAt': turnStartedAt!.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is GameRuntimeState &&
      other.cityFoundingDraft == cityFoundingDraft &&
      other.pendingAction == pendingAction &&
      setEquals(other.submittedPlayerIds, submittedPlayerIds) &&
      mapEquals(other.timeoutStreaksByPlayerId, timeoutStreaksByPlayerId) &&
      setEquals(other.afkPlayerIds, afkPlayerIds) &&
      setEquals(other.kickedPlayerIds, kickedPlayerIds) &&
      listEquals(other.intendedAttacks, intendedAttacks) &&
      other.diplomacy == diplomacy &&
      mapEquals(
        other.dominationHoldTurnsByPlayerId,
        dominationHoldTurnsByPlayerId,
      ) &&
      mapEquals(
        other.culturalVictoryHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId,
      ) &&
      _mapObjectiveHoldStateMapEquals(
        other.mapObjectiveHoldStatesByObjectiveId,
        mapObjectiveHoldStatesByObjectiveId,
      ) &&
      listEquals(other.resourceTradeAgreements, resourceTradeAgreements) &&
      other.turnStartedAt == turnStartedAt;

  @override
  int get hashCode => Object.hash(
    cityFoundingDraft,
    pendingAction,
    _stringSetHash(submittedPlayerIds),
    _intMapHash(timeoutStreaksByPlayerId),
    _stringSetHash(afkPlayerIds),
    _stringSetHash(kickedPlayerIds),
    Object.hashAll(intendedAttacks),
    diplomacy,
    _intMapHash(dominationHoldTurnsByPlayerId),
    _intMapHash(culturalVictoryHoldTurnsByPlayerId),
    _mapObjectiveHoldStateMapHash(mapObjectiveHoldStatesByObjectiveId),
    Object.hashAll(resourceTradeAgreements),
    turnStartedAt,
  );
}
