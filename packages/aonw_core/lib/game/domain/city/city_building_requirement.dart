import 'package:aonw_core/map/domain/terrain_type.dart';

sealed class CityBuildingRequirement {
  const CityBuildingRequirement();
}

final class CoastalAccessRequirement extends CityBuildingRequirement {
  const CoastalAccessRequirement();
}

final class CityResourceRequirement extends CityBuildingRequirement {
  final Set<ResourceType> resources;

  const CityResourceRequirement(this.resources);
}
