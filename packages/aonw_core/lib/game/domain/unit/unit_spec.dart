import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_capabilities.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unit_spec.freezed.dart';

@freezed
abstract class UnitSpec with _$UnitSpec {
  const UnitSpec._();

  const factory UnitSpec({
    required GameUnitType type,
    required int productionCost,
    @Default([]) List<UnitProductionRequirement> requirements,
    required CombatStats baseStats,
    required UnitCapabilities capabilities,
    required int upkeep,
    required int supplyCost,
    required int scoreValue,
  }) = _UnitSpec;
}
