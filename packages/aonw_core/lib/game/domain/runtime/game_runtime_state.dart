import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/util/collection_equality.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_runtime_state.freezed.dart';
part 'game_runtime_state_codec.dart';
part 'game_runtime_state_copying.dart';
part 'game_runtime_state_value.dart';
part 'pending_player_action.dart';

final class GameRuntimeState with _GameRuntimeStateCopying {
  static const Object _unset = Object();
  static const empty = GameRuntimeState._owned();

  @override
  final CityFoundingDraft? cityFoundingDraft;
  @override
  final PendingPlayerAction? pendingAction;
  @override
  final Set<String> submittedPlayerIds;
  @override
  final Map<String, int> timeoutStreaksByPlayerId;
  @override
  final Set<String> afkPlayerIds;
  @override
  final Set<String> kickedPlayerIds;
  @override
  final List<IntendedAttack> intendedAttacks;
  @override
  final DiplomacyState diplomacy;
  @override
  final Map<String, int> dominationHoldTurnsByPlayerId;
  @override
  final Map<String, int> culturalVictoryHoldTurnsByPlayerId;
  @override
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;
  @override
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  @override
  final DateTime? turnStartedAt;
  @override
  final bool _isImmutableSnapshot;

  /// Legacy const constructor retained for compile-time fixtures.
  /// Runtime code must use [GameRuntimeState.snapshot].
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
  }) : _isImmutableSnapshot = false;

  GameRuntimeState.snapshot({
    this.cityFoundingDraft,
    this.pendingAction,
    Set<String> submittedPlayerIds = const {},
    Map<String, int> timeoutStreaksByPlayerId = const {},
    Set<String> afkPlayerIds = const {},
    Set<String> kickedPlayerIds = const {},
    List<IntendedAttack> intendedAttacks = const [],
    this.diplomacy = DiplomacyState.empty,
    Map<String, int> dominationHoldTurnsByPlayerId = const {},
    Map<String, int> culturalVictoryHoldTurnsByPlayerId = const {},
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
    List<ResourceTradeAgreement> resourceTradeAgreements = const [],
    this.turnStartedAt,
  }) : submittedPlayerIds = _immutableRuntimeSet(submittedPlayerIds),
       timeoutStreaksByPlayerId = _immutableRuntimeMap(
         timeoutStreaksByPlayerId,
       ),
       afkPlayerIds = _immutableRuntimeSet(afkPlayerIds),
       kickedPlayerIds = _immutableRuntimeSet(kickedPlayerIds),
       intendedAttacks = _immutableRuntimeList(intendedAttacks),
       dominationHoldTurnsByPlayerId = _immutableRuntimeMap(
         dominationHoldTurnsByPlayerId,
       ),
       culturalVictoryHoldTurnsByPlayerId = _immutableRuntimeMap(
         culturalVictoryHoldTurnsByPlayerId,
       ),
       mapObjectiveHoldStatesByObjectiveId = _immutableRuntimeMap(
         mapObjectiveHoldStatesByObjectiveId,
       ),
       resourceTradeAgreements = _immutableRuntimeList(resourceTradeAgreements),
       _isImmutableSnapshot = true;

  const GameRuntimeState._owned({
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
  }) : _isImmutableSnapshot = true;

  factory GameRuntimeState.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty;
    return GameRuntimeState.snapshot(
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

  bool hasSubmitted(String playerId) => submittedPlayerIds.contains(playerId);
  bool isAfk(String playerId) => afkPlayerIds.contains(playerId);
  bool isKicked(String playerId) => kickedPlayerIds.contains(playerId);

  GameRuntimeState withoutClientInteractionState() {
    return copyWith(cityFoundingDraft: null, pendingAction: null);
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
      identical(this, other) ||
      other is GameRuntimeState && _sameRuntimeState(this, other);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    cityFoundingDraft,
    pendingAction,
    Object.hashAllUnordered(submittedPlayerIds),
    mapHash(timeoutStreaksByPlayerId),
    Object.hashAllUnordered(afkPlayerIds),
    Object.hashAllUnordered(kickedPlayerIds),
    Object.hashAll(intendedAttacks),
    diplomacy,
    mapHash(dominationHoldTurnsByPlayerId),
    mapHash(culturalVictoryHoldTurnsByPlayerId),
    mapHash(mapObjectiveHoldStatesByObjectiveId),
    Object.hashAll(resourceTradeAgreements),
    turnStartedAt,
  );

  @override
  String toString() {
    return 'GameRuntimeState(cityFoundingDraft: $cityFoundingDraft, '
        'pendingAction: $pendingAction, '
        'submittedPlayerIds: $submittedPlayerIds, '
        'timeoutStreaksByPlayerId: $timeoutStreaksByPlayerId, '
        'afkPlayerIds: $afkPlayerIds, kickedPlayerIds: $kickedPlayerIds, '
        'intendedAttacks: $intendedAttacks, diplomacy: $diplomacy, '
        'dominationHoldTurnsByPlayerId: $dominationHoldTurnsByPlayerId, '
        'culturalVictoryHoldTurnsByPlayerId: '
        '$culturalVictoryHoldTurnsByPlayerId, '
        'mapObjectiveHoldStatesByObjectiveId: '
        '$mapObjectiveHoldStatesByObjectiveId, '
        'resourceTradeAgreements: $resourceTradeAgreements, '
        'turnStartedAt: $turnStartedAt)';
  }
}
