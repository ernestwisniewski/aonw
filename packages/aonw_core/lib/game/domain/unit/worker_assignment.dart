import 'package:aonw_core/game/domain/city.dart';

class WorkerAssignment {
  final CityHex targetHex;

  const WorkerAssignment({required this.targetHex});

  factory WorkerAssignment.fromJson(Map<String, dynamic> json) {
    return WorkerAssignment(
      targetHex: CityHex.fromJson(json['targetHex'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {'targetHex': targetHex.toJson()};

  WorkerAssignment copyWith({CityHex? targetHex}) {
    return WorkerAssignment(targetHex: targetHex ?? this.targetHex);
  }

  @override
  bool operator ==(Object other) =>
      other is WorkerAssignment && other.targetHex == targetHex;

  @override
  int get hashCode => targetHex.hashCode;
}
