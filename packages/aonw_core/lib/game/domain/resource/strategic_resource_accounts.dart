import 'package:aonw_core/game/domain/resource/strategic_resource_bundle.dart';
import 'package:aonw_core/game/domain/resource/strategic_resource_stockpile.dart';
import 'package:aonw_core/util/collection_equality.dart';

final class StrategicResourceAccounts {
  factory StrategicResourceAccounts({
    Map<String, StrategicResourceStockpile> byPlayerId = const {},
  }) {
    final entries =
        byPlayerId.entries.where((entry) => entry.key.isNotEmpty).toList()
          ..sort((left, right) => left.key.compareTo(right.key));
    if (entries.isEmpty) return empty;
    return StrategicResourceAccounts._(
      Map.unmodifiable({for (final entry in entries) entry.key: entry.value}),
    );
  }

  const StrategicResourceAccounts._(this.byPlayerId);

  static const empty = StrategicResourceAccounts._({});

  final Map<String, StrategicResourceStockpile> byPlayerId;

  StrategicResourceStockpile forPlayer(String playerId) =>
      byPlayerId[playerId] ?? StrategicResourceStockpile.empty;

  StrategicResourceAccounts credit(
    String playerId,
    StrategicResourceBundle bundle,
  ) => _update(playerId, forPlayer(playerId).credit(bundle));

  StrategicResourceAccounts debit(
    String playerId,
    StrategicResourceBundle bundle,
  ) => _update(playerId, forPlayer(playerId).debit(bundle));

  StrategicResourceAccounts transfer({
    required String fromPlayerId,
    required String toPlayerId,
    required StrategicResourceBundle bundle,
  }) {
    if (bundle.isEmpty || fromPlayerId == toPlayerId) return this;
    return debit(fromPlayerId, bundle).credit(toPlayerId, bundle);
  }

  StrategicResourceAccounts _update(
    String playerId,
    StrategicResourceStockpile stockpile,
  ) {
    if (playerId.isEmpty) return this;
    return StrategicResourceAccounts(
      byPlayerId: {...byPlayerId, playerId: stockpile},
    );
  }

  Map<String, dynamic> toJson() => {
    for (final entry in byPlayerId.entries) entry.key: entry.value.toJson(),
  };

  factory StrategicResourceAccounts.fromJson(Object? value) {
    if (value == null) return empty;
    if (value is! Map<Object?, Object?>) {
      throw const FormatException(
        'Expected strategic resource accounts object.',
      );
    }
    final accounts = <String, StrategicResourceStockpile>{};
    for (final entry in value.entries) {
      if (entry.key is! String || (entry.key as String).isEmpty) {
        throw const FormatException('Invalid strategic resource player id.');
      }
      accounts[entry.key as String] = StrategicResourceStockpile.fromJson(
        entry.value,
      );
    }
    return StrategicResourceAccounts(byPlayerId: accounts);
  }

  @override
  bool operator ==(Object other) =>
      other is StrategicResourceAccounts &&
      mapEquals(other.byPlayerId, byPlayerId);

  @override
  int get hashCode => mapHash(byPlayerId);
}
