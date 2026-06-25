import 'package:aonw_core/game/domain/city.dart';

class WorkerJob {
  final CityHex targetHex;
  final FieldImprovementType improvementType;
  final int remainingTurns;
  final int totalTurns;

  const WorkerJob({
    required this.targetHex,
    required this.improvementType,
    required this.remainingTurns,
    required this.totalTurns,
  });

  factory WorkerJob.fromJson(Map<String, dynamic> json) {
    return WorkerJob(
      targetHex: CityHex.fromJson(json['targetHex'] as Map<String, dynamic>),
      improvementType: FieldImprovementType.values.byName(
        json['improvementType'] as String,
      ),
      remainingTurns: (json['remainingTurns'] as num).toInt(),
      totalTurns: (json['totalTurns'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'targetHex': targetHex.toJson(),
    'improvementType': improvementType.name,
    'remainingTurns': remainingTurns,
    'totalTurns': totalTurns,
  };

  WorkerJob copyWith({
    CityHex? targetHex,
    FieldImprovementType? improvementType,
    int? remainingTurns,
    int? totalTurns,
  }) {
    return WorkerJob(
      targetHex: targetHex ?? this.targetHex,
      improvementType: improvementType ?? this.improvementType,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      totalTurns: totalTurns ?? this.totalTurns,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorkerJob &&
      other.targetHex == targetHex &&
      other.improvementType == improvementType &&
      other.remainingTurns == remainingTurns &&
      other.totalTurns == totalTurns;

  @override
  int get hashCode =>
      Object.hash(targetHex, improvementType, remainingTurns, totalTurns);
}
