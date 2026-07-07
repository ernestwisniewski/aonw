import 'package:aonw_core/map/domain/terrain_type.dart';

sealed class WonderRequirement {
  const WonderRequirement();
}

final class WonderCoastalAccessRequirement extends WonderRequirement {
  const WonderCoastalAccessRequirement();
}

final class WonderResourceRequirement extends WonderRequirement {
  const WonderResourceRequirement(this.resources);

  final Set<ResourceType> resources;
}

final class WonderAdjacentRiverRequirement extends WonderRequirement {
  const WonderAdjacentRiverRequirement();
}

final class WonderAdjacentMountainRequirement extends WonderRequirement {
  const WonderAdjacentMountainRequirement();
}

final class WonderHostTerrainRequirement extends WonderRequirement {
  const WonderHostTerrainRequirement(this.allowedTerrains);

  final Set<TerrainType> allowedTerrains;
}
