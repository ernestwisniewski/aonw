import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_progression.dart';
import 'package:aonw_core/game/domain/city/city_progression_catalog.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';

part 'game_city_copying.dart';

final class GameCity {
  static const Object _unset = Object();

  static const int defaultStartPopulation =
      CityProgressionCatalog.startPopulation;
  static const int defaultStartStoredFood =
      CityProgressionCatalog.startStoredFood;
  static const int defaultStartMaxHexes = CityProgressionCatalog.startMaxHexes;
  static const int defaultStartTerritoryRadius =
      CityProgressionCatalog.startTerritoryRadius;

  final String id;
  final String ownerPlayerId;
  final String? foundingOwnerPlayerId;
  final String name;
  final int population;
  final int storedFood;
  final int maxHexes;
  final int territoryRadius;
  final CityHex center;
  final List<CityHex> controlledHexes;
  final List<CityHex> workedHexes;
  final Set<CityBuildingType> buildings;
  final Set<WonderType> wonders;
  final CityProductionQueue? productionQueue;
  final int productionOverflow;
  final CitySpecializationType? specialization;
  final CityHex? preferredExpansionHex;
  final int? hitPoints;
  final bool _isImmutableSnapshot;

  /// Legacy const constructor retained for compile-time fixtures.
  /// Runtime code must use [GameCity.snapshot].
  const GameCity({
    required this.id,
    required this.ownerPlayerId,
    this.foundingOwnerPlayerId,
    required this.name,
    this.population = defaultStartPopulation,
    this.storedFood = defaultStartStoredFood,
    this.maxHexes = defaultStartMaxHexes,
    this.territoryRadius = defaultStartTerritoryRadius,
    required this.center,
    this.controlledHexes = const [],
    this.workedHexes = const [],
    this.buildings = const {},
    this.wonders = const {},
    this.productionQueue,
    this.productionOverflow = 0,
    this.specialization,
    this.preferredExpansionHex,
    this.hitPoints,
  }) : _isImmutableSnapshot = false;

  GameCity.snapshot({
    required this.id,
    required this.ownerPlayerId,
    this.foundingOwnerPlayerId,
    required this.name,
    this.population = defaultStartPopulation,
    this.storedFood = defaultStartStoredFood,
    this.maxHexes = defaultStartMaxHexes,
    this.territoryRadius = defaultStartTerritoryRadius,
    required this.center,
    List<CityHex> controlledHexes = const [],
    List<CityHex> workedHexes = const [],
    Set<CityBuildingType> buildings = const {},
    Set<WonderType> wonders = const {},
    this.productionQueue,
    this.productionOverflow = 0,
    this.specialization,
    this.preferredExpansionHex,
    this.hitPoints,
  }) : controlledHexes = _immutableCityList(controlledHexes),
       workedHexes = _immutableCityList(workedHexes),
       buildings = _immutableCitySet(buildings),
       wonders = _immutableCitySet(wonders),
       _isImmutableSnapshot = true;

  const GameCity._owned({
    required this.id,
    required this.ownerPlayerId,
    required this.foundingOwnerPlayerId,
    required this.name,
    required this.population,
    required this.storedFood,
    required this.maxHexes,
    required this.territoryRadius,
    required this.center,
    required this.controlledHexes,
    required this.workedHexes,
    required this.buildings,
    required this.wonders,
    required this.productionQueue,
    required this.productionOverflow,
    required this.specialization,
    required this.preferredExpansionHex,
    required this.hitPoints,
  }) : _isImmutableSnapshot = true;

  factory GameCity.founded({
    required GameUnit founder,
    String? name,
    List<CityHex> controlledHexes = const [],
    int sequence = 1,
    CityProgression progression = CityProgressionCatalog.standard,
  }) {
    final center = CityHex(col: founder.col, row: founder.row);
    return GameCity.snapshot(
      id: 'city_${founder.ownerPlayerId}_${center.col}_${center.row}',
      ownerPlayerId: founder.ownerPlayerId,
      foundingOwnerPlayerId: founder.ownerPlayerId,
      name: name ?? 'city_$sequence',
      population: progression.startPopulation,
      storedFood: progression.startStoredFood,
      maxHexes: progression.startMaxHexes,
      territoryRadius: progression.startTerritoryRadius,
      center: center,
      controlledHexes: controlledHexes,
    );
  }

