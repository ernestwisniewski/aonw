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
    required this.preferredOptionValid,
    required this.selectedOptionIndex,
  });

  final List<StrategicResourceBundle> options;
  final StrategicResourceBundle selectedAllocation;
  final StrategicResourceBundle missing;
  final StrategicResourceStockpile onHand;
  final StrategicResourceBundle refundable;
  final bool preferredOptionValid;
  final int? selectedOptionIndex;

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
    int? preferredOptionIndex,
  }) {
    final ownedOptions = _stockpileCostOptions(definition);
    final onHand = accounts.forPlayer(playerId);
    final refundable = _refundableAllocation(replacingCity, playerId);
    final available = onHand.credit(refundable);
    final preferredValid = _preferredOptionIsValid(
      preferredOptionIndex,
      ownedOptions,
    );
    final selected = _coveredOption(
      options: ownedOptions,
      available: available,
      preferredOptionIndex: preferredOptionIndex,
      preferredOptionValid: preferredValid,
    );
    if (selected != null) {
      return _availableQuote(
        options: ownedOptions,
        selected: selected,
        onHand: onHand,
        refundable: refundable,
        preferredOptionValid: preferredValid,
      );
    }
    if (ownedOptions.isEmpty) {
      return _emptyQuote(
        onHand: onHand,
        refundable: refundable,
        preferredOptionValid: preferredValid,
      );
    }
    return _shortageQuote(
      options: ownedOptions,
      available: available,
      onHand: onHand,
      refundable: refundable,
      preferredOptionIndex: preferredOptionIndex,
      preferredOptionValid: preferredValid,
    );
  }
}

List<StrategicResourceBundle> _stockpileCostOptions(
  UnitProductionDefinition definition,
) => List.unmodifiable([
  for (final requirement in definition.requirements)
    if (requirement case UnitStockpileCostRequirement(:final options))
      ...options,
]);

StrategicResourceBundle _refundableAllocation(
  GameCity? replacingCity,
  String playerId,
) => replacingCity?.ownerPlayerId == playerId
    ? replacingCity?.productionQueue?.resourceAllocation ??
          StrategicResourceBundle.empty
    : StrategicResourceBundle.empty;

bool _preferredOptionIsValid(
  int? preferredOptionIndex,
  List<StrategicResourceBundle> options,
) =>
    preferredOptionIndex == null ||
    (preferredOptionIndex >= 0 && preferredOptionIndex < options.length);

(int, StrategicResourceBundle)? _coveredOption({
  required List<StrategicResourceBundle> options,
  required StrategicResourceStockpile available,
  required int? preferredOptionIndex,
  required bool preferredOptionValid,
}) {
  final candidates = preferredOptionIndex == null || !preferredOptionValid
      ? options.indexed
      : [options.indexed.elementAt(preferredOptionIndex)];
  for (final option in candidates) {
    if (available.covers(option.$2)) return option;
  }
  return null;
}

UnitStrategicResourceAvailability _availableQuote({
  required List<StrategicResourceBundle> options,
  required (int, StrategicResourceBundle) selected,
  required StrategicResourceStockpile onHand,
  required StrategicResourceBundle refundable,
  required bool preferredOptionValid,
}) => UnitStrategicResourceAvailability(
  options: options,
  selectedAllocation: selected.$2,
  missing: StrategicResourceBundle.empty,
  onHand: onHand,
  refundable: refundable,
  preferredOptionValid: preferredOptionValid,
  selectedOptionIndex: selected.$1,
);

UnitStrategicResourceAvailability _emptyQuote({
  required StrategicResourceStockpile onHand,
  required StrategicResourceBundle refundable,
  required bool preferredOptionValid,
}) => UnitStrategicResourceAvailability(
  options: const [],
  selectedAllocation: StrategicResourceBundle.empty,
  missing: StrategicResourceBundle.empty,
  onHand: onHand,
  refundable: refundable,
  preferredOptionValid: preferredOptionValid,
  selectedOptionIndex: null,
);

UnitStrategicResourceAvailability _shortageQuote({
  required List<StrategicResourceBundle> options,
  required StrategicResourceStockpile available,
  required StrategicResourceStockpile onHand,
  required StrategicResourceBundle refundable,
  required int? preferredOptionIndex,
  required bool preferredOptionValid,
}) {
  final cost = preferredOptionValid && preferredOptionIndex != null
      ? options[preferredOptionIndex]
      : options.first;
  return UnitStrategicResourceAvailability(
    options: options,
    selectedAllocation: StrategicResourceBundle.empty,
    missing: StrategicResourceBundle({
      for (final entry in cost.amounts.entries)
        if (entry.value > available.amountFor(entry.key))
          entry.key: entry.value - available.amountFor(entry.key),
    }),
    onHand: onHand,
    refundable: refundable,
    preferredOptionValid: preferredOptionValid,
    selectedOptionIndex: null,
  );
}
