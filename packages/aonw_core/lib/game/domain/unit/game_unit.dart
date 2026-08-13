import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit/army_troop.dart';
import 'package:aonw_core/game/domain/unit/city_founding_job.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/merchant_trade_route.dart';
import 'package:aonw_core/game/domain/unit/worker_assignment.dart';
import 'package:aonw_core/game/domain/unit/worker_improvement_charge_rules.dart';
import 'package:aonw_core/game/domain/unit/worker_job.dart';

part 'game_unit_json_codec.dart';

enum UnitPosture {
  active,
  fortified,
  autoExploring,
  autoWorking;

  static UnitPosture fromJson(Object? value) {
    if (value is String && value.isNotEmpty) {
      return UnitPosture.values.byName(value);
    }
    return UnitPosture.active;
  }
}

class GameUnit {
  static const Object _unset = Object();

  final String id;
  final String ownerPlayerId;
  final GameUnitType type;
  final String name;
  final int col;
  final int row;
  final int movementUnits;
  final List<ArmyTroop> army;
  final QueuedMovePath? queuedPath;
  final MerchantTradeRoute? merchantTradeRoute;
  final WorkerJob? workerJob;
  final int workerBuildCharges;
  final CityFoundingJob? cityFoundingJob;
  final WorkerAssignment? workerAssignment;
  final int? hitPoints;
  final int experiencePoints;
  final UnitPosture posture;
  final String? carriedArtifactId;
  final String? excavatingArtifactId;

  GameUnit({
    required this.id,
    required this.ownerPlayerId,
    required this.type,
    required this.name,
    required this.col,
    required this.row,
    int? movementPoints,
    int? movementUnits,
    List<ArmyTroop> army = const [],
    this.queuedPath,
    this.merchantTradeRoute,
    this.workerJob,
    int? workerBuildCharges,
    this.cityFoundingJob,
    this.workerAssignment,
    this.hitPoints,
    this.experiencePoints = 0,
    this.posture = UnitPosture.active,
    this.carriedArtifactId,
    this.excavatingArtifactId,
  }) : assert(movementPoints == null || movementUnits == null),
       movementUnits =
           movementUnits ??
           MovementPointScale.unitsFromWholePoints(
             movementPoints ??
                 UnitMovementBalance.maxMovementPointsFor(
                   type: type,
                   carriedArtifactId: carriedArtifactId,
                 ),
           ),
       workerBuildCharges = WorkerImprovementChargeRules.normalize(
         type: type,
         charges: workerBuildCharges,
       ),
       army = List.unmodifiable(army);

  static GameUnit startingCommander({
    required String ownerPlayerId,
    int col = 0,
    int row = 0,
    List<ArmyTroop> army = const [],
  }) => GameUnit(
    id: 'commander_$ownerPlayerId',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.commander,
    name: GameUnitType.commander.defaultNameToken,
    col: col,
    row: row,
    army: army,
  );

  static GameUnit startingWarrior({
    required String ownerPlayerId,
    int col = 0,
    int row = 0,
  }) => GameUnit(
    id: 'warrior_$ownerPlayerId',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
  );

  factory GameUnit.produced({
    required String id,
    required String ownerPlayerId,
    required GameUnitType type,
    required int col,
    required int row,
  }) {
    return GameUnit(
      id: id,
      ownerPlayerId: ownerPlayerId,
      type: type,
      name: type.defaultNameToken,
      col: col,
      row: row,
    );
  }

  factory GameUnit.fromJson(Map<String, dynamic> json) =>
      _GameUnitJsonCodec.fromJson(json);

  Map<String, dynamic> toJson() => _GameUnitJsonCodec.toJson(this);

  GameUnit copyWith({
    String? id,
    String? ownerPlayerId,
    GameUnitType? type,
    String? name,
    int? col,
    int? row,
    int? movementPoints,
    int? movementUnits,
    List<ArmyTroop>? army,
    QueuedMovePath? queuedPath,
    MerchantTradeRoute? merchantTradeRoute,
    WorkerJob? workerJob,
    int? workerBuildCharges,
    CityFoundingJob? cityFoundingJob,
    WorkerAssignment? workerAssignment,
    int? hitPoints,
    int? experiencePoints,
    UnitPosture? posture,
    Object? carriedArtifactId = _unset,
    Object? excavatingArtifactId = _unset,
  }) {
    assert(movementPoints == null || movementUnits == null);
    return _copyWithNullable(
      id: id,
      ownerPlayerId: ownerPlayerId,
      type: type,
      name: name,
      col: col,
      row: row,
      movementPoints: movementPoints,
      movementUnits: movementUnits,
      army: army,
      queuedPath: queuedPath ?? _unset,
      merchantTradeRoute: merchantTradeRoute ?? _unset,
      workerJob: workerJob ?? _unset,
      workerBuildCharges: workerBuildCharges,
      cityFoundingJob: cityFoundingJob ?? _unset,
      workerAssignment: workerAssignment ?? _unset,
      hitPoints: hitPoints ?? _unset,
      experiencePoints: experiencePoints,
      posture: posture,
      carriedArtifactId: carriedArtifactId,
      excavatingArtifactId: excavatingArtifactId,
    );
  }