  factory GameCity.fromJson(Map<String, dynamic> json) {
    return GameCity.snapshot(
      id: json['id'] as String,
      ownerPlayerId: json['ownerPlayerId'] as String,
      foundingOwnerPlayerId: json['foundingOwnerPlayerId'] as String?,
      name: json['name'] as String,
      population:
          (json['population'] as num?)?.toInt() ?? defaultStartPopulation,
      storedFood:
          (json['storedFood'] as num?)?.toInt() ?? defaultStartStoredFood,
      maxHexes: (json['maxHexes'] as num?)?.toInt() ?? defaultStartMaxHexes,
      territoryRadius:
          (json['territoryRadius'] as num?)?.toInt() ??
          defaultStartTerritoryRadius,
      center: CityHex.fromJson(json['center'] as Map<String, dynamic>),
      controlledHexes:
          (json['controlledHexes'] as List<dynamic>?)
              ?.map((value) => CityHex.fromJson(value as Map<String, dynamic>))
              .toList() ??
          const [],
      workedHexes:
          (json['workedHexes'] as List<dynamic>?)
              ?.map((value) => CityHex.fromJson(value as Map<String, dynamic>))
              .toList() ??
          const [],
      buildings: _buildingsFromJson(json['buildings'] as List<dynamic>?),
      wonders: _wondersFromJson(json['wonders'] as List<dynamic>?),
      productionQueue: json['productionQueue'] == null
          ? null
          : CityProductionQueue.fromJson(
              json['productionQueue'] as Map<String, dynamic>,
            ),
      productionOverflow: (json['productionOverflow'] as num?)?.toInt() ?? 0,
      specialization: json['specialization'] == null
          ? null
          : CitySpecializationType.fromString(json['specialization'] as String),
      preferredExpansionHex: json['preferredExpansionHex'] == null
          ? null
          : CityHex.fromJson(
              json['preferredExpansionHex'] as Map<String, dynamic>,
            ),
      hitPoints: (json['hitPoints'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerPlayerId': ownerPlayerId,
    if (foundingOwnerPlayerId != null)
      'foundingOwnerPlayerId': foundingOwnerPlayerId,
    'name': name,
    'population': population,
    'storedFood': storedFood,
    'maxHexes': maxHexes,
    'territoryRadius': territoryRadius,
    'center': center.toJson(),
    'controlledHexes': controlledHexes.map((hex) => hex.toJson()).toList(),
    'workedHexes': workedHexes.map((hex) => hex.toJson()).toList(),
    'buildings': _buildingsToJson(buildings),
    if (wonders.isNotEmpty) 'wonders': _wondersToJson(wonders),
    if (productionQueue != null) 'productionQueue': productionQueue!.toJson(),
    'productionOverflow': productionOverflow,
    if (specialization != null) 'specialization': specialization!.name,
    if (preferredExpansionHex != null)
      'preferredExpansionHex': preferredExpansionHex!.toJson(),
    if (hitPoints != null) 'hitPoints': hitPoints,
  };

  String get capitalOwnerPlayerId => foundingOwnerPlayerId ?? ownerPlayerId;

  List<CityHex> get territoryHexes => [center, ...controlledHexes];

  int get territoryHexCount => territoryHexes.length;

  HexCoordinate get coordinate => center.coordinate;

  bool occupiesCenter(int col, int row) => center.occupies(col, row);

  bool controlsHex(CityHex hex) =>
      center == hex || controlledHexes.contains(hex);

  bool controlsTile(int col, int row) =>
      controlsHex(CityHex(col: col, row: row));

  @override
  bool operator ==(Object other) {
    return other is GameCity &&
        other.id == id &&
        other.ownerPlayerId == ownerPlayerId &&
        other.foundingOwnerPlayerId == foundingOwnerPlayerId &&
        other.name == name &&
        other.population == population &&
        other.storedFood == storedFood &&
        other.maxHexes == maxHexes &&
        other.territoryRadius == territoryRadius &&
        other.center == center &&
        _sameList(other.controlledHexes, controlledHexes) &&
        _sameList(other.workedHexes, workedHexes) &&
        _sameSet(other.buildings, buildings) &&
        _sameSet(other.wonders, wonders) &&
        other.productionQueue == productionQueue &&
        other.productionOverflow == productionOverflow &&
        other.specialization == specialization &&
        other.preferredExpansionHex == preferredExpansionHex &&
        other.hitPoints == hitPoints;
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerPlayerId,
    foundingOwnerPlayerId,
    name,
    population,
    storedFood,
    maxHexes,
    territoryRadius,
    center,
    Object.hashAll(controlledHexes),
    Object.hashAll(workedHexes),
    Object.hashAllUnordered(buildings),
    Object.hashAllUnordered(wonders),
    productionQueue,
    productionOverflow,
    specialization,
    preferredExpansionHex,
    hitPoints,
  );

  @override
  String toString() {
    return 'GameCity(id: $id, ownerPlayerId: $ownerPlayerId, '
        'foundingOwnerPlayerId: $foundingOwnerPlayerId, name: $name, '
        'population: $population, storedFood: $storedFood, '
        'maxHexes: $maxHexes, territoryRadius: $territoryRadius, '
        'center: $center, controlledHexes: $controlledHexes, '
        'workedHexes: $workedHexes, buildings: $buildings, '
        'wonders: $wonders, '
        'productionQueue: $productionQueue, '
        'productionOverflow: $productionOverflow, '
        'specialization: $specialization, '
        'preferredExpansionHex: $preferredExpansionHex, '
        'hitPoints: $hitPoints)';
  }

  static Set<CityBuildingType> _buildingsFromJson(List<dynamic>? values) =>
      values == null
      ? const {}
      : values
            .map((value) => CityBuildingType.fromString(value as String))
            .toSet();

  static List<String> _buildingsToJson(Set<CityBuildingType> values) =>
      values.map((building) => building.name).toList();

  static Set<WonderType> _wondersFromJson(List<dynamic>? values) =>
      values == null
      ? const {}
      : values.map((value) => WonderType.fromString(value as String)).toSet();

  static List<String> _wondersToJson(Set<WonderType> values) =>
      values.map((wonder) => wonder.name).toList();

  static bool _sameList<T>(List<T> left, List<T> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static bool _sameSet<T>(Set<T> left, Set<T> right) {
    if (left.length != right.length) return false;
    for (final item in left) {
      if (!right.contains(item)) return false;
    }
    return true;
  }
}
