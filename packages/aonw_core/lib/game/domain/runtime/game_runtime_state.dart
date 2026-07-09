import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/util/collection_equality.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_runtime_state.freezed.dart';
part 'game_runtime_state_codec.dart';
part 'pending_player_action.dart';

@freezed
abstract class GameRuntimeState with _$GameRuntimeState {
  const GameRuntimeState._();

  static const empty = GameRuntimeState();

  const factory GameRuntimeState({
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
    @Default(<String>{}) Set<String> submittedPlayerIds,
    @Default(<String, int>{}) Map<String, int> timeoutStreaksByPlayerId,
    @Default(<String>{}) Set<String> afkPlayerIds,
    @Default(<String>{}) Set<String> kickedPlayerIds,
    @Default(<IntendedAttack>[]) List<IntendedAttack> intendedAttacks,
    @Default(DiplomacyState.empty) DiplomacyState diplomacy,
    @Default(<String, int>{}) Map<String, int> dominationHoldTurnsByPlayerId,
    @Default(<String, int>{})
    Map<String, int> culturalVictoryHoldTurnsByPlayerId,
    @Default(<String, MapObjectiveHoldState>{})
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,
    @Default(<ResourceTradeAgreement>[])
    List<ResourceTradeAgreement> resourceTradeAgreements,
    DateTime? turnStartedAt,
  }) = _GameRuntimeState;

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
}
