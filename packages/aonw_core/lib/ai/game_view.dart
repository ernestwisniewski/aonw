import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'game_view_projection_helpers.dart';

class PendingCityAttackThreat {
  final String attackerPlayerId;
  final String attackerUnitId;
  final HexCoordinate attackerHex;
  final String cityId;
  final CityHex cityCenter;

  const PendingCityAttackThreat({
    required this.attackerPlayerId,
    required this.attackerUnitId,
    required this.attackerHex,
    required this.cityId,
    required this.cityCenter,
  });

  @override
  bool operator ==(Object other) {
    return other is PendingCityAttackThreat &&
        other.attackerPlayerId == attackerPlayerId &&
        other.attackerUnitId == attackerUnitId &&
        other.attackerHex == attackerHex &&
        other.cityId == cityId &&
        other.cityCenter == cityCenter;
  }

  @override
  int get hashCode {
    return Object.hash(
      attackerPlayerId,
      attackerUnitId,
      attackerHex,
      cityId,
      cityCenter,
    );
  }
}

class GameView {
  final String forPlayerId;
  final int turn;
  final List<GameUnit> ownUnits;
  final List<GameCity> ownCities;
  final List<WorldArtifact> artifacts;
  final int ownGold;
  final int ownWarWeariness;
  final int ownStabilityNet;
  final ResearchState research;
  final PlayerResearchState ownResearch;
  final List<FieldImprovement> ownImprovements;
  final List<FieldImprovement> knownImprovements;
  final StrategicResourceStockpile ownStrategicResources;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;
  final DiplomacyState diplomacy;
  final List<GameUnit> visibleEnemyUnits;
  final List<GameUnit> movementBlockingUnits;
  final List<GameCity> rememberedEnemyCities;
  final Set<String> activeHostilePlayerIds;
  final Set<String> recentHostilePlayerIds;
  final Set<String> pressureTargetPlayerIds;
  final Set<String> defaultNeutralPlayerIds;
  final List<PendingCityAttackThreat> pendingCityAttackThreats;
  final FogVisibilityQuery visibility;
  final MapReadView mapData;
  final GameRuleset ruleset;
  final WonderRegistry wonderRegistry;
  final TransportNetworkState transportNetwork;
  final CanonicalGameSnapshot? engineSnapshot;

  GameView({
    required this.forPlayerId,
    required this.turn,
    required Iterable<GameUnit> ownUnits,
    required Iterable<GameCity> ownCities,
    Iterable<WorldArtifact> artifacts = const [],
    this.ownGold = 0,
    this.ownWarWeariness = 0,
    this.ownStabilityNet = 0,
    this.research = ResearchState.empty,
    required this.ownResearch,
    required Iterable<FieldImprovement> ownImprovements,
    Iterable<FieldImprovement>? knownImprovements,
    this.ownStrategicResources = StrategicResourceStockpile.empty,
    Iterable<ResourceTradeAgreement> resourceTradeAgreements = const [],
    Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId =
        const {},
    this.diplomacy = DiplomacyState.empty,
    required Iterable<GameUnit> visibleEnemyUnits,
    Iterable<GameUnit>? movementBlockingUnits,
    required Iterable<GameCity> rememberedEnemyCities,
    Iterable<String> activeHostilePlayerIds = const [],
    Iterable<String> recentHostilePlayerIds = const [],
    Iterable<String> pressureTargetPlayerIds = const [],
    Iterable<String> defaultNeutralPlayerIds = const [],
    Iterable<PendingCityAttackThreat> pendingCityAttackThreats = const [],
    required this.visibility,
    required this.mapData,
    required this.ruleset,
    this.wonderRegistry = WonderRegistry.empty,
    this.transportNetwork = TransportNetworkState.empty,
    this.engineSnapshot,
  }) : ownUnits = List.unmodifiable(ownUnits),
       ownCities = List.unmodifiable(ownCities),
       artifacts = List.unmodifiable(artifacts),
       ownImprovements = List.unmodifiable(ownImprovements),
       knownImprovements = List.unmodifiable(
         knownImprovements ?? ownImprovements,
       ),
       resourceTradeAgreements = List.unmodifiable(resourceTradeAgreements),
       mapObjectiveHoldStatesByObjectiveId = Map.unmodifiable(
         mapObjectiveHoldStatesByObjectiveId,
       ),
       visibleEnemyUnits = List.unmodifiable(visibleEnemyUnits),
       movementBlockingUnits = List.unmodifiable(
         movementBlockingUnits ?? [...ownUnits, ...visibleEnemyUnits],
       ),
       rememberedEnemyCities = List.unmodifiable(rememberedEnemyCities),
       activeHostilePlayerIds = Set.unmodifiable(activeHostilePlayerIds),
       recentHostilePlayerIds = Set.unmodifiable(recentHostilePlayerIds),
       pressureTargetPlayerIds = Set.unmodifiable(pressureTargetPlayerIds),
       defaultNeutralPlayerIds = Set.unmodifiable(defaultNeutralPlayerIds),
       pendingCityAttackThreats = List.unmodifiable(pendingCityAttackThreats);

