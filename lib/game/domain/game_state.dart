import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

// Hand-rolled instead of @freezed because copyWith must distinguish omitted
// fields from explicit nulls. Keep copyWith, equality, and hashCode in sync
// when adding fields.
class GameInteractionState {
  static const empty = GameInteractionState();
  static const Object unset = Object();

  const GameInteractionState({
    this.selection,
    this.movePreview,
    this.cityFoundingDraft,
    this.pendingAction,
    this.moveCommandActive = false,
  });

  final GameSelection? selection;
  final UnitMovementPlan? movePreview;
  final CityFoundingDraft? cityFoundingDraft;
  final PendingPlayerAction? pendingAction;
  final bool moveCommandActive;

  GameInteractionMode get mode {
    if (cityFoundingDraft != null) return GameInteractionMode.cityFounding;
    if (pendingAction != null) return pendingAction!.mode;
    if (moveCommandActive) return GameInteractionMode.moveTargeting;
    return GameInteractionMode.standard;
  }

  GameInteractionState copyWith({
    Object? selection = unset,
    Object? movePreview = unset,
    Object? cityFoundingDraft = unset,
    Object? pendingAction = unset,
    bool? moveCommandActive,
  }) {
    return GameInteractionState(
      selection: identical(selection, unset)
          ? this.selection
          : selection as GameSelection?,
      movePreview: identical(movePreview, unset)
          ? this.movePreview
          : movePreview as UnitMovementPlan?,
      cityFoundingDraft: identical(cityFoundingDraft, unset)
          ? this.cityFoundingDraft
          : cityFoundingDraft as CityFoundingDraft?,
      pendingAction: identical(pendingAction, unset)
          ? this.pendingAction
          : pendingAction as PendingPlayerAction?,
      moveCommandActive: moveCommandActive ?? this.moveCommandActive,
    );
  }

  GameInteractionState clearMapState({bool clearPendingAction = false}) {
    return copyWith(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: clearPendingAction ? null : pendingAction,
    );
  }

  GameInteractionState clearTransientModes() {
    return copyWith(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GameInteractionState &&
        other.selection == selection &&
        other.movePreview == movePreview &&
        other.cityFoundingDraft == cityFoundingDraft &&
        other.pendingAction == pendingAction &&
        other.moveCommandActive == moveCommandActive;
  }

  @override
  int get hashCode => Object.hash(
    selection,
    movePreview,
    cityFoundingDraft,
    pendingAction,
    moveCommandActive,
  );
}

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
    @Default(GameInteractionState.empty) GameInteractionState interaction,
  }) = _GameState;

  GameSelection? get selection => interaction.selection;

  UnitMovementPlan? get movePreview => interaction.movePreview;

  CityFoundingDraft? get cityFoundingDraft => interaction.cityFoundingDraft;

  PendingPlayerAction? get pendingAction => interaction.pendingAction;

  bool get moveCommandActive => interaction.moveCommandActive;

  GameState copyWithInteraction({
    Object? selection = GameInteractionState.unset,
    Object? movePreview = GameInteractionState.unset,
    Object? cityFoundingDraft = GameInteractionState.unset,
    Object? pendingAction = GameInteractionState.unset,
    bool? moveCommandActive,
  }) {
    return copyWith(
      interaction: interaction.copyWith(
        selection: selection,
        movePreview: movePreview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive: moveCommandActive,
      ),
    );
  }

  String? get selectedUnitId {
    if (selection?.type == GameSelectionType.unit) {
      return selection!.unit?.id;
    }
    return null;
  }

  GameUnit? get selectedUnit {
    final id = selectedUnitId;
    return id == null ? null : unitById(id);
  }

  GameUnit? unitById(String unitId) => units.byId(unitId);

  GameCity? cityById(String cityId) => cities.byId(cityId);

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
    return interaction.mode;
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
