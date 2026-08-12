import 'package:aonw_core/game/domain/resource/strategic_resource_bundle.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit_production_requirement.freezed.dart';

@Freezed(copyWith: false)
sealed class UnitProductionRequirement with _$UnitProductionRequirement {
  const UnitProductionRequirement._();

  const factory UnitProductionRequirement.resource(
    Set<ResourceType> resources,
  ) = UnitResourceRequirement;

  const factory UnitProductionRequirement.stockpileCost(
    List<StrategicResourceBundle> options,
  ) = UnitStockpileCostRequirement;
}
