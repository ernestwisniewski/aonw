import 'package:aonw_core/game/domain/city/city_hex.dart';

class CityFoundingJob {
  final CityHex center;
  final List<CityHex> controlledHexes;
  final int remainingTurns;
  final int totalTurns;

  CityFoundingJob({
    required this.center,
    required List<CityHex> controlledHexes,
    required this.remainingTurns,
    required this.totalTurns,
  }) : controlledHexes = List.unmodifiable(controlledHexes);

  factory CityFoundingJob.fromJson(Map<String, dynamic> json) {
    return CityFoundingJob(
      center: CityHex.fromJson(json['center'] as Map<String, dynamic>),
      controlledHexes:
          (json['controlledHexes'] as List<dynamic>? ?? const <dynamic>[])
              .map((value) => CityHex.fromJson(value as Map<String, dynamic>))
              .toList(),
      remainingTurns: (json['remainingTurns'] as num).toInt(),
      totalTurns: (json['totalTurns'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'center': center.toJson(),
    'controlledHexes': controlledHexes.map((hex) => hex.toJson()).toList(),
    'remainingTurns': remainingTurns,
    'totalTurns': totalTurns,
  };

  CityFoundingJob copyWith({
    CityHex? center,
    List<CityHex>? controlledHexes,
    int? remainingTurns,
    int? totalTurns,
  }) {
    return CityFoundingJob(
      center: center ?? this.center,
      controlledHexes: controlledHexes ?? this.controlledHexes,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      totalTurns: totalTurns ?? this.totalTurns,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! CityFoundingJob) return false;
    if (other.center != center ||
        other.remainingTurns != remainingTurns ||
        other.totalTurns != totalTurns ||
        other.controlledHexes.length != controlledHexes.length) {
      return false;
    }
    for (var i = 0; i < controlledHexes.length; i++) {
      if (other.controlledHexes[i] != controlledHexes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    center,
    Object.hashAll(controlledHexes),
    remainingTurns,
    totalTurns,
  );
}
