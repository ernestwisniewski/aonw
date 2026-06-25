import 'package:aonw_core/map/domain/terrain_type.dart';

sealed class UnitProductionRequirement {
  const UnitProductionRequirement();
}

final class UnitResourceRequirement extends UnitProductionRequirement {
  final Set<ResourceType> resources;

  const UnitResourceRequirement(this.resources);
}
