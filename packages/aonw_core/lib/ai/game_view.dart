import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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
  final MapData mapData;
  final GameRuleset ruleset;

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
  }) : ownUnits = List.unmodifiable(ownUnits),
       ownCities = List.unmodifiable(ownCities),
       artifacts = List.unmodifiable(artifacts),
       ownImprovements = List.unmodifiable(ownImprovements),
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

  factory GameView.fromPersistentState(
    PersistentGameState state, {
    required String forPlayerId,
    required int turn,
    required MapData mapData,
    required GameRuleset ruleset,
    Iterable<String> recentHostilePlayerIds = const [],
    Iterable<String> activeHostilePlayerIds = const [],
    Iterable<String> pressureTargetPlayerIds = const [],
    Iterable<String> defaultNeutralPlayerIds = const [],
    Iterable<PendingCityAttackThreat> pendingCityAttackThreats = const [],
    Iterable<String> forcedVisibleEnemyUnitIds = const [],
    bool ignoreFogOfWar = false,
    bool ignoreDynamicFogOfWar = false,
  }) {
    final visibility = FogVisibilityQuery(
      playerId: ignoreFogOfWar ? '' : forPlayerId,
      state: state.fogOfWar,
    );
    final dynamicVisibility = FogVisibilityQuery(
      playerId: ignoreFogOfWar && ignoreDynamicFogOfWar ? '' : forPlayerId,
      state: state.fogOfWar,
    );
    final ownCities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == forPlayerId) city,
    ];
    final ownCityIds = {for (final city in ownCities) city.id};
    final ownUnitIds = {
      for (final unit in state.units)
        if (unit.ownerPlayerId == forPlayerId) unit.id,
    };
    final forcedVisibleUnitIds = forcedVisibleEnemyUnitIds.toSet();

    return GameView(
      forPlayerId: forPlayerId,
      turn: turn,
      ownUnits: [
        for (final unit in state.units)
          if (unit.ownerPlayerId == forPlayerId) unit,
      ],
      ownCities: ownCities,
      artifacts: [
        for (final artifact in state.artifacts)
          if (_canSeeArtifact(
            artifact,
            cities: state.cities,
            units: state.units,
            ownCityIds: ownCityIds,
            ownUnitIds: ownUnitIds,
            visibility: visibility,
          ))
            artifact,
      ],
      ownGold: state.playerGold[forPlayerId] ?? 0,
      ownWarWeariness: state.playerWarWeariness[forPlayerId] ?? 0,
      ownStabilityNet: state.playerStabilityNet[forPlayerId] ?? 0,
      research: state.research,
      ownResearch: state.research.forPlayer(forPlayerId),
      ownImprovements: [
        for (final improvement in state.fieldImprovements)
          if (_isOwnImprovement(improvement, ownCities, ownCityIds))
            improvement,
      ],
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
      mapObjectiveHoldStatesByObjectiveId:
          state.runtimeState.mapObjectiveHoldStatesByObjectiveId,
      diplomacy: state.runtimeState.diplomacy,
      visibleEnemyUnits: [
        for (final unit in state.units)
          if (unit.ownerPlayerId != forPlayerId &&
              (dynamicVisibility.canSeeDynamicAt(unit.col, unit.row) ||
                  forcedVisibleUnitIds.contains(unit.id)))
            unit,
      ],
      movementBlockingUnits: state.units,
      rememberedEnemyCities: [
        for (final city in state.cities)
          if (city.ownerPlayerId != forPlayerId &&
              visibility.canRememberStaticAt(city.center.col, city.center.row))
            city,
      ],
      activeHostilePlayerIds: activeHostilePlayerIds,
      recentHostilePlayerIds: recentHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargetPlayerIds,
      defaultNeutralPlayerIds: defaultNeutralPlayerIds,
      pendingCityAttackThreats: pendingCityAttackThreats,
      visibility: visibility,
      mapData: mapData,
      ruleset: ruleset,
    );
  }

  static bool _isOwnImprovement(
    FieldImprovement improvement,
    List<GameCity> ownCities,
    Set<String> ownCityIds,
  ) {
    final builtByCityId = improvement.builtByCityId;
    if (builtByCityId != null) return ownCityIds.contains(builtByCityId);
    return ownCities.any((city) => city.controlsHex(improvement.hex));
  }

  static bool _canSeeArtifact(
    WorldArtifact artifact, {
    required List<GameCity> cities,
    required List<GameUnit> units,
    required Set<String> ownCityIds,
    required Set<String> ownUnitIds,
    required FogVisibilityQuery visibility,
  }) {
    final location = artifact.location;
    switch (location.kind) {
      case WorldArtifactLocationKind.map:
      case WorldArtifactLocationKind.excavation:
        final col = location.col;
        final row = location.row;
        return col != null &&
            row != null &&
            visibility.canSeeDynamicAt(col, row);
      case WorldArtifactLocationKind.carried:
        final unitId = location.unitId;
        if (unitId == null) return false;
        if (ownUnitIds.contains(unitId)) return true;
        final unit = units.byId(unitId);
        return unit != null && visibility.canSeeDynamicAt(unit.col, unit.row);
      case WorldArtifactLocationKind.stored:
        final cityId = location.cityId;
        if (cityId == null) return false;
        if (ownCityIds.contains(cityId)) return true;
        final city = cities.byId(cityId);
        return city != null &&
            visibility.canSeeDynamicAt(city.center.col, city.center.row);
    }
  }
}
