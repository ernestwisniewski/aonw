import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

enum CityTurnEventType { grew, claimedHex, builtBuilding, producedUnit }

class CityTurnEvent {
  final CityTurnEventType type;
  final String cityId;
  final CityHex? hex;
  final FieldImprovement? fieldImprovement;
  final GameUnit? producedUnit;

  const CityTurnEvent({
    required this.type,
    required this.cityId,
    this.hex,
    this.fieldImprovement,
    this.producedUnit,
  });
}

class CityTurnBatchResult {
  final List<GameCity> cities;
  final List<FieldImprovement> fieldImprovements;
  final List<GameUnit> units;
  final List<CityTurnEvent> events;
  final int goldGained;
  final ScienceYieldBreakdown scienceGained;
  final bool hasStateChanges;

  const CityTurnBatchResult({
    required this.cities,
    required this.fieldImprovements,
    this.units = const [],
    required this.events,
    this.goldGained = 0,
    this.scienceGained = ScienceYieldBreakdown.empty,
    this.hasStateChanges = false,
  });

  bool get changed => hasStateChanges || events.isNotEmpty;
}
