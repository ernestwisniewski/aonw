part of '../run_save_ai_benchmark.dart';

class _StaleMoveDiagnostic {
  const _StaleMoveDiagnostic({
    required this.commandIndex,
    required this.command,
    required this.reason,
    required this.unitId,
    required this.targetCol,
    required this.targetRow,
    this.unitCol,
    this.unitRow,
    this.blockerUnitId,
    this.blockerOwnerPlayerId,
    this.blockerOwnerKind,
    this.blockerRelation,
    this.blockerPlanVisibility,
    this.planTargetOccupantId,
  });

  final int commandIndex;
  final String command;
  final String reason;
  final String unitId;
  final int? unitCol;
  final int? unitRow;
  final int targetCol;
  final int targetRow;
  final String? blockerUnitId;
  final String? blockerOwnerPlayerId;
  final String? blockerOwnerKind;
  final String? blockerRelation;
  final String? blockerPlanVisibility;
  final String? planTargetOccupantId;

  Map<String, Object?> toJson() {
    return {
      'commandIndex': commandIndex,
      'command': command,
      'reason': reason,
      'unitId': unitId,
      'unitPosition': unitCol == null || unitRow == null
          ? null
          : {'col': unitCol, 'row': unitRow},
      'target': {'col': targetCol, 'row': targetRow},
      if (blockerUnitId != null)
        'blocker': {
          'unitId': blockerUnitId,
          'ownerPlayerId': blockerOwnerPlayerId,
          'ownerKind': blockerOwnerKind,
          'relation': blockerRelation,
          'planVisibility': blockerPlanVisibility,
        },
      if (planTargetOccupantId != null)
        'planTargetOccupantId': planTargetOccupantId,
    };
  }

  String toMarkdown() {
    final buffer = StringBuffer(
      '#$commandIndex $reason: $command; target=($targetCol,$targetRow)',
    );
    if (unitCol != null && unitRow != null) {
      buffer.write('; unitAt=($unitCol,$unitRow)');
    }
    if (blockerUnitId != null) {
      buffer.write(
        '; blocker=$blockerUnitId/$blockerOwnerPlayerId'
        '[$blockerOwnerKind,$blockerRelation,$blockerPlanVisibility]',
      );
    }
    if (planTargetOccupantId != null) {
      buffer.write('; planTargetOccupant=$planTargetOccupantId');
    }
    return buffer.toString();
  }
}

class _ReplayTurnResult {
  const _ReplayTurnResult({
    required this.save,
    required this.state,
    required this.applied,
    required this.rejected,
    required this.stale,
    required this.skippedTerminal,
    required this.terminalChangedState,
    required this.executionDuration,
    required this.eventCounts,
    required this.staleMoveDiagnostics,
    required this.rejectedCommandDescriptions,
  });

  final GameSave save;
  final GameState state;
  final int applied;
  final int rejected;
  final int stale;
  final int skippedTerminal;
  final bool terminalChangedState;
  final Duration executionDuration;
  final _ExecutionEventCountsSnapshot eventCounts;
  final List<_StaleMoveDiagnostic> staleMoveDiagnostics;
  final List<String> rejectedCommandDescriptions;
}

class _ResolvedReplayTurn {
  const _ResolvedReplayTurn({
    required this.save,
    required this.state,
    required this.events,
  });

  final GameSave save;
  final GameState state;
  final List<GameEvent> events;
}
