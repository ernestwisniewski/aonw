import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/unit/unit_production_definition.dart';
import 'package:aonw_core/game/domain/unit/unit_production_requirement.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class UnitStrategicResourceAvailability {
  const UnitStrategicResourceAvailability({
    required this.options,
    required this.selectedAllocation,
    required this.missing,
    required this.onHand,
    required this.refundable,
  });

  final List<StrategicResourceBundle> options;
  final StrategicResourceBundle selectedAllocation;
  final StrategicResourceBundle missing;
  final StrategicResourceStockpile onHand;
  final StrategicResourceBundle refundable;

  bool get hasCost => options.isNotEmpty;

  bool get isAvailable => missing.isEmpty;

  int availableFor(ResourceType resource) =>
      onHand.amountFor(resource) + refundable.amountFor(resource);

  static UnitStrategicResourceAvailability forUnit({
    required String playerId,
    required GameUnitType unitType,
    required UnitProductionDefinition definition,
    required StrategicResourceAccounts accounts,
    GameCity? replacingCity,
  }) {
    final costOptions = <StrategicResourceBundle>[];
    for (final requirement in definition.requirements) {
      if (requirement case UnitStockpileCostRequirement(
        options: final requirementOptions,
      )) {
        costOptions.addAll(requirementOptions);
      }
    }
    final ownedOptions = List<StrategicResourceBundle>.unmodifiable(
      costOptions,
    );
    final onHand = accounts.forPlayer(playerId);
    final refundable = replacingCity?.ownerPlayerId == playerId
        ? replacingCity?.productionQueue?.resourceAllocation ??
              StrategicResourceBundle.empty
        : StrategicResourceBundle.empty;
    final available = onHand.credit(refundable);
    for (final option in ownedOptions) {
      if (available.covers(option)) {
        return UnitStrategicResourceAvailability(
          options: ownedOptions,
          selectedAllocation: option,
          missing: StrategicResourceBundle.empty,
          onHand: onHand,
          refundable: refundable,
        );
      }
    }
    if (ownedOptions.isEmpty) {
      return UnitStrategicResourceAvailability(
        options: ownedOptions,
        selectedAllocation: StrategicResourceBundle.empty,
        missing: StrategicResourceBundle.empty,
        onHand: onHand,
        refundable: refundable,
      );
    }
    final first = ownedOptions.first;
    return UnitStrategicResourceAvailability(
      options: ownedOptions,
      selectedAllocation: StrategicResourceBundle.empty,
      missing: StrategicResourceBundle({
        for (final entry in first.amounts.entries)
          if (entry.value > available.amountFor(entry.key))
            entry.key: entry.value - available.amountFor(entry.key),
      }),
      onHand: onHand,
      refundable: refundable,
    );
  }
}
