import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

enum WorkerImprovementOptionState { selected, recommended, available, blocked }

class WorkerJobProgressViewModel {
  final FieldImprovementType improvementType;
  final String improvementName;
  final CityHex targetHex;
  final int remainingTurns;
  final int totalTurns;

  const WorkerJobProgressViewModel({
    required this.improvementType,
    required this.improvementName,
    required this.targetHex,
    required this.remainingTurns,
    required this.totalTurns,
  });
}

class WorkerImprovementOptionViewModel {
  final FieldImprovementType improvementType;
  final String title;
  final TileYield yield;
  final int buildTurns;
  final WorkerImprovementOptionState state;
  final String reason;
  final bool canSelect;
  final int score;

  const WorkerImprovementOptionViewModel({
    required this.improvementType,
    required this.title,
    required this.yield,
    required this.buildTurns,
    required this.state,
    required this.reason,
    required this.canSelect,
    required this.score,
  });

  bool get blocked => state == WorkerImprovementOptionState.blocked;
  bool get buildable => !blocked;
  bool get selected => state == WorkerImprovementOptionState.selected;
  bool get recommended => state == WorkerImprovementOptionState.recommended;
}

class WorkerActionPanelViewModel {
  final String unitId;
  final String unitName;
  final CityHex currentHex;
  final int movementPoints;
  final bool selectionActive;
  final FieldImprovementType? selectedImprovementType;
  final WorkerJobProgressViewModel? activeJob;
  final List<WorkerImprovementOptionViewModel> options;
  final String buildUnavailableReason;

  const WorkerActionPanelViewModel({
    required this.unitId,
    required this.unitName,
    required this.currentHex,
    required this.movementPoints,
    required this.selectionActive,
    required this.selectedImprovementType,
    required this.activeJob,
    required this.options,
    this.buildUnavailableReason = 'No build is available on this tile.',
  });

  bool get hasActiveJob => activeJob != null;

  bool get isWorking => hasActiveJob;

  bool get canStartSelection =>
      movementPoints > 0 &&
      !isWorking &&
      options.any((option) => option.buildable);

  WorkerImprovementOptionViewModel? get selectedOption {
    return options.where((option) => option.selected).firstOrNull;
  }

  WorkerImprovementOptionViewModel? get recommendedOption {
    return options.where((option) => option.recommended).firstOrNull;
  }

  String? get buildBlockedReason {
    if (canStartSelection) return null;
    if (options.isEmpty) return buildUnavailableReason;
    final reasons = <String>[];
    for (final option in options) {
      if (option.buildable) continue;
      final reason = option.reason.trim();
      if (reason.isEmpty) continue;
      if (reasons.contains(reason)) continue;
      reasons.add(reason);
      if (reasons.length == 2) break;
    }
    if (reasons.isEmpty) return buildUnavailableReason;
    return reasons.join(' • ');
  }
}