  late final List<TechnologyId> availableTechnologyIds = List.unmodifiable([
    for (final technologyId in ruleset.technology.technologies.keys)
      if (TechnologyAvailabilityService.availabilityFor(
            technologyId: technologyId,
            playerResearch: ownResearch,
            ruleset: ruleset.technology,
          ) ==
          TechnologyAvailability.available)
        technologyId,
  ]);

  late final UnitTraversalCostResolver traversalCostResolver =
      InfrastructureAwareTraversalCostResolver(transportNetwork);

  UnitMovementPathfinder movementPathfinder({
    MapTraversalView? mapData,
    Iterable<GameUnit>? units,
    bool Function(MapTileView tile)? canEnterTile,
  }) {
    return UnitMovementPathfinder(
      mapData: mapData ?? this.mapData,
      units: units ?? movementBlockingUnits,
      costResolver: traversalCostResolver,
      canEnterTile: canEnterTile,
    );
  }

  late final List<GameCity> citiesWithEmptyProduction = List.unmodifiable([
    for (final city in ownCities)
      if (city.productionQueue == null) city,
  ]);

  late final List<GameCity> citiesWithReassignableProduction =
      List.unmodifiable([
        for (final city in ownCities)
          if (city.productionQueue == null ||
              city.productionQueue?.target is ProjectProductionTarget)
            city,
      ]);

  late final List<GameUnit> visibleTargetableEnemyUnits = List.unmodifiable([
    for (final unit in visibleEnemyUnits)
      if (canTargetPlayer(unit.ownerPlayerId)) unit,
  ]);

  late final List<GameCity> rememberedTargetableEnemyCities =
      List.unmodifiable([
        for (final city in rememberedEnemyCities)
          if (canTargetPlayer(city.ownerPlayerId)) city,
      ]);

  DiplomaticRelationStatus relationStatusFor(String playerId) {
    return diplomacy.statusBetween(forPlayerId, playerId);
  }

  bool hasExplicitDiplomaticRelationWith(String playerId) {
    final key = DiplomacyState.relationKey(forPlayerId, playerId);
    return key.isNotEmpty && diplomacy.relations.containsKey(key);
  }

  bool hasDiplomaticContactWith(String playerId) {
    if (playerId.isEmpty || playerId == forPlayerId) return false;
    if (diplomacy.hasContact(forPlayerId, playerId)) return true;
    return visibleEnemyUnits.any((unit) => unit.ownerPlayerId == playerId) ||
        rememberedEnemyCities.any((city) => city.ownerPlayerId == playerId);
  }

  bool canTargetPlayer(String playerId) {
    if (playerId.isEmpty || playerId == forPlayerId) return false;

    final status = relationStatusFor(playerId);
    final hasExplicitRelation = hasExplicitDiplomaticRelationWith(playerId);
    if (status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce) {
      return false;
    }
    if (status == DiplomaticRelationStatus.hostile ||
        status == DiplomaticRelationStatus.war) {
      return true;
    }
    if (activeHostilePlayerIds.contains(playerId)) return true;
    if (hasExplicitRelation) return false;
    if (recentHostilePlayerIds.contains(playerId) ||
        pressureTargetPlayerIds.contains(playerId)) {
      return true;
    }
    if (defaultNeutralPlayerIds.contains(playerId)) return false;
    return true;
  }

