import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/util/collection_equality.dart';

typedef _PendingPlayerActionParser =
    PendingPlayerAction Function(
      Map<String, dynamic> json,
      String ownerPlayerId,
    );

enum GameInteractionMode {
  standard,
  moveTargeting,
  unitTurnSkip,
  cityFounding,
  cityWorkedHexSelection,
  cityExpansionSelection,
  workerAction,
  merchantTradeRouteSelection,
  merchantMoveToCitySelection,
  attackTargeting,
  commanderMerge,
  researchSelection,
}

sealed class PendingPlayerAction {
  const PendingPlayerAction();

  String get ownerPlayerId;

  GameInteractionMode get mode;

  bool ownsUnit(String unitId) => false;

  String get jsonType => switch (mode) {
    GameInteractionMode.cityWorkedHexSelection => 'cityWorkedHexSelection',
    GameInteractionMode.cityExpansionSelection => 'cityExpansionSelection',
    GameInteractionMode.workerAction => 'workerActionSelection',
    GameInteractionMode.merchantTradeRouteSelection =>
      'merchantTradeRouteSelection',
    GameInteractionMode.merchantMoveToCitySelection =>
      'merchantMoveToCitySelection',
    GameInteractionMode.unitTurnSkip => 'unitTurnSkip',
    GameInteractionMode.attackTargeting => 'attackTargeting',
    GameInteractionMode.commanderMerge => 'commanderMergeSelection',
    GameInteractionMode.researchSelection => 'researchSelection',
    _ => throw StateError('Unsupported pending action mode: $mode'),
  };

  Map<String, dynamic> get jsonFields => const {};

  List<Object?> get equalityFields => const [];

  Map<String, dynamic> toJson() => {
    'type': jsonType,
    'ownerPlayerId': ownerPlayerId,
    ...jsonFields,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is PendingPlayerAction &&
          other.ownerPlayerId == ownerPlayerId &&
          listEquals(other.equalityFields, equalityFields);

  @override
  int get hashCode =>
      Object.hash(runtimeType, ownerPlayerId, Object.hashAll(equalityFields));

  static PendingPlayerAction fromJson(Map<String, dynamic> json) {
    final type = _stringField(json, 'type');
    final parser = _parsers[type];
    if (parser == null) {
      throw ArgumentError('Unknown PendingPlayerAction type: "$type"');
    }
    return parser(json, _stringField(json, 'ownerPlayerId'));
  }

  static final Map<String, _PendingPlayerActionParser> _parsers = {
    'researchSelection': (_, ownerPlayerId) =>
        PendingResearchSelection(ownerPlayerId: ownerPlayerId),
    'cityWorkedHexSelection': (json, ownerPlayerId) =>
        PendingCityWorkedHexSelection(
          ownerPlayerId: ownerPlayerId,
          cityId: _stringField(json, 'cityId'),
        ),
    'cityExpansionSelection': (json, ownerPlayerId) =>
        PendingCityExpansionSelection(
          ownerPlayerId: ownerPlayerId,
          cityId: _stringField(json, 'cityId'),
        ),
    'workerActionSelection': (json, ownerPlayerId) =>
        PendingWorkerActionSelection(
          ownerPlayerId: ownerPlayerId,
          unitId: _stringField(json, 'unitId'),
          improvementType: _fieldImprovementType(json['improvementType']),
        ),
    'merchantTradeRouteSelection': (json, ownerPlayerId) =>
        PendingMerchantTradeRouteSelection(
          ownerPlayerId: ownerPlayerId,
          unitId: _stringField(json, 'unitId'),
        ),
    'merchantMoveToCitySelection': (json, ownerPlayerId) =>
        PendingMerchantMoveToCitySelection(
          ownerPlayerId: ownerPlayerId,
          unitId: _stringField(json, 'unitId'),
        ),
    'unitTurnSkip': (json, ownerPlayerId) => PendingUnitTurnSkip(
      ownerPlayerId: ownerPlayerId,
      unitId: _stringField(json, 'unitId'),
      restoreMovementPoints: _intField(json, 'restoreMovementPoints'),
    ),
    'unitSleep': (json, ownerPlayerId) => PendingUnitTurnSkip(
      ownerPlayerId: ownerPlayerId,
      unitId: _stringField(json, 'unitId'),
      restoreMovementPoints: _intField(json, 'restoreMovementPoints'),
    ),
    'attackTargeting': (json, ownerPlayerId) => PendingAttackTargeting(
      ownerPlayerId: ownerPlayerId,
      attackerUnitId: _stringField(json, 'attackerUnitId'),
      defenderCol: _optionalIntField(json, 'defenderCol'),
      defenderRow: _optionalIntField(json, 'defenderRow'),
    ),
    'commanderMergeSelection': (json, ownerPlayerId) =>
        PendingCommanderMergeSelection(
          ownerPlayerId: ownerPlayerId,
          commanderUnitId: _stringField(json, 'commanderUnitId'),
        ),
  };

  static String _stringField(Map<String, dynamic> json, String field) {
    return json[field] as String;
  }

  static int _intField(Map<String, dynamic> json, String field) {
    return (json[field] as num).toInt();
  }

  static int? _optionalIntField(Map<String, dynamic> json, String field) {
    final value = json[field];
    return value is num ? value.toInt() : null;
  }

  static FieldImprovementType? _fieldImprovementType(Object? value) {
    return switch (value) {
      final String name => FieldImprovementType.values.byName(name),
      _ => null,
    };
  }
}

final class PendingResearchSelection extends PendingPlayerAction {
  const PendingResearchSelection({required this.ownerPlayerId});

