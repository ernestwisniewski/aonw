part of 'game_runtime_state.dart';

mixin _GameRuntimeStateCopying {
  CityFoundingDraft? get cityFoundingDraft;
  PendingPlayerAction? get pendingAction;
  Set<String> get submittedPlayerIds;
  Map<String, int> get timeoutStreaksByPlayerId;
  Set<String> get afkPlayerIds;
  Set<String> get kickedPlayerIds;
  List<IntendedAttack> get intendedAttacks;
  DiplomacyState get diplomacy;
  Map<String, int> get dominationHoldTurnsByPlayerId;
  Map<String, int> get culturalVictoryHoldTurnsByPlayerId;
  Map<String, MapObjectiveHoldState> get mapObjectiveHoldStatesByObjectiveId;
  List<ResourceTradeAgreement> get resourceTradeAgreements;
  DateTime? get turnStartedAt;
  bool get _isImmutableSnapshot;

  GameRuntimeState immutableSnapshot() {
    if (_isImmutableSnapshot) return this as GameRuntimeState;
    return GameRuntimeState.snapshot(
      cityFoundingDraft: cityFoundingDraft,
      pendingAction: pendingAction,
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
    Object? cityFoundingDraft = GameRuntimeState._unset,
    Object? pendingAction = GameRuntimeState._unset,
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
    Object? turnStartedAt = GameRuntimeState._unset,
  }) {
    final source = immutableSnapshot();
    return GameRuntimeState._owned(
      cityFoundingDraft: identical(cityFoundingDraft, GameRuntimeState._unset)
          ? source.cityFoundingDraft
          : cityFoundingDraft as CityFoundingDraft?,
      pendingAction: identical(pendingAction, GameRuntimeState._unset)
          ? source.pendingAction
          : pendingAction as PendingPlayerAction?,
      submittedPlayerIds: _runtimeSetCopy(
        submittedPlayerIds,
        source.submittedPlayerIds,
      ),
      timeoutStreaksByPlayerId: _runtimeMapCopy(
        timeoutStreaksByPlayerId,
        source.timeoutStreaksByPlayerId,
      ),
      afkPlayerIds: _runtimeSetCopy(afkPlayerIds, source.afkPlayerIds),
      kickedPlayerIds: _runtimeSetCopy(kickedPlayerIds, source.kickedPlayerIds),
      intendedAttacks: _runtimeListCopy(
        intendedAttacks,
        source.intendedAttacks,
      ),
      diplomacy: diplomacy ?? source.diplomacy,
      dominationHoldTurnsByPlayerId: _runtimeMapCopy(
        dominationHoldTurnsByPlayerId,
        source.dominationHoldTurnsByPlayerId,
      ),
      culturalVictoryHoldTurnsByPlayerId: _runtimeMapCopy(
        culturalVictoryHoldTurnsByPlayerId,
        source.culturalVictoryHoldTurnsByPlayerId,
      ),
      mapObjectiveHoldStatesByObjectiveId: _runtimeMapCopy(
        mapObjectiveHoldStatesByObjectiveId,
        source.mapObjectiveHoldStatesByObjectiveId,
      ),
      resourceTradeAgreements: _runtimeListCopy(
        resourceTradeAgreements,
        source.resourceTradeAgreements,
      ),
      turnStartedAt: identical(turnStartedAt, GameRuntimeState._unset)
          ? source.turnStartedAt
          : turnStartedAt as DateTime?,
    );
  }
}

Set<T> _runtimeSetCopy<T>(Set<T>? replacement, Set<T> current) {
  return replacement == null ? current : _immutableRuntimeSet(replacement);
}

Map<K, V> _runtimeMapCopy<K, V>(Map<K, V>? replacement, Map<K, V> current) {
  return replacement == null ? current : _immutableRuntimeMap(replacement);
}

List<T> _runtimeListCopy<T>(List<T>? replacement, List<T> current) {
  return replacement == null ? current : _immutableRuntimeList(replacement);
}

Set<T> _immutableRuntimeSet<T>(Set<T> source) =>
    source.isEmpty ? const {} : Set.unmodifiable(source);

Map<K, V> _immutableRuntimeMap<K, V>(Map<K, V> source) =>
    source.isEmpty ? const {} : Map.unmodifiable(source);

List<T> _immutableRuntimeList<T>(List<T> source) =>
    source.isEmpty ? const [] : List.unmodifiable(source);
