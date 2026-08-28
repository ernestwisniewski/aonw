import '../../cities/read_model/city_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';
import 'map_view.dart';
import 'pending_action_view.dart';

enum VisibleUnitKind {
  commander,
  warrior,
  archer,
  settler,
  worker,
  merchant,
  scout,
  spearman,
  cavalry,
  catapult,
  heavyInfantry,
  fieldCannon,
  rifleman,
  tank,
  scoutShip,
  warship,
  reconPlane,
}

enum VisibleUnitPosture { active, fortified, autoExploring, autoWorking }

final class SessionStampView {
  const SessionStampView({
    required this.revision,
    required this.stateDigest,
    required this.mapHash,
    required this.rulesetHash,
  });

  final int revision;
  final String stateDigest;
  final String mapHash;
  final String rulesetHash;
}

final class VisibleUnitView {
  VisibleUnitView({
    required this.id,
    required this.ownerPlayerId,
    required this.kind,
    required this.name,
    required this.coordinate,
    required this.movementUnits,
    required this.posture,
    List<VisibleArmyTroopView> army = const [],
    this.queuedTarget,
    this.merchantRouteDestinationCityId,
  }) : army = List.unmodifiable(army);

  final String id;
  final String ownerPlayerId;
  final VisibleUnitKind kind;
  final String name;
  final MapHexCoordinate coordinate;
  final int movementUnits;
  final VisibleUnitPosture posture;
  final List<VisibleArmyTroopView> army;
  final MapHexCoordinate? queuedTarget;
  final String? merchantRouteDestinationCityId;
}

final class VisibleArmyTroopView {
  const VisibleArmyTroopView({required this.kind, required this.count});

  final String kind;
  final int count;
}

final class PlayerMapView {
  PlayerMapView({
    required this.actorPlayerId,
    required this.stamp,
    required this.turnView,
    required List<VisibleUnitView> units,
    List<CityView> cities = const [],
    this.cityFoundingDraft,
  }) : units = List.unmodifiable(units),
       cities = List.unmodifiable(cities) {
    final byCoordinate = <MapHexCoordinate, List<VisibleUnitView>>{};
    final controlledById = <String, VisibleUnitView>{};
    for (final unit in units) {
      (byCoordinate[unit.coordinate] ??= []).add(unit);
      if (unit.ownerPlayerId == actorPlayerId) controlledById[unit.id] = unit;
    }
    _unitsByCoordinate = Map.unmodifiable({
      for (final entry in byCoordinate.entries)
        entry.key: List<VisibleUnitView>.unmodifiable(entry.value),
    });
    _controlledUnitsById = Map.unmodifiable(controlledById);
    _citiesByCoordinate = Map.unmodifiable({
      for (final city in cities) city.center: city,
    });
    _citiesById = Map.unmodifiable({for (final city in cities) city.id: city});
    _controlledCitiesById = Map.unmodifiable({
      for (final city in cities)
        if (city.ownerPlayerId == actorPlayerId) city.id: city,
    });
  }

  factory PlayerMapView.preview({
    required String actorPlayerId,
    required SessionStampView stamp,
    required int turn,
    required PendingActionView? pendingAction,
    required List<VisibleUnitView> units,
    List<CityView> cities = const [],
    CityFoundingDraftView? cityFoundingDraft,
  }) => PlayerMapView(
    actorPlayerId: actorPlayerId,
    stamp: stamp,
    turnView: RecipientTurnView(
      number: turn,
      ownState: RecipientTurnStateView.active,
      ownSubmitted: false,
      requiredSubmissionCount: 1,
      submittedCount: 0,
      pendingAction: pendingAction,
      outcome: GameOutcomeView(
        condition: GameOutcomeConditionView.ongoing,
        winnerPlayerId: null,
        scoreByPlayerId: const {},
      ),
    ),
    units: units,
    cities: cities,
    cityFoundingDraft: cityFoundingDraft,
  );

  final String actorPlayerId;
  final SessionStampView stamp;
  final RecipientTurnView turnView;
  final List<VisibleUnitView> units;
  final List<CityView> cities;
  final CityFoundingDraftView? cityFoundingDraft;
  late final Map<MapHexCoordinate, List<VisibleUnitView>> _unitsByCoordinate;
  late final Map<String, VisibleUnitView> _controlledUnitsById;
  late final Map<MapHexCoordinate, CityView> _citiesByCoordinate;
  late final Map<String, CityView> _citiesById;
  late final Map<String, CityView> _controlledCitiesById;

  int get turn => turnView.number;

  PendingActionView? get pendingAction => turnView.pendingAction;

  Iterable<VisibleUnitView> unitsAt(MapHexCoordinate coordinate) =>
      _unitsByCoordinate[coordinate] ?? const <VisibleUnitView>[];

  VisibleUnitView? controlledUnitAt(MapHexCoordinate coordinate) {
    for (final unit in unitsAt(coordinate)) {
      if (unit.ownerPlayerId == actorPlayerId) return unit;
    }
    return null;
  }

  VisibleUnitView? controlledUnitById(String unitId) =>
      _controlledUnitsById[unitId];

  CityView? cityAt(MapHexCoordinate coordinate) =>
      _citiesByCoordinate[coordinate];

  CityView? cityById(String cityId) => _citiesById[cityId];

  CityView? controlledCityById(String cityId) => _controlledCitiesById[cityId];
}