  @override
  final String ownerPlayerId;

  @override
  GameInteractionMode get mode => GameInteractionMode.researchSelection;
}

final class PendingCityWorkedHexSelection extends PendingPlayerAction {
  const PendingCityWorkedHexSelection({
    required this.ownerPlayerId,
    required this.cityId,
  });

  @override
  final String ownerPlayerId;
  final String cityId;

  @override
  GameInteractionMode get mode => GameInteractionMode.cityWorkedHexSelection;

  @override
  Map<String, dynamic> get jsonFields => {'cityId': cityId};

  @override
  List<Object?> get equalityFields => [cityId];
}

final class PendingCityExpansionSelection extends PendingPlayerAction {
  const PendingCityExpansionSelection({
    required this.ownerPlayerId,
    required this.cityId,
  });

  @override
  final String ownerPlayerId;
  final String cityId;

  @override
  GameInteractionMode get mode => GameInteractionMode.cityExpansionSelection;

  @override
  Map<String, dynamic> get jsonFields => {'cityId': cityId};

  @override
  List<Object?> get equalityFields => [cityId];
}

final class PendingWorkerActionSelection extends PendingPlayerAction {
  const PendingWorkerActionSelection({
    required this.ownerPlayerId,
    required this.unitId,
    this.improvementType,
  });

  @override
  final String ownerPlayerId;
  final String unitId;
  final FieldImprovementType? improvementType;

  @override
  GameInteractionMode get mode => GameInteractionMode.workerAction;

  @override
  bool ownsUnit(String unitId) => this.unitId == unitId;

  @override
  Map<String, dynamic> get jsonFields => {
    'unitId': unitId,
    if (improvementType != null) 'improvementType': improvementType!.name,
  };

  @override
  List<Object?> get equalityFields => [unitId, improvementType];

  PendingWorkerActionSelection copyWith({
    String? ownerPlayerId,
    String? unitId,
    Object? improvementType = _unset,
  }) => PendingWorkerActionSelection(
    ownerPlayerId: ownerPlayerId ?? this.ownerPlayerId,
    unitId: unitId ?? this.unitId,
    improvementType: identical(improvementType, _unset)
        ? this.improvementType
        : improvementType as FieldImprovementType?,
  );
}

final class PendingMerchantTradeRouteSelection extends PendingPlayerAction {
  const PendingMerchantTradeRouteSelection({
    required this.ownerPlayerId,
    required this.unitId,
  });

