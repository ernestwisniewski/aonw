import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_territory_rules.dart';

class CityFoundingDraft {
  static const int requiredControlledHexes = 2;
  static const int maxRadius = 2;

  final String unitId;
  final String ownerPlayerId;
  final CityHex center;
  final List<CityHex> controlledHexes;

  CityFoundingDraft({
    required this.unitId,
    required this.ownerPlayerId,
    required this.center,
    List<CityHex> controlledHexes = const [],
  }) : controlledHexes = List.unmodifiable(controlledHexes);

  factory CityFoundingDraft.fromJson(Map<String, dynamic> json) {
    final controlledHexes =
        (json['controlledHexes'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => CityHex.fromJson(value as Map<String, dynamic>))
            .toList();
    return CityFoundingDraft(
      unitId: json['unitId'] as String,
      ownerPlayerId: json['ownerPlayerId'] as String,
      center: CityHex.fromJson(json['center'] as Map<String, dynamic>),
      controlledHexes: controlledHexes,
    );
  }

  List<CityHex> get territoryHexes => [center, ...controlledHexes];

  bool get hasRequiredControlledHexes =>
      controlledHexes.length == requiredControlledHexes;

  bool get hasConnectedTerritory => CityTerritoryRules.isConnected(
    center: center,
    controlledHexes: controlledHexes,
  );

  bool get canConfirm => hasRequiredControlledHexes && hasConnectedTerritory;

  CityFoundingDraft copyWith({List<CityHex>? controlledHexes}) {
    return CityFoundingDraft(
      unitId: unitId,
      ownerPlayerId: ownerPlayerId,
      center: center,
      controlledHexes: controlledHexes ?? this.controlledHexes,
    );
  }

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'ownerPlayerId': ownerPlayerId,
    'center': center.toJson(),
    'controlledHexes': controlledHexes.map((hex) => hex.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CityFoundingDraft) return false;
    if (other.unitId != unitId) return false;
    if (other.ownerPlayerId != ownerPlayerId) return false;
    if (other.center != center) return false;
    if (other.controlledHexes.length != controlledHexes.length) return false;
    for (var i = 0; i < controlledHexes.length; i++) {
      if (other.controlledHexes[i] != controlledHexes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    unitId,
    ownerPlayerId,
    center,
    Object.hashAll(controlledHexes),
  );
}
