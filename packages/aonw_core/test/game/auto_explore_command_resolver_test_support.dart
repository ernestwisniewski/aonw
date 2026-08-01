import 'package:aonw_core/domain.dart';

const autoExploreActorId = 'player_1';
const autoExploreOpponentId = 'player_2';
const autoExploreUnitId = 'scout_1';

AutoExploreCommandState autoExploreState({
  required GameUnit scout,
  List<GameUnit> additionalUnits = const [],
  List<GameCity> cities = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  DiplomacyState diplomacy = DiplomacyState.empty,
  DomainActionState interaction = DomainActionState.empty,
}) {
  return AutoExploreCommandState(
    movement: MovementCommandState(
      units: [scout, ...additionalUnits],
      cities: cities,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      playerIds: const [autoExploreActorId, autoExploreOpponentId],
    ),
    interaction: interaction,
  );
}

GameUnit autoExploreScout({
  String id = autoExploreUnitId,
  String ownerPlayerId = autoExploreActorId,
  GameUnitType type = GameUnitType.scout,
  int col = 0,
  int row = 0,
  int movementPoints = 5,
  UnitPosture posture = UnitPosture.active,
  String? excavatingArtifactId,
  String? carriedArtifactId,
  QueuedMovePath? queuedPath,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: id,
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
    excavatingArtifactId: excavatingArtifactId,
    carriedArtifactId: carriedArtifactId,
    queuedPath: queuedPath,
  );
}

QueuedMovePath autoExploreQueuedPath({int targetCol = 2}) {
  return QueuedMovePath(
    targetCol: targetCol,
    targetRow: 0,
    steps: [
      for (var col = 0; col <= targetCol; col++)
        UnitMovementStep(
          col: col,
          row: 0,
          enterCost: col == 0 ? 0 : 1,
          cumulativeCost: col,
        ),
    ],
  );
}

FogOfWarState autoExploreFog({
  required Set<HexCoordinate> visible,
  Set<HexCoordinate>? discovered,
}) {
  return FogOfWarState(
    players: {
      autoExploreActorId: PlayerFogOfWar(
        playerId: autoExploreActorId,
        discoveredHexes: discovered ?? visible,
        visibleHexes: visible,
      ),
    },
  );
}

MapTraversalView autoExploreMap({
  required int cols,
  int rows = 1,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

DomainActionState ownedAutoExploreInteraction() {
  return DomainActionState(
    cityFoundingDraft: CityFoundingDraft(
      unitId: autoExploreUnitId,
      ownerPlayerId: autoExploreActorId,
      center: const CityHex(col: 0, row: 0),
    ),
    pendingAction: const PendingUnitTurnSkip(
      ownerPlayerId: autoExploreActorId,
      unitId: autoExploreUnitId,
      restoreMovementPoints: 5,
    ),
  );
}

DomainActionState unrelatedAutoExploreInteraction() {
  return DomainActionState(
    cityFoundingDraft: CityFoundingDraft(
      unitId: 'other_unit',
      ownerPlayerId: autoExploreActorId,
      center: const CityHex(col: 0, row: 0),
    ),
    pendingAction: const PendingResearchSelection(
      ownerPlayerId: autoExploreActorId,
    ),
  );
}

AutoExploreCommandResult resolveAutoExplore(
  AutoExploreCommandState state,
  MapTraversalView map, {
  String unitId = autoExploreUnitId,
  String actorPlayerId = autoExploreActorId,
  AutoExploreCommandPhase phase = AutoExploreCommandPhase.direct,
  bool canAct = true,
}) {
  return const AutoExploreCommandResolver().resolve(
    state: state,
    command: AutoExploreUnitCommand(unitId),
    actorPlayerId: actorPlayerId,
    mapData: map,
    phase: phase,
    canAct: canAct,
  );
}

List<(int, int)> autoExploreStepCoordinates(Iterable<UnitMovementStep> steps) =>
    [for (final step in steps) (step.col, step.row)];
