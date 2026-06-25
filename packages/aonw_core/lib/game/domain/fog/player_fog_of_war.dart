import 'package:aonw_core/game/domain/fog/fog_visibility.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/util/collection_equality.dart';

class PlayerFogOfWar {
  final String playerId;
  final Set<HexCoordinate> discoveredHexes;
  final Set<HexCoordinate> visibleHexes;

  PlayerFogOfWar({
    required this.playerId,
    Set<HexCoordinate> discoveredHexes = const {},
    Set<HexCoordinate> visibleHexes = const {},
  }) : visibleHexes = Set.unmodifiable(visibleHexes),
       discoveredHexes = Set.unmodifiable({
         ...discoveredHexes,
         ...visibleHexes,
       });

  factory PlayerFogOfWar.fromJson(Map<String, dynamic> json) {
    final discovered = (json['discoveredHexes'] as List<dynamic>)
        .map((value) => HexCoordinate.fromJson(value as Map<String, dynamic>))
        .toSet();
    final visible = (json['visibleHexes'] as List<dynamic>? ?? const [])
        .map((value) => HexCoordinate.fromJson(value as Map<String, dynamic>))
        .toSet();
    return PlayerFogOfWar(
      playerId: json['playerId'] as String,
      discoveredHexes: discovered,
      visibleHexes: visible,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'discoveredHexes': _sorted(
      discoveredHexes,
    ).map((hex) => hex.toJson()).toList(),
    'visibleHexes': _sorted(visibleHexes).map((hex) => hex.toJson()).toList(),
  };

  FogVisibility visibilityFor(HexCoordinate hex) {
    if (visibleHexes.contains(hex)) return FogVisibility.visible;
    if (discoveredHexes.contains(hex)) return FogVisibility.discovered;
    return FogVisibility.hidden;
  }

  bool isKnown(HexCoordinate hex) => visibilityFor(hex).isKnown;

  bool isVisible(HexCoordinate hex) => visibilityFor(hex).isVisible;

  PlayerFogOfWar copyWith({
    Set<HexCoordinate>? discoveredHexes,
    Set<HexCoordinate>? visibleHexes,
  }) {
    return PlayerFogOfWar(
      playerId: playerId,
      discoveredHexes: discoveredHexes ?? this.discoveredHexes,
      visibleHexes: visibleHexes ?? this.visibleHexes,
    );
  }

  PlayerFogOfWar withVisibleHexes(Set<HexCoordinate> visibleHexes) {
    return PlayerFogOfWar(
      playerId: playerId,
      discoveredHexes: {...discoveredHexes, ...visibleHexes},
      visibleHexes: visibleHexes,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerFogOfWar &&
        other.playerId == playerId &&
        setEquals(other.discoveredHexes, discoveredHexes) &&
        setEquals(other.visibleHexes, visibleHexes);
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    Object.hashAll(_sorted(discoveredHexes)),
    Object.hashAll(_sorted(visibleHexes)),
  );

  static List<HexCoordinate> _sorted(Iterable<HexCoordinate> values) {
    return values.toList()..sort((a, b) {
      final col = a.col.compareTo(b.col);
      if (col != 0) return col;
      return a.row.compareTo(b.row);
    });
  }
}