  factory GameView.fromDomainState(
    DomainState state, {
    required String forPlayerId,
    required int turn,
    required MapReadView mapData,
    required GameRuleset ruleset,
    CanonicalGameSnapshot? engineSnapshot,
    Iterable<String> recentHostilePlayerIds = const [],
    Iterable<String> activeHostilePlayerIds = const [],
    Iterable<String> pressureTargetPlayerIds = const [],
    Iterable<String> defaultNeutralPlayerIds = const [],
    Iterable<PendingCityAttackThreat> pendingCityAttackThreats = const [],
    Iterable<String> forcedVisibleEnemyUnitIds = const [],
    bool ignoreFogOfWar = false,
    bool ignoreDynamicFogOfWar = false,
  }) => _buildGameView(
    _GameViewProjection.fromDomainState(
      state,
      forPlayerId: forPlayerId,
      turn: turn,
      mapData: mapData,
      ruleset: ruleset,
      engineSnapshot: engineSnapshot,
      recentHostilePlayerIds: recentHostilePlayerIds,
      activeHostilePlayerIds: activeHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargetPlayerIds,
      defaultNeutralPlayerIds: defaultNeutralPlayerIds,
      pendingCityAttackThreats: pendingCityAttackThreats,
      forcedVisibleEnemyUnitIds: forcedVisibleEnemyUnitIds,
      ignoreFogOfWar: ignoreFogOfWar,
      ignoreDynamicFogOfWar: ignoreDynamicFogOfWar,
    ),
  );
}

final class _GameViewProjection {
  factory _GameViewProjection.fromDomainState(
    DomainState state, {
    required String forPlayerId,
    required int turn,
    required MapReadView mapData,
    required GameRuleset ruleset,
    required CanonicalGameSnapshot? engineSnapshot,
    Iterable<String> recentHostilePlayerIds = const [],
    Iterable<String> activeHostilePlayerIds = const [],
    Iterable<String> pressureTargetPlayerIds = const [],
    Iterable<String> defaultNeutralPlayerIds = const [],
    Iterable<PendingCityAttackThreat> pendingCityAttackThreats = const [],
    Iterable<String> forcedVisibleEnemyUnitIds = const [],
    bool ignoreFogOfWar = false,
    bool ignoreDynamicFogOfWar = false,
  }) => _GameViewProjection(
    forPlayerId: forPlayerId,
    turn: turn,
    mapData: mapData,
    ruleset: ruleset,
    engineSnapshot: engineSnapshot,
    units: state.units,
    cities: state.cities,
    artifacts: state.artifacts,
    playerGold: state.playerGold,
    playerWarWeariness: state.playerWarWeariness,
    playerStabilityNet: state.playerStabilityNet,
    research: state.research,
    fieldImprovements: state.fieldImprovements,
    strategicResources: state.strategicResources,
    transportNetwork: state.transportNetwork,
    fogOfWar: state.fogOfWar,
    resourceTradeAgreements: state.resourceTradeAgreements,
    mapObjectiveHoldStatesByObjectiveId:
        state.mapObjectiveHoldStatesByObjectiveId,
    diplomacy: state.diplomacy,
    wonderRegistry: state.wonderRegistry,
    recentHostilePlayerIds: recentHostilePlayerIds,
    activeHostilePlayerIds: activeHostilePlayerIds,
    pressureTargetPlayerIds: pressureTargetPlayerIds,
    defaultNeutralPlayerIds: defaultNeutralPlayerIds,
    pendingCityAttackThreats: pendingCityAttackThreats,
    forcedVisibleEnemyUnitIds: forcedVisibleEnemyUnitIds,
    ignoreFogOfWar: ignoreFogOfWar,
    ignoreDynamicFogOfWar: ignoreDynamicFogOfWar,
  );

  _GameViewProjection({
    required this.forPlayerId,
    required this.turn,
    required this.mapData,
    required this.ruleset,
    required this.engineSnapshot,
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.playerGold,
    required this.playerWarWeariness,
    required this.playerStabilityNet,
    required this.research,
    required this.fieldImprovements,
    required this.strategicResources,
    required this.transportNetwork,
    required this.fogOfWar,
    required this.resourceTradeAgreements,
    required this.mapObjectiveHoldStatesByObjectiveId,
    required this.diplomacy,
    required this.wonderRegistry,
    required this.recentHostilePlayerIds,
    required this.activeHostilePlayerIds,
    required this.pressureTargetPlayerIds,
    required this.defaultNeutralPlayerIds,
    required this.pendingCityAttackThreats,
    required Iterable<String> forcedVisibleEnemyUnitIds,
    required this.ignoreFogOfWar,
    required this.ignoreDynamicFogOfWar,
  }) : forcedVisibleEnemyUnitIds = forcedVisibleEnemyUnitIds.toSet();

