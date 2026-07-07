import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit_production_requirement.freezed.dart';

@freezed
sealed class UnitProductionRequirement with _$UnitProductionRequirement {
  const UnitProductionRequirement._();

  const factory UnitProductionRequirement.resource(
    Set<ResourceType> resources,
  ) = UnitResourceRequirement;
}
