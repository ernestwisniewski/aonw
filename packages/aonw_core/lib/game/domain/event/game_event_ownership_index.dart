import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Immutable, pre-indexed entity ownership needed by event boundaries.
///
/// It captures only identity and ownership, so persistent and canonical state
/// collections can share event audience rules without sharing a state type.
final class GameEventOwnershipIndex {
  factory GameEventOwnershipIndex.from(
    Iterable<GameUnit> units,
    Iterable<GameCity> cities,
  ) {
    final unitOwners = <String, String>{};
    for (final unit in units) {
      unitOwners.putIfAbsent(unit.id, () => unit.ownerPlayerId);
    }
    final cityOwners = <String, String>{};
    for (final city in cities) {
      cityOwners.putIfAbsent(city.id, () => city.ownerPlayerId);
    }
    return GameEventOwnershipIndex._(
      unitOwners: Map.unmodifiable(unitOwners),
      cityOwners: Map.unmodifiable(cityOwners),
    );
  }

  const GameEventOwnershipIndex._({
    required Map<String, String> unitOwners,
    required Map<String, String> cityOwners,
  }) : _unitOwners = unitOwners,
       _cityOwners = cityOwners;

  static const empty = GameEventOwnershipIndex._(
    unitOwners: {},
    cityOwners: {},
  );

  final Map<String, String> _unitOwners;
  final Map<String, String> _cityOwners;

  String? unitOwner(String unitId) => _unitOwners[unitId];

  String? cityOwner(String cityId) => _cityOwners[cityId];
}
