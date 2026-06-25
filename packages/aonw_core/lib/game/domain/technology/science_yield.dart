import 'package:aonw_core/util/collection_equality.dart';

class ScienceYieldBreakdown {
  final int total;
  final Map<String, int> byCityId;
  final List<ScienceYieldSource> sources;

  const ScienceYieldBreakdown({
    required this.total,
    required this.byCityId,
    required this.sources,
  });

  static const empty = ScienceYieldBreakdown(
    total: 0,
    byCityId: {},
    sources: [],
  );

  @override
  bool operator ==(Object other) =>
      other is ScienceYieldBreakdown &&
      other.total == total &&
      mapEquals(other.byCityId, byCityId) &&
      listEquals(other.sources, sources);

  @override
  int get hashCode => Object.hash(
    total,
    Object.hashAll(byCityId.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(sources),
  );
}

class ScienceYieldSource {
  final String cityId;
  final int amount;
  final String label;

  const ScienceYieldSource({
    required this.cityId,
    required this.amount,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      other is ScienceYieldSource &&
      other.cityId == cityId &&
      other.amount == amount &&
      other.label == label;

  @override
  int get hashCode => Object.hash(cityId, amount, label);
}
