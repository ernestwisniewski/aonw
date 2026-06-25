import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_project_type.dart';
import 'package:aonw_core/game/domain/unit.dart';

sealed class CityProductionTarget {
  const CityProductionTarget();

  factory CityProductionTarget.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String;
    return switch (kind) {
      BuildingProductionTarget.kind => BuildingProductionTarget(
        CityBuildingType.fromString(json['buildingType'] as String),
      ),
      UnitProductionTarget.kind => UnitProductionTarget(
        GameUnitType.fromName(json['unitType'] as String),
      ),
      ProjectProductionTarget.kind => ProjectProductionTarget(
        CityProjectType.fromName(json['projectType'] as String),
      ),
      _ => throw ArgumentError('Unknown city production target kind: $kind'),
    };
  }

  Map<String, dynamic> toJson();
}

class BuildingProductionTarget extends CityProductionTarget {
  static const String kind = 'building';

  final CityBuildingType buildingType;

  const BuildingProductionTarget(this.buildingType);

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'buildingType': buildingType.name,
  };

  @override
  bool operator ==(Object other) =>
      other is BuildingProductionTarget && other.buildingType == buildingType;

  @override
  int get hashCode => Object.hash(kind, buildingType);
}

class UnitProductionTarget extends CityProductionTarget {
  static const String kind = 'unit';

  final GameUnitType unitType;

  const UnitProductionTarget(this.unitType);

  @override
  Map<String, dynamic> toJson() => {'kind': kind, 'unitType': unitType.name};

  @override
  bool operator ==(Object other) =>
      other is UnitProductionTarget && other.unitType == unitType;

  @override
  int get hashCode => Object.hash(kind, unitType);
}

class ProjectProductionTarget extends CityProductionTarget {
  static const String kind = 'project';

  final CityProjectType projectType;

  const ProjectProductionTarget(this.projectType);

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'projectType': projectType.name,
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectProductionTarget && other.projectType == projectType;

  @override
  int get hashCode => Object.hash(kind, projectType);
}
