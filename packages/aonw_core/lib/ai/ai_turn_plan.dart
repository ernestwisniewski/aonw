import 'package:aonw_core/game/domain/command.dart';

class AiTurnPlan {
  final List<GameCommand> commands;
  final AiDebugInfo? debug;

  AiTurnPlan({Iterable<GameCommand> commands = const [], this.debug})
    : commands = List.unmodifiable(commands);

  static final empty = AiTurnPlan();
}

class AiDebugInfo {
  final String strategyId;
  final List<String> notes;
  final Map<String, Object?> metrics;

  AiDebugInfo({
    required this.strategyId,
    Iterable<String> notes = const [],
    Map<String, Object?> metrics = const {},
  }) : notes = List.unmodifiable(notes),
       metrics = Map.unmodifiable(metrics);
}