  final String forPlayerId;
  final int turn;
  final MapReadView mapData;
  final GameRuleset ruleset;
  final CanonicalGameSnapshot? engineSnapshot;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final Map<String, int> playerGold;
  final Map<String, int> playerWarWeariness;
  final Map<String, int> playerStabilityNet;
  final ResearchState research;
  final List<FieldImprovement> fieldImprovements;
  final StrategicResourceAccounts strategicResources;
  final TransportNetworkState transportNetwork;
  final FogOfWarState fogOfWar;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final Map<String, MapObjectiveHoldState> mapObjectiveHoldStatesByObjectiveId;
  final DiplomacyState diplomacy;
  final WonderRegistry wonderRegistry;
  final Iterable<String> recentHostilePlayerIds;
  final Iterable<String> activeHostilePlayerIds;
  final Iterable<String> pressureTargetPlayerIds;
  final Iterable<String> defaultNeutralPlayerIds;
  final Iterable<PendingCityAttackThreat> pendingCityAttackThreats;
  final Set<String> forcedVisibleEnemyUnitIds;
  final bool ignoreFogOfWar;
  final bool ignoreDynamicFogOfWar;

  FogVisibilityQuery get visibility => FogVisibilityQuery(
    playerId: ignoreFogOfWar ? '' : forPlayerId,
    state: fogOfWar,
  );

  FogVisibilityQuery get dynamicVisibility => FogVisibilityQuery(
    playerId: ignoreFogOfWar && ignoreDynamicFogOfWar ? '' : forPlayerId,
    state: fogOfWar,
  );

  List<GameCity> get ownCities => [
    for (final city in cities)
      if (city.ownerPlayerId == forPlayerId) city,
  ];

  List<GameUnit> get ownUnits => [
    for (final unit in units)
      if (unit.ownerPlayerId == forPlayerId) unit,
  ];
}

GameView _buildGameView(_GameViewProjection source) {
  final ownCities = source.ownCities;
  final ownCityIds = {for (final city in ownCities) city.id};
  final ownUnitIds = {for (final unit in source.ownUnits) unit.id};
  final visibility = source.visibility;
  return GameView(
    forPlayerId: source.forPlayerId,
    turn: source.turn,
    ownUnits: source.ownUnits,
    ownCities: ownCities,
    artifacts: _visibleArtifacts(source, ownCityIds, ownUnitIds, visibility),
    ownGold: source.playerGold[source.forPlayerId] ?? 0,
    ownWarWeariness: source.playerWarWeariness[source.forPlayerId] ?? 0,
    ownStabilityNet: source.playerStabilityNet[source.forPlayerId] ?? 0,
    research: source.research,
    ownResearch: source.research.forPlayer(source.forPlayerId),
    ownImprovements: _ownImprovements(source, ownCities, ownCityIds),
    knownImprovements: _knownImprovements(source, ownCities, ownCityIds),
    ownStrategicResources: source.strategicResources.forPlayer(
      source.forPlayerId,
    ),
    transportNetwork: source.transportNetwork,
    resourceTradeAgreements: source.resourceTradeAgreements,
    mapObjectiveHoldStatesByObjectiveId:
        source.mapObjectiveHoldStatesByObjectiveId,
    diplomacy: source.diplomacy,
    visibleEnemyUnits: _visibleEnemyUnits(source),
    movementBlockingUnits: source.units,
    rememberedEnemyCities: _rememberedEnemyCities(source, visibility),
    activeHostilePlayerIds: source.activeHostilePlayerIds,
    recentHostilePlayerIds: source.recentHostilePlayerIds,
    pressureTargetPlayerIds: source.pressureTargetPlayerIds,
    defaultNeutralPlayerIds: source.defaultNeutralPlayerIds,
    pendingCityAttackThreats: source.pendingCityAttackThreats,
    visibility: visibility,
    mapData: source.mapData,
    ruleset: source.ruleset,
    wonderRegistry: source.wonderRegistry,
    engineSnapshot: source.engineSnapshot,
  );
}
