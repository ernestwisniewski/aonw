import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

const Object _unsetClientValue = Object();

/// Client-local selection, targeting and prompt state.
final class InteractionState {
  const InteractionState({
    this.selection,
    this.movePreview,
    this.cityFoundingDraft,
    this.pendingAction,
    this.moveCommandActive = false,
  });

  static const empty = InteractionState();
  static const Object unset = Object();

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

  InteractionState copyWith({
    Object? selection = unset,
    Object? movePreview = unset,
    Object? cityFoundingDraft = unset,
    Object? pendingAction = unset,
    bool? moveCommandActive,
  }) => InteractionState(
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

  InteractionState clearMapState({bool clearPendingAction = false}) => copyWith(
    moveCommandActive: false,
    movePreview: null,
    cityFoundingDraft: null,
    pendingAction: clearPendingAction ? null : pendingAction,
  );

  InteractionState clearTransientModes() => copyWith(
    moveCommandActive: false,
    movePreview: null,
    cityFoundingDraft: null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionState &&
          other.selection == selection &&
          other.movePreview == movePreview &&
          other.cityFoundingDraft == cityFoundingDraft &&
          other.pendingAction == pendingAction &&
          other.moveCommandActive == moveCommandActive;

  @override
  int get hashCode => Object.hash(
    selection,
    movePreview,
    cityFoundingDraft,
    pendingAction,
    moveCommandActive,
  );
}

/// Client projection composed from canonical domain data and local interaction.
///
/// This value never owns a second copy of rule state: every authoritative
/// getter delegates to [domain].
final class GameClientState {
  GameClientState.fromDomain({
    required this.domain,
    this.activePlayerId = '',
    this.activePlayerCanAct = true,
    this.interaction = InteractionState.empty,
  });

  /// Projection fixture constructor retained for UI tests.
  factory GameClientState({
    DomainState? domain,
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
    DiplomacyState diplomacy = DiplomacyState.empty,
    List<IntendedAttack> intendedAttacks = const [],
    List<ResourceTradeAgreement> resourceTradeAgreements = const [],
    Map<String, int> dominationHoldTurnsByPlayerId = const {},
    Map<String, int> culturalVictoryHoldTurnsByPlayerId = const {},
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
    String activePlayerId = '',
    bool activePlayerCanAct = true,
    Set<String> submittedPlayerIds = const {},
    Map<String, int> timeoutStreaksByPlayerId = const {},
    Set<String> afkPlayerIds = const {},
    Set<String> kickedPlayerIds = const {},
    DateTime? turnStartedAt,
    DomainActionState domainActions = DomainActionState.empty,
    InteractionState interaction = InteractionState.empty,
  }) => (() {
    final resolvedDomain =
        domain ??
        DomainState.snapshot(
          turn: 0,
          matchRules: MatchRules.standard,
          participants: _projectionParticipants(
            playerColors: playerColors,
            playerCountries: playerCountries,
            playerGold: playerGold,
            units: units,
            cities: cities,
            activePlayerId: activePlayerId,
            submittedPlayerIds: submittedPlayerIds,
            timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
            afkPlayerIds: afkPlayerIds,
            kickedPlayerIds: kickedPlayerIds,
          ),
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
          diplomacy: diplomacy,
          intendedAttacks: intendedAttacks,
          resourceTradeAgreements: resourceTradeAgreements,
          dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
          culturalVictoryHoldTurnsByPlayerId:
              culturalVictoryHoldTurnsByPlayerId,
          mapObjectiveHoldStatesByObjectiveId:
              mapObjectiveHoldStatesByObjectiveId,
          submittedPlayerIds: submittedPlayerIds,
          timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
          afkPlayerIds: afkPlayerIds,
          kickedPlayerIds: kickedPlayerIds,
          turnStartedAt: turnStartedAt,
          actions: domainActions,
        );
    return GameClientState.fromDomain(
      domain: resolvedDomain,
      activePlayerId: activePlayerId,
      activePlayerCanAct: activePlayerCanAct,
      interaction: interaction,
    );
  })();

  final DomainState domain;
  final String activePlayerId;
  final bool activePlayerCanAct;
  final InteractionState interaction;

  Map<String, int> get playerColors => domain.playerColors;
  Map<String, PlayerCountry> get playerCountries => domain.playerCountries;
  Map<String, int> get playerGold => domain.playerGold;
  Map<String, int> get playerWarWeariness => domain.playerWarWeariness;
  Map<String, int> get playerStabilityNet => domain.playerStabilityNet;
  List<GameUnit> get units => domain.units;
  List<GameCity> get cities => domain.cities;
  List<WorldArtifact> get artifacts => domain.artifacts;
  List<FieldImprovement> get fieldImprovements => domain.fieldImprovements;
  FogOfWarState get fogOfWar => domain.fogOfWar;
  ResearchState get research => domain.research;
  WonderRegistry get wonderRegistry => domain.wonderRegistry;
  DiplomacyState get diplomacy => domain.diplomacy;
  List<IntendedAttack> get intendedAttacks => domain.intendedAttacks;
  List<ResourceTradeAgreement> get resourceTradeAgreements =>
      domain.resourceTradeAgreements;
  Map<String, int> get dominationHoldTurnsByPlayerId =>
      domain.dominationHoldTurnsByPlayerId;
  Map<String, int> get culturalVictoryHoldTurnsByPlayerId =>
      domain.culturalVictoryHoldTurnsByPlayerId;
  Map<String, MapObjectiveHoldState> get mapObjectiveHoldStatesByObjectiveId =>
      domain.mapObjectiveHoldStatesByObjectiveId;
  Set<String> get submittedPlayerIds => domain.submittedPlayerIds;
  Map<String, int> get timeoutStreaksByPlayerId =>
      domain.timeoutStreaksByPlayerId;
  Set<String> get afkPlayerIds => domain.afkPlayerIds;
  Set<String> get kickedPlayerIds => domain.kickedPlayerIds;
  DateTime? get turnStartedAt => domain.turnStartedAt;

  GameClientState withDomain(DomainState nextDomain) =>
      identical(domain, nextDomain)
      ? this
      : GameClientState.fromDomain(
          domain: nextDomain,
          activePlayerId: activePlayerId,
          activePlayerCanAct: activePlayerCanAct,
          interaction: interaction,
        );

  GameSelection? get selection => interaction.selection;
  UnitMovementPlan? get movePreview => interaction.movePreview;
  CityFoundingDraft? get cityFoundingDraft => interaction.cityFoundingDraft;
  PendingPlayerAction? get pendingAction => interaction.pendingAction;
  bool get moveCommandActive => interaction.moveCommandActive;

  GameClientState copyWith({
    DomainState? domain,
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
    DiplomacyState? diplomacy,
    List<IntendedAttack>? intendedAttacks,
    List<ResourceTradeAgreement>? resourceTradeAgreements,
    Map<String, int>? dominationHoldTurnsByPlayerId,
    Map<String, int>? culturalVictoryHoldTurnsByPlayerId,
    Map<String, MapObjectiveHoldState>? mapObjectiveHoldStatesByObjectiveId,
    String? activePlayerId,
    bool? activePlayerCanAct,
    Set<String>? submittedPlayerIds,
    Map<String, int>? timeoutStreaksByPlayerId,
    Set<String>? afkPlayerIds,
    Set<String>? kickedPlayerIds,
    Object? turnStartedAt = _unsetClientValue,
    InteractionState? interaction,
  }) => (() {
    final source = domain ?? this.domain;
    var updatedDomain = source.copyWith(
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
      diplomacy: diplomacy,
      intendedAttacks: intendedAttacks,
      resourceTradeAgreements: resourceTradeAgreements,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
      submittedPlayerIds: submittedPlayerIds,
      timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
      afkPlayerIds: afkPlayerIds,
      kickedPlayerIds: kickedPlayerIds,
    );
    if (!identical(turnStartedAt, _unsetClientValue)) {
      updatedDomain = updatedDomain.copyWith(turnStartedAt: turnStartedAt);
    }
    return GameClientState.fromDomain(
      domain: updatedDomain,
      activePlayerId: activePlayerId ?? this.activePlayerId,
      activePlayerCanAct: activePlayerCanAct ?? this.activePlayerCanAct,
      interaction: interaction ?? this.interaction,
    );
  })();

  GameClientState copyWithInteraction({
    Object? selection = InteractionState.unset,
    Object? movePreview = InteractionState.unset,
    Object? cityFoundingDraft = InteractionState.unset,
    Object? pendingAction = InteractionState.unset,
    bool? moveCommandActive,
  }) => copyWith(
    interaction: interaction.copyWith(
      selection: selection,
      movePreview: movePreview,
      cityFoundingDraft: cityFoundingDraft,
      pendingAction: pendingAction,
      moveCommandActive: moveCommandActive,
    ),
  );

  String? get selectedUnitId =>
      selection?.type == GameSelectionType.unit ? selection!.unit?.id : null;

  GameUnit? get selectedUnit {
    final id = selectedUnitId;
    return id == null ? null : unitById(id);
  }

  GameUnit? unitById(String unitId) => units.byId(unitId);
  GameCity? cityById(String cityId) => cities.byId(cityId);
  int? colorForPlayer(String playerId) => playerColors[playerId];
  PlayerCountry countryForPlayer(String playerId) =>
      domain.countryForPlayer(playerId);

  bool canControlUnit(GameUnit unit) =>
      activePlayerCanAct &&
      (activePlayerId.isEmpty || unit.ownerPlayerId == activePlayerId);

  bool canControlCity(GameCity city) =>
      activePlayerCanAct &&
      (activePlayerId.isEmpty || city.ownerPlayerId == activePlayerId);

  bool hasSubmittedTurn(String playerId) => domain.hasSubmitted(playerId);

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

  GameUnit? unitAt(int col, int row) => units.unitAt(col, row);
  GameCity? cityAt(int col, int row) => cities.cityAt(col, row);
  GameInteractionMode get interactionMode => interaction.mode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameClientState &&
          other.domain == domain &&
          other.activePlayerId == activePlayerId &&
          other.activePlayerCanAct == activePlayerCanAct &&
          other.interaction == interaction;

  @override
  int get hashCode =>
      Object.hash(domain, activePlayerId, activePlayerCanAct, interaction);
}

List<Player> _projectionParticipants({
  required Map<String, int> playerColors,
  required Map<String, PlayerCountry> playerCountries,
  required Map<String, int> playerGold,
  required Iterable<GameUnit> units,
  required Iterable<GameCity> cities,
  required String activePlayerId,
  required Set<String> submittedPlayerIds,
  required Map<String, int> timeoutStreaksByPlayerId,
  required Set<String> afkPlayerIds,
  required Set<String> kickedPlayerIds,
}) {
  final ids = <String>{
    ...playerColors.keys,
    ...playerCountries.keys,
    ...playerGold.keys,
    activePlayerId,
    ...submittedPlayerIds,
    ...timeoutStreaksByPlayerId.keys,
    ...afkPlayerIds,
    ...kickedPlayerIds,
    for (final unit in units) unit.ownerPlayerId,
    for (final city in cities) city.ownerPlayerId,
  }..removeWhere((id) => id.isEmpty);
  final ordered = ids.toList()..sort();
  return [
    for (var index = 0; index < ordered.length; index++)
      Player(
        id: ordered[index],
        name: ordered[index],
        colorValue:
            playerColors[ordered[index]] ??
            Player.palette[index % Player.palette.length],
        country: playerCountries[ordered[index]] ?? PlayerCountry.poland,
      ),
  ];
}