  GameUnit _copyWithNullable({
    String? id,
    String? ownerPlayerId,
    GameUnitType? type,
    String? name,
    int? col,
    int? row,
    int? movementPoints,
    int? movementUnits,
    List<ArmyTroop>? army,
    Object? queuedPath = _unset,
    Object? merchantTradeRoute = _unset,
    Object? workerJob = _unset,
    int? workerBuildCharges,
    Object? cityFoundingJob = _unset,
    Object? workerAssignment = _unset,
    Object? hitPoints = _unset,
    int? experiencePoints,
    UnitPosture? posture,
    Object? carriedArtifactId = _unset,
    Object? excavatingArtifactId = _unset,
  }) {
    return GameUnit(
      id: id ?? this.id,
      ownerPlayerId: ownerPlayerId ?? this.ownerPlayerId,
      type: type ?? this.type,
      name: name ?? this.name,
      col: col ?? this.col,
      row: row ?? this.row,
      movementUnits: _movementUnitsForCopy(this, movementPoints, movementUnits),
      army: army ?? this.army,
      queuedPath: identical(queuedPath, _unset)
          ? this.queuedPath
          : queuedPath as QueuedMovePath?,
      merchantTradeRoute: identical(merchantTradeRoute, _unset)
          ? this.merchantTradeRoute
          : merchantTradeRoute as MerchantTradeRoute?,
      workerJob: identical(workerJob, _unset)
          ? this.workerJob
          : workerJob as WorkerJob?,
      workerBuildCharges: workerBuildCharges ?? this.workerBuildCharges,
      cityFoundingJob: identical(cityFoundingJob, _unset)
          ? this.cityFoundingJob
          : cityFoundingJob as CityFoundingJob?,
      workerAssignment: identical(workerAssignment, _unset)
          ? this.workerAssignment
          : workerAssignment as WorkerAssignment?,
      hitPoints: identical(hitPoints, _unset)
          ? this.hitPoints
          : hitPoints as int?,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      posture: posture ?? this.posture,
      carriedArtifactId: identical(carriedArtifactId, _unset)
          ? this.carriedArtifactId
          : carriedArtifactId as String?,
      excavatingArtifactId: identical(excavatingArtifactId, _unset)
          ? this.excavatingArtifactId
          : excavatingArtifactId as String?,
    );
  }

  /// Use this to set OR clear queuedPath.
  GameUnit copyWithQueuedPath(QueuedMovePath? path) =>
      _copyWithNullable(queuedPath: path);

  /// Use this to set OR clear merchantTradeRoute.
  GameUnit copyWithMerchantTradeRoute(MerchantTradeRoute? route) =>
      _copyWithNullable(merchantTradeRoute: route);

  /// Use this to set OR clear workerJob.
  GameUnit copyWithWorkerJob(WorkerJob? job) =>
      _copyWithNullable(workerJob: job);

  GameUnit copyWithWorkerBuildCharges(int charges) =>
      _copyWithNullable(workerBuildCharges: charges);

  GameUnit copyWithMovementUnits(int units) =>
      _copyWithNullable(movementUnits: units);

  /// Use this to set OR clear cityFoundingJob.
  GameUnit copyWithCityFoundingJob(CityFoundingJob? job) =>
      _copyWithNullable(cityFoundingJob: job);

  /// Use this to set OR clear workerAssignment.
  GameUnit copyWithWorkerAssignment(WorkerAssignment? assignment) =>
      _copyWithNullable(workerAssignment: assignment);

  /// Use this to set OR clear combat HP.
  GameUnit copyWithHitPoints(int? hitPoints) =>
      _copyWithNullable(hitPoints: hitPoints);

  GameUnit copyWithPosture(UnitPosture posture) =>
      _copyWithNullable(posture: posture);

  GameUnit copyWithCarriedArtifact(String? artifactId) =>
      _copyWithNullable(carriedArtifactId: artifactId);

  GameUnit copyWithExcavatingArtifact(String? artifactId) =>
      _copyWithNullable(excavatingArtifactId: artifactId);

  bool occupies(int targetCol, int targetRow) =>
      col == targetCol && row == targetRow;

  HexCoordinate get coordinate => HexCoordinate(col: col, row: row);

  int get movementPoints =>
      MovementPointScale.wholePointsFromUnits(movementUnits);

  int get movementSubpoints =>
      movementUnits.remainder(MovementPointScale.unitsPerPoint);

