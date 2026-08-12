import 'package:aonw_core/game/domain/resource/resource_definition.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/util/collection_equality.dart';

final class StrategicResourceBundle {
  factory StrategicResourceBundle(Map<ResourceType, int> amounts) {
    final sorted = amounts.entries.toList()
      ..sort((left, right) => left.key.name.compareTo(right.key.name));
    final owned = <ResourceType, int>{};
    for (final entry in sorted) {
      if (!ResourceCatalog.isStockpiled(entry.key)) {
        throw ArgumentError.value(
          entry.key,
          'amounts',
          'Only stockpiled strategic resources can be bundled.',
        );
      }
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          'amounts',
          'Resource amounts cannot be negative.',
        );
      }
      if (entry.value > 0) owned[entry.key] = entry.value;
    }
    if (owned.isEmpty) return empty;
    return StrategicResourceBundle._(Map.unmodifiable(owned));
  }

  const StrategicResourceBundle._(this.amounts);

  static const empty = StrategicResourceBundle._({});
  static const oilOne = StrategicResourceBundle._({ResourceType.oil: 1});
  static const oilTwo = StrategicResourceBundle._({ResourceType.oil: 2});
  static const aluminiumOne = StrategicResourceBundle._({
    ResourceType.aluminium: 1,
  });

  final Map<ResourceType, int> amounts;

  bool get isEmpty => amounts.isEmpty;

  int amountFor(ResourceType resource) => amounts[resource] ?? 0;

  bool covers(StrategicResourceBundle required) {
    for (final entry in required.amounts.entries) {
      if (amountFor(entry.key) < entry.value) return false;
    }
    return true;
  }

  StrategicResourceBundle plus(StrategicResourceBundle other) {
    if (other.isEmpty) return this;
    if (isEmpty) return other;
    return StrategicResourceBundle({
      ...amounts,
      for (final entry in other.amounts.entries)
        entry.key: amountFor(entry.key) + entry.value,
    });
  }

  StrategicResourceBundle minus(StrategicResourceBundle other) {
    if (!covers(other)) {
      throw StateError('Strategic resource bundle would become negative.');
    }
    return StrategicResourceBundle({
      ...amounts,
      for (final entry in other.amounts.entries)
        entry.key: amountFor(entry.key) - entry.value,
    });
  }

  Map<String, dynamic> toJson() => {
    for (final entry in amounts.entries) entry.key.name: entry.value,
  };

  factory StrategicResourceBundle.fromJson(Object? value) {
    if (value == null) return empty;
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Expected strategic resource bundle object.');
    }
    final amounts = <ResourceType, int>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final amount = entry.value;
      if (key is! String || amount is! num || amount.toInt() != amount) {
        throw const FormatException('Invalid strategic resource bundle entry.');
      }
      final resource = ResourceType.values.firstWhere(
        (candidate) => candidate.name == key,
        orElse: () => throw FormatException('Unknown resource: $key'),
      );
      if (amount < 0) {
        throw FormatException('Negative strategic resource amount: $amount');
      }
      amounts[resource] = amount.toInt();
    }
    try {
      return StrategicResourceBundle(amounts);
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? '$error');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is StrategicResourceBundle && mapEquals(other.amounts, amounts);

  @override
  int get hashCode => mapHash(amounts);

  @override
  String toString() => 'StrategicResourceBundle($amounts)';
}
