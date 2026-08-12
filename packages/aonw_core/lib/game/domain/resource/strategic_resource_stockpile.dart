import 'package:aonw_core/game/domain/resource/strategic_resource_bundle.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class StrategicResourceStockpile {
  const StrategicResourceStockpile._(this.onHand);

  factory StrategicResourceStockpile({
    StrategicResourceBundle onHand = StrategicResourceBundle.empty,
  }) => StrategicResourceStockpile._(onHand);

  static const empty = StrategicResourceStockpile._(
    StrategicResourceBundle.empty,
  );

  final StrategicResourceBundle onHand;

  int amountFor(ResourceType resource) => onHand.amountFor(resource);

  bool covers(StrategicResourceBundle bundle) => onHand.covers(bundle);

  StrategicResourceStockpile credit(StrategicResourceBundle bundle) {
    if (bundle.isEmpty) return this;
    return StrategicResourceStockpile(onHand: onHand.plus(bundle));
  }

  StrategicResourceStockpile debit(StrategicResourceBundle bundle) {
    if (bundle.isEmpty) return this;
    return StrategicResourceStockpile(onHand: onHand.minus(bundle));
  }

  Map<String, dynamic> toJson() => onHand.toJson();

  factory StrategicResourceStockpile.fromJson(Object? value) =>
      StrategicResourceStockpile(
        onHand: StrategicResourceBundle.fromJson(value),
      );

  @override
  bool operator ==(Object other) =>
      other is StrategicResourceStockpile && other.onHand == onHand;

  @override
  int get hashCode => onHand.hashCode;
}