  num get exactMovementPoints =>
      MovementPointScale.displayPointsFromUnits(movementUnits);

  bool get hasMovementRemaining => movementUnits > 0;

  bool get isWorker => type == GameUnitType.worker;

  bool get isMerchant => type == GameUnitType.merchant;

  bool get hasActiveWorkerJob => workerJob != null;

  bool get hasWorkerAssignment => workerAssignment != null;

  bool get isWorking =>
      workerJob != null ||
      cityFoundingJob != null ||
      workerAssignment != null ||
      excavatingArtifactId != null;

  bool get isReadyToAct =>
      !isWorking &&
      !isAutoWorking &&
      hasMovementRemaining &&
      queuedPath == null;

  bool get isCarryingArtifact => carriedArtifactId != null;

  bool get isFortified => posture == UnitPosture.fortified;
  bool get isAutoExploring => posture == UnitPosture.autoExploring;
  bool get isAutoWorking => posture == UnitPosture.autoWorking;

  int troopCount(TroopType type) {
    for (final troop in army) {
      if (troop.type == type) return troop.count;
    }
    return 0;
  }

  bool get hasSettlers => troopCount(TroopType.settler) > 0;

  bool canDetachTroop(TroopType type) =>
      this.type == GameUnitType.commander && troopCount(type) > 0;

  GameUnit consumeSettler() {
    final updated = <ArmyTroop>[];
    var consumed = false;
    for (final troop in army) {
      if (!consumed && troop.type == TroopType.settler && troop.count > 0) {
        consumed = true;
        final remaining = troop.count - 1;
        if (remaining > 0) {
          updated.add(ArmyTroop(type: troop.type, count: remaining));
        }
        continue;
      }
      updated.add(troop);
    }
    if (!consumed) return this;
    return copyWith(army: updated);
  }

  GameUnit detachTroop(TroopType type) {
    if (!canDetachTroop(type)) return this;

    final updated = <ArmyTroop>[];
    var detached = false;
    for (final troop in army) {
      if (!detached && troop.type == type && troop.count > 0) {
        detached = true;
        final remaining = troop.count - 1;
        if (remaining > 0) {
          updated.add(ArmyTroop(type: troop.type, count: remaining));
        }
        continue;
      }
      updated.add(troop);
    }
    return copyWith(army: updated);
  }

  @override
  bool operator ==(Object other) {
    return other is GameUnit &&
        other.id == id &&
        other.ownerPlayerId == ownerPlayerId &&
        other.type == type &&
        other.name == name &&
        other.col == col &&
        other.row == row &&
        other.movementUnits == movementUnits &&
        _sameArmy(other.army, army) &&
        other.queuedPath == queuedPath &&
        other.merchantTradeRoute == merchantTradeRoute &&
        other.workerJob == workerJob &&
        other.workerBuildCharges == workerBuildCharges &&
        other.cityFoundingJob == cityFoundingJob &&
        other.workerAssignment == workerAssignment &&
        other.hitPoints == hitPoints &&
        other.experiencePoints == experiencePoints &&
        other.posture == posture &&
        other.carriedArtifactId == carriedArtifactId &&
        other.excavatingArtifactId == excavatingArtifactId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerPlayerId,
    type,
    name,
    col,
    row,
    movementUnits,
    Object.hashAll(army),
    queuedPath,
    merchantTradeRoute,
    workerJob,
    workerBuildCharges,
    cityFoundingJob,
    workerAssignment,
    hitPoints,
    experiencePoints,
    posture,
    carriedArtifactId,
    excavatingArtifactId,
  );

  @override
  String toString() {
    return 'GameUnit(id: $id, ownerPlayerId: $ownerPlayerId, type: $type, '
        'name: $name, col: $col, row: $row, movementUnits: $movementUnits, '
        'army: $army, queuedPath: $queuedPath, '
        'merchantTradeRoute: $merchantTradeRoute, workerJob: $workerJob, '
        'workerBuildCharges: $workerBuildCharges, '
        'cityFoundingJob: $cityFoundingJob, '
        'workerAssignment: $workerAssignment, hitPoints: $hitPoints, '
        'experiencePoints: $experiencePoints, posture: $posture, '
        'carriedArtifactId: $carriedArtifactId, '
        'excavatingArtifactId: $excavatingArtifactId)';
  }

  static bool _sameArmy(List<ArmyTroop> left, List<ArmyTroop> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }
}

int _movementUnitsForCopy(
  GameUnit unit,
  int? movementPoints,
  int? movementUnits,
) {
  assert(movementPoints == null || movementUnits == null);
  if (movementPoints != null) {
    return MovementPointScale.unitsFromWholePoints(movementPoints);
  }
  return movementUnits ?? unit.movementUnits;
}
