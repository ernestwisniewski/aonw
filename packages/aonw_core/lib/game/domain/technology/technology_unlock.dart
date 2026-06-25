import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

enum CityBuildingUnlockId {
  workshop,
  merchantHall,
  storehouse,
  waterMill,
  stonemason,
  barracks,
  marketplace,
  housing,
  port,
  aqueduct,
  forge,
  stable,
  bank,
  buildersGuild,
  factory,
  lighthouse,
  trainingGrounds,
  townHall,
  monument,
  archive,
  academy,
  university,
  observatory,
  laboratory,
  reactor,
  courthouse,
  court,
  governorsOffice,
  surveyorsOffice,
  planningOffice,
  apothecary,
  publicBaths,
  hospital,
  ministries,
  walls,
  armory,
  siegeWorkshop,
  citadel,
  warCollege,
  conscriptionOffice,
  borderFort,
  airfield,
  artisansGuild,
  masterWorkshop,
  steelworks,
  railDepot,
  powerPlant,
  assemblyPlant,
  refinery,
  mapRoom,
  shipyard,
  dryDock,
  navalAcademy,
  harborCustoms,
  museum,
  parliament,
  broadcastTower,
  worldFairGrounds;

  static CityBuildingUnlockId fromString(String value) {
    return CityBuildingUnlockId.values.firstWhere(
      (id) => id.name == value,
      orElse: () => throw ArgumentError('Unknown city building unlock: $value'),
    );
  }
}

sealed class TechnologyUnlock {
  const TechnologyUnlock();
}

class UnlockCityBuilding extends TechnologyUnlock {
  final CityBuildingUnlockId buildingId;

  const UnlockCityBuilding(this.buildingId);

  @override
  bool operator ==(Object other) =>
      other is UnlockCityBuilding && other.buildingId == buildingId;

  @override
  int get hashCode => Object.hash(UnlockCityBuilding, buildingId);
}

class UnlockFieldImprovement extends TechnologyUnlock {
  final FieldImprovementType improvementType;

  const UnlockFieldImprovement(this.improvementType);

  @override
  bool operator ==(Object other) =>
      other is UnlockFieldImprovement &&
      other.improvementType == improvementType;

  @override
  int get hashCode => Object.hash(UnlockFieldImprovement, improvementType);
}

class UnlockUnitType extends TechnologyUnlock {
  final GameUnitType unitType;

  const UnlockUnitType(this.unitType);

  @override
  bool operator ==(Object other) =>
      other is UnlockUnitType && other.unitType == unitType;

  @override
  int get hashCode => Object.hash(UnlockUnitType, unitType);
}
