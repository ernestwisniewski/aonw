import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/util/collection_equality.dart';

class TileTerrainProfile {
  final TerrainType? base;
  final Set<TerrainType> features;
  final Set<TerrainType> modifiers;
  final Set<TerrainType> blockers;

  const TileTerrainProfile({
    required this.base,
    this.features = const {},
    this.modifiers = const {},
    this.blockers = const {},
  });

  bool get hasRiver => modifiers.contains(TerrainType.river);

  bool get hasForest => features.contains(TerrainType.forest);

  bool get hasJungle => features.contains(TerrainType.jungle);

  bool get hasHills => features.contains(TerrainType.hills);

  bool get hasWetlands => features.contains(TerrainType.wetlands);

  bool get hasMountain => blockers.contains(TerrainType.mountain);

  bool get isWater =>
      base == TerrainType.ocean ||
      base == TerrainType.coast ||
      base == TerrainType.lake;

  @override
  bool operator ==(Object other) {
    return other is TileTerrainProfile &&
        other.base == base &&
        setEquals(other.features, features) &&
        setEquals(other.modifiers, modifiers) &&
        setEquals(other.blockers, blockers);
  }

  @override
  int get hashCode => Object.hash(
    base,
    Object.hashAll(_sorted(features)),
    Object.hashAll(_sorted(modifiers)),
    Object.hashAll(_sorted(blockers)),
  );

  static List<TerrainType> _sorted(Set<TerrainType> values) {
    return values.toList()..sort((a, b) => a.index.compareTo(b.index));
  }
}
