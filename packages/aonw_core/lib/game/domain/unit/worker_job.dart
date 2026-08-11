import 'package:aonw_core/game/domain/city.dart';

enum WorkerJobKind { fieldImprovement, roadConstruction }

class WorkerJob {
  final CityHex targetHex;
  final WorkerJobKind kind;
  final FieldImprovementType? improvementType;
  final int remainingTurns;
  final int totalTurns;

  const WorkerJob({
    required this.targetHex,
    required this.improvementType,
    required this.remainingTurns,
    required this.totalTurns,
  }) : kind = WorkerJobKind.fieldImprovement;

  const WorkerJob.roadConstruction({
    required this.targetHex,
    required this.remainingTurns,
    required this.totalTurns,
  }) : kind = WorkerJobKind.roadConstruction,
       improvementType = null;

  bool get buildsFieldImprovement => kind == WorkerJobKind.fieldImprovement;
  bool get buildsRoad => kind == WorkerJobKind.roadConstruction;

  factory WorkerJob.fromJson(Map<String, dynamic> json) {
    final targetHex = CityHex.fromJson(
      json['targetHex'] as Map<String, dynamic>,
    );
    final remainingTurns = (json['remainingTurns'] as num).toInt();
    final totalTurns = (json['totalTurns'] as num).toInt();
    final kind = WorkerJobKind.values.byName(
      json['kind'] as String? ?? WorkerJobKind.fieldImprovement.name,
    );
    return switch (kind) {
      WorkerJobKind.fieldImprovement => WorkerJob(
        targetHex: targetHex,
        improvementType: FieldImprovementType.values.byName(
          json['improvementType'] as String,
        ),
        remainingTurns: remainingTurns,
        totalTurns: totalTurns,
      ),
      WorkerJobKind.roadConstruction => WorkerJob.roadConstruction(
        targetHex: targetHex,
        remainingTurns: remainingTurns,
        totalTurns: totalTurns,
      ),
    };
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'targetHex': targetHex.toJson(),
    if (improvementType != null) 'improvementType': improvementType!.name,
    'remainingTurns': remainingTurns,
    'totalTurns': totalTurns,
  };

  WorkerJob copyWith({
    CityHex? targetHex,
    int? remainingTurns,
    int? totalTurns,
  }) {
    return switch (kind) {
      WorkerJobKind.fieldImprovement => WorkerJob(
        targetHex: targetHex ?? this.targetHex,
        improvementType: improvementType!,
        remainingTurns: remainingTurns ?? this.remainingTurns,
        totalTurns: totalTurns ?? this.totalTurns,
      ),
      WorkerJobKind.roadConstruction => WorkerJob.roadConstruction(
        targetHex: targetHex ?? this.targetHex,
        remainingTurns: remainingTurns ?? this.remainingTurns,
        totalTurns: totalTurns ?? this.totalTurns,
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is WorkerJob &&
      other.targetHex == targetHex &&
      other.kind == kind &&
      other.improvementType == improvementType &&
      other.remainingTurns == remainingTurns &&
      other.totalTurns == totalTurns;

  @override
  int get hashCode =>
      Object.hash(targetHex, kind, improvementType, remainingTurns, totalTurns);
}
