import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../cities/read_model/city_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';
import '../../workers/infrastructure/worker_view_mapper.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';
import 'pending_action_view_mapper.dart';

final class PlayerMapViewMapper {
  const PlayerMapViewMapper({
    PendingActionViewMapper pendingActionMapper =
        const PendingActionViewMapper(),
    WorkerViewMapper workerMapper = const WorkerViewMapper(),
  }) : _pendingActionMapper = pendingActionMapper,
       _workerMapper = workerMapper;

  final PendingActionViewMapper _pendingActionMapper;
  final WorkerViewMapper _workerMapper;

  PlayerMapView fromWire(
    AonwPlayerViewSnapshot wire, {
    required MapView map,
    required String actorPlayerId,
  }) {
    _validateSnapshot(wire, map: map, actorPlayerId: actorPlayerId);
    final units = _mapUnits(wire.units, map);
    final pendingAction = _pendingActionMapper.fromWire(
      wire.pendingAction,
      actorPlayerId: actorPlayerId,
      units: units,
      map: map,
    );
    return PlayerMapView(
      actorPlayerId: actorPlayerId,
      stamp: _mapStamp(wire.stamp),
      turnView: RecipientTurnView(
        number: wire.turn,
        ownState: switch (wire.turnLifecycle.ownState) {
          AonwPlayerTurnState.active => RecipientTurnStateView.active,
          AonwPlayerTurnState.finished => RecipientTurnStateView.finished,
          null => null,
        },
        ownSubmitted: wire.turnLifecycle.ownSubmitted,
        requiredSubmissionCount: wire.turnLifecycle.requiredSubmissionCount,
        submittedCount: wire.turnLifecycle.submittedCount,
        pendingAction: pendingAction,
        outcome: GameOutcomeView(
          condition: GameOutcomeConditionView.values.byName(
            wire.outcome.condition.name,
          ),
          winnerPlayerId: wire.outcome.winnerPlayerId,
          scoreByPlayerId: wire.outcome.scoreByPlayerId,
        ),
      ),
      units: units,
      cities: [for (final city in wire.cities) _mapCity(city)],
      fieldImprovements: [
        for (final improvement in wire.fieldImprovements)
          _workerMapper.fieldImprovement(improvement, map),
      ],
      roads: [for (final road in wire.roads) _workerMapper.road(road, map)],
      cityFoundingDraft: wire.cityFoundingDraft == null
          ? null
          : _mapCityFoundingDraft(wire.cityFoundingDraft!),
    );
  }

  static void _validateSnapshot(
    AonwPlayerViewSnapshot wire, {
    required MapView map,
    required String actorPlayerId,
  }) {
    if (actorPlayerId.isEmpty) {
      throw const FormatException('Session actor player id is empty.');
    }
    _validateStamp(wire.stamp);
    if (wire.stamp.mapHash != map.contentHash) {
      throw const FormatException('Session snapshot belongs to another map.');
    }
    if (wire.turn < 1) {
      throw const FormatException('Session snapshot turn is not positive.');
    }
  }

  static void _validateStamp(AonwSessionStamp stamp) {
    _validateHash(stamp.stateDigest, 'state digest');
    _validateHash(stamp.mapHash, 'map hash');
    _validateHash(stamp.rulesetHash, 'ruleset hash');
  }

  List<VisibleUnitView> _mapUnits(
    List<AonwPlayerUnitView> source,
    MapView map,
  ) {
    final units = <VisibleUnitView>[];
    String? previousId;
    for (final unit in source) {
      _validateUnit(unit, previousId: previousId, map: map);
      units.add(_mapUnit(unit, map));
      previousId = unit.id;
    }
    return units;
  }

  static void _validateUnit(
    AonwPlayerUnitView unit, {
    required String? previousId,
    required MapView map,
  }) {
    if (unit.id.isEmpty || unit.ownerPlayerId.isEmpty || unit.name.isEmpty) {
      throw const FormatException(
        'Session snapshot contains an empty unit field.',
      );
    }
    if (previousId != null && previousId.compareTo(unit.id) >= 0) {
      throw const FormatException(
        'Session snapshot unit identifiers are not unique and ordered.',
      );
    }
    if (!map.contains(_coordinate(unit))) {
      throw const FormatException('Session snapshot unit is outside the map.');
    }
  }