  @override
  final String ownerPlayerId;
  final String unitId;

  @override
  GameInteractionMode get mode =>
      GameInteractionMode.merchantTradeRouteSelection;

  @override
  bool ownsUnit(String unitId) => this.unitId == unitId;

  @override
  Map<String, dynamic> get jsonFields => {'unitId': unitId};

  @override
  List<Object?> get equalityFields => [unitId];
}

final class PendingMerchantMoveToCitySelection extends PendingPlayerAction {
  const PendingMerchantMoveToCitySelection({
    required this.ownerPlayerId,
    required this.unitId,
  });

  @override
  final String ownerPlayerId;
  final String unitId;

  @override
  GameInteractionMode get mode =>
      GameInteractionMode.merchantMoveToCitySelection;

  @override
  bool ownsUnit(String unitId) => this.unitId == unitId;

  @override
  Map<String, dynamic> get jsonFields => {'unitId': unitId};

  @override
  List<Object?> get equalityFields => [unitId];
}

final class PendingUnitTurnSkip extends PendingPlayerAction {
  const PendingUnitTurnSkip({
    required this.ownerPlayerId,
    required this.unitId,
    required this.restoreMovementPoints,
  });

  @override
  final String ownerPlayerId;
  final String unitId;
  final int restoreMovementPoints;

  @override
  GameInteractionMode get mode => GameInteractionMode.unitTurnSkip;

  @override
  bool ownsUnit(String unitId) => this.unitId == unitId;

  @override
  Map<String, dynamic> get jsonFields => {
    'unitId': unitId,
    'restoreMovementPoints': restoreMovementPoints,
  };

  @override
  List<Object?> get equalityFields => [unitId, restoreMovementPoints];
}

final class PendingAttackTargeting extends PendingPlayerAction {
  const PendingAttackTargeting({
    required this.ownerPlayerId,
    required this.attackerUnitId,
    this.defenderCol,
    this.defenderRow,
  });

  @override
  final String ownerPlayerId;
  final String attackerUnitId;
  final int? defenderCol;
  final int? defenderRow;

  bool get hasDefenderTarget => defenderCol != null && defenderRow != null;

  @override
  GameInteractionMode get mode => GameInteractionMode.attackTargeting;

  @override
  bool ownsUnit(String unitId) => attackerUnitId == unitId;

  @override
  Map<String, dynamic> get jsonFields => {
    'attackerUnitId': attackerUnitId,
    if (defenderCol != null) 'defenderCol': defenderCol,
    if (defenderRow != null) 'defenderRow': defenderRow,
  };

  @override
  List<Object?> get equalityFields => [
    attackerUnitId,
    defenderCol,
    defenderRow,
  ];

  PendingAttackTargeting copyWith({
    String? ownerPlayerId,
    String? attackerUnitId,
    Object? defenderCol = _unset,
    Object? defenderRow = _unset,
  }) => PendingAttackTargeting(
    ownerPlayerId: ownerPlayerId ?? this.ownerPlayerId,
    attackerUnitId: attackerUnitId ?? this.attackerUnitId,
    defenderCol: identical(defenderCol, _unset)
        ? this.defenderCol
        : defenderCol as int?,
    defenderRow: identical(defenderRow, _unset)
        ? this.defenderRow
        : defenderRow as int?,
  );
}

final class PendingCommanderMergeSelection extends PendingPlayerAction {
  const PendingCommanderMergeSelection({
    required this.ownerPlayerId,
    required this.commanderUnitId,
  });

  @override
  final String ownerPlayerId;
  final String commanderUnitId;

  @override
  GameInteractionMode get mode => GameInteractionMode.commanderMerge;

  @override
  bool ownsUnit(String unitId) => commanderUnitId == unitId;

  @override
  Map<String, dynamic> get jsonFields => {'commanderUnitId': commanderUnitId};

  @override
  List<Object?> get equalityFields => [commanderUnitId];
}

const Object _unset = Object();
