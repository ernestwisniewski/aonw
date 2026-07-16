part of 'game_city.dart';

extension GameCityCopying on GameCity {
  GameCity immutableSnapshot() {
    if (_isImmutableSnapshot) return this;
    return GameCity.snapshot(
      id: id,
      ownerPlayerId: ownerPlayerId,
      foundingOwnerPlayerId: foundingOwnerPlayerId,
      name: name,
      population: population,
      storedFood: storedFood,
      maxHexes: maxHexes,
      territoryRadius: territoryRadius,
      center: center,
      controlledHexes: controlledHexes,
      workedHexes: workedHexes,
      buildings: buildings,
      wonders: wonders,
      productionQueue: productionQueue,
      productionOverflow: productionOverflow,
      specialization: specialization,
      preferredExpansionHex: preferredExpansionHex,
      hitPoints: hitPoints,
    );
  }

  GameCity copyWith({
    String? id,
    String? ownerPlayerId,
    Object? foundingOwnerPlayerId = GameCity._unset,
    String? name,
    int? population,
    int? storedFood,
    int? maxHexes,
    int? territoryRadius,
    CityHex? center,
    List<CityHex>? controlledHexes,
    List<CityHex>? workedHexes,
    Set<CityBuildingType>? buildings,
    Set<WonderType>? wonders,
    Object? productionQueue = GameCity._unset,
    int? productionOverflow,
    Object? specialization = GameCity._unset,
    Object? preferredExpansionHex = GameCity._unset,
    Object? hitPoints = GameCity._unset,
  }) {
    final source = immutableSnapshot();
    final nextOwnerPlayerId = ownerPlayerId ?? source.ownerPlayerId;
    final nextFoundingOwnerPlayerId =
        identical(foundingOwnerPlayerId, GameCity._unset)
        ? source._preservedFoundingOwnerFor(nextOwnerPlayerId)
        : foundingOwnerPlayerId as String?;
    return GameCity._owned(
      id: id ?? source.id,
      ownerPlayerId: nextOwnerPlayerId,
      foundingOwnerPlayerId: nextFoundingOwnerPlayerId,
      name: name ?? source.name,
      population: population ?? source.population,
      storedFood: storedFood ?? source.storedFood,
      maxHexes: maxHexes ?? source.maxHexes,
      territoryRadius: territoryRadius ?? source.territoryRadius,
      center: center ?? source.center,
      controlledHexes: _listCopy(controlledHexes, source.controlledHexes),
      workedHexes: _listCopy(workedHexes, source.workedHexes),
      buildings: _setCopy(buildings, source.buildings),
      wonders: _setCopy(wonders, source.wonders),
      productionQueue: identical(productionQueue, GameCity._unset)
          ? source.productionQueue
          : productionQueue as CityProductionQueue?,
      productionOverflow: productionOverflow ?? source.productionOverflow,
      specialization: identical(specialization, GameCity._unset)
          ? source.specialization
          : specialization as CitySpecializationType?,
      preferredExpansionHex: identical(preferredExpansionHex, GameCity._unset)
          ? source.preferredExpansionHex
          : preferredExpansionHex as CityHex?,
      hitPoints: identical(hitPoints, GameCity._unset)
          ? source.hitPoints
          : hitPoints as int?,
    );
  }

  /// Use this to set OR clear combat HP.
  GameCity copyWithHitPoints(int? hitPoints) => copyWith(hitPoints: hitPoints);

  String? _preservedFoundingOwnerFor(String nextOwnerPlayerId) {
    if (foundingOwnerPlayerId != null) return foundingOwnerPlayerId;
    if (nextOwnerPlayerId == ownerPlayerId) return null;
    return ownerPlayerId;
  }
}

List<T> _listCopy<T>(List<T>? replacement, List<T> current) {
  return replacement == null ? current : _immutableCityList(replacement);
}

Set<T> _setCopy<T>(Set<T>? replacement, Set<T> current) {
  return replacement == null ? current : _immutableCitySet(replacement);
}

List<T> _immutableCityList<T>(List<T> source) =>
    source.isEmpty ? const [] : List.unmodifiable(source);

Set<T> _immutableCitySet<T>(Set<T> source) =>
    source.isEmpty ? const {} : Set.unmodifiable(source);