  VisibleUnitView _mapUnit(AonwPlayerUnitView unit, MapView map) =>
      VisibleUnitView(
        id: unit.id,
        ownerPlayerId: unit.ownerPlayerId,
        kind: _kind(unit.kind),
        name: unit.name,
        coordinate: _coordinate(unit),
        movementUnits: unit.movementUnits,
        posture: _posture(unit.posture),
        army: [
          for (final troop
              in unit.ownedDetails?.army ?? const <AonwArmyTroop>[])
            VisibleArmyTroopView(kind: troop.kind.name, count: troop.count),
        ],
        queuedTarget: unit.ownedDetails?.queuedPath == null
            ? null
            : (
                col: unit.ownedDetails!.queuedPath!.target.col,
                row: unit.ownedDetails!.queuedPath!.target.row,
              ),
        merchantRouteDestinationCityId:
            unit.ownedDetails?.merchantTradeRoute?.destinationCityId,
        workerBuildCharges: unit.workerBuildCharges,
        workerJob: _workerMapper.job(unit.workerJob, map),
        workerAssignment: unit.workerAssignment == null
            ? null
            : _ownedCoordinate(unit.workerAssignment!, map),
      );

  static CityView _mapCity(AonwPlayerCityView city) => CityView(
    id: city.id,
    ownerPlayerId: city.ownerPlayerId,
    name: city.name,
    center: _cityCoordinate(city.center),
    visibleControlledHexes: [
      for (final coordinate in city.visibleControlledHexes)
        _cityCoordinate(coordinate),
    ],
    hitPoints: city.hitPoints,
    ownedDetails: city.ownedDetails == null
        ? null
        : OwnedCityDetailsView(
            population: city.ownedDetails!.population,
            storedFood: city.ownedDetails!.storedFood,
            maxHexes: city.ownedDetails!.maxHexes,
            territoryRadius: city.ownedDetails!.territoryRadius,
            workedHexes: [
              for (final coordinate in city.ownedDetails!.workedHexes)
                _cityCoordinate(coordinate),
            ],
            preferredExpansionHex:
                city.ownedDetails!.preferredExpansionHex == null
                ? null
                : _cityCoordinate(city.ownedDetails!.preferredExpansionHex!),
            buildings: [
              for (final building in city.ownedDetails!.buildings)
                building.name,
            ],
            wonders: [
              for (final wonder in city.ownedDetails!.wonders) wonder.name,
            ],
            productionQueue: city.ownedDetails!.productionQueue == null
                ? null
                : _mapProductionQueue(city.ownedDetails!.productionQueue!),
            productionOverflow: city.ownedDetails!.productionOverflow,
            specialization: city.ownedDetails!.specialization?.name,
          ),
  );

  static CityProductionQueueView _mapProductionQueue(
    AonwCityProductionQueue value,
  ) => CityProductionQueueView(
    targetKind: value.target.kind.name,
    target: switch (value.target.kind) {
      AonwCityProductionTargetKind.building => value.target.buildingType!.name,
      AonwCityProductionTargetKind.unit => value.target.unitType!.name,
      AonwCityProductionTargetKind.project => value.target.projectType!.name,
      AonwCityProductionTargetKind.wonder => value.target.wonderType!.name,
    },
    investedProduction: value.investedProduction,
    resourceAllocation: {
      for (final entry in value.resourceAllocation.entries)
        MapResource.values.byName(entry.key.name): entry.value,
    },
  );

  static CityFoundingDraftView _mapCityFoundingDraft(
    AonwCityFoundingDraft draft,
  ) => CityFoundingDraftView(
    founderUnitId: draft.founderUnitId,
    center: _cityCoordinate(draft.center),
    controlledHexes: [
      for (final coordinate in draft.controlledHexes)
        _cityCoordinate(coordinate),
    ],
  );

  static SessionStampView _mapStamp(AonwSessionStamp stamp) => SessionStampView(
    revision: stamp.revision,
    stateDigest: stamp.stateDigest,
    mapHash: stamp.mapHash,
    rulesetHash: stamp.rulesetHash,
  );

  static ({int col, int row}) _coordinate(AonwPlayerUnitView unit) =>
      (col: unit.coordinate.col, row: unit.coordinate.row);

  static MapHexCoordinate _cityCoordinate(AonwCoordinate coordinate) =>
      (col: coordinate.col, row: coordinate.row);

  static MapHexCoordinate _ownedCoordinate(
    AonwCoordinate coordinate,
    MapView map,
  ) {
    final value = _cityCoordinate(coordinate);
    if (!map.contains(value)) {
      throw const FormatException('Owned unit coordinate is outside the map.');
    }
    return value;
  }

  static void _validateHash(String value, String label) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw FormatException('Session $label is not a canonical digest.');
    }
  }

  static VisibleUnitKind _kind(AonwUnitKind value) =>
      VisibleUnitKind.values.byName(value.name);

  static VisibleUnitPosture _posture(AonwUnitPosture value) =>
      VisibleUnitPosture.values.byName(value.name);
}
