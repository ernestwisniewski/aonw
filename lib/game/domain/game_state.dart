import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

@freezed
abstract class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    @Default({}) Map<String, int> playerColors,
    @Default({}) Map<String, PlayerCountry> playerCountries,
    @Default({}) Map<String, int> playerGold,
    @Default([]) List<GameUnit> units,
    @Default([]) List<GameCity> cities,
    @Default([]) List<WorldArtifact> artifacts,
    @Default([]) List<FieldImprovement> fieldImprovements,
    @Default(FogOfWarState.empty) FogOfWarState fogOfWar,
    @Default(ResearchState.empty) ResearchState research,
    @Default(DiplomacyState.empty) DiplomacyState diplomacy,
    @Default([]) List<IntendedAttack> intendedAttacks,
    @Default([]) List<ResourceTradeAgreement> resourceTradeAgreements,
    @Default({}) Map<String, int> dominationHoldTurnsByPlayerId,
    @Default({}) Map<String, int> culturalVictoryHoldTurnsByPlayerId,
    @Default({})
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId,
    @Default('') String activePlayerId,
    @Default(true) bool activePlayerCanAct,
    @Default({}) Set<String> submittedPlayerIds,
    GameSelection? selection,
    UnitMovementPlan? movePreview,
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
    @Default(false) bool moveCommandActive,
  }) = _GameState;

  String? get selectedUnitId {
    if (selection?.type == GameSelectionType.unit) {
      return selection!.unit?.id;
    }
    return null;
  }

  GameUnit? get selectedUnit {
    final id = selectedUnitId;
    if (id == null) return null;
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  int? colorForPlayer(String playerId) => playerColors[playerId];

  PlayerCountry countryForPlayer(String playerId) {
    return playerCountries[playerId] ?? PlayerCountry.poland;
  }

  bool canControlUnit(GameUnit unit) {
    if (!activePlayerCanAct) return false;
    if (activePlayerId.isEmpty) return true;
    return unit.ownerPlayerId == activePlayerId;
  }

  bool canControlCity(GameCity city) {
    if (!activePlayerCanAct) return false;
    if (activePlayerId.isEmpty) return true;
    return city.ownerPlayerId == activePlayerId;
  }

  bool hasSubmittedTurn(String playerId) =>
      submittedPlayerIds.contains(playerId);

  FogVisibilityQuery get activePlayerVisibility =>
      FogVisibilityQuery(playerId: activePlayerId, state: fogOfWar);

  List<GameUnit> get unitsVisibleToActivePlayer {
    final query = activePlayerVisibility;
    return [
      for (final unit in units)
        if (unit.ownerPlayerId == activePlayerId ||
            query.canSeeDynamicAt(unit.col, unit.row))
          unit,
    ];
  }

  List<GameCity> get citiesKnownToActivePlayer {
    final query = activePlayerVisibility;
    return [
      for (final city in cities)
        if (query.canRememberStaticAt(city.center.col, city.center.row)) city,
    ];
  }

  GameUnit? unitAt(int col, int row) {
    for (final unit in units) {
      if (unit.occupies(col, row)) return unit;
    }
    return null;
  }

  GameInteractionMode get interactionMode {
    if (cityFoundingDraft != null) return GameInteractionMode.cityFounding;
    if (pendingAction != null) return pendingAction!.mode;
    if (moveCommandActive) return GameInteractionMode.moveTargeting;
    return GameInteractionMode.standard;
  }

  GameRuntimeState get runtimeState => GameRuntimeState(
    cityFoundingDraft: cityFoundingDraft,
    pendingAction: pendingAction,
    submittedPlayerIds: submittedPlayerIds,
    intendedAttacks: intendedAttacks,
    diplomacy: diplomacy,
    resourceTradeAgreements: resourceTradeAgreements,
    dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
  );
}
