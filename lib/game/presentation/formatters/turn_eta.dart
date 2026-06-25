import 'dart:math' as math;

import 'package:aonw/l10n/generated/app_localizations.dart';

class TurnEta {
  const TurnEta({
    required this.turnsRemaining,
    required this.completionTurn,
    this.blockedLabel = '',
  });

  const TurnEta.blocked([this.blockedLabel = ''])
    : turnsRemaining = null,
      completionTurn = null;

  final int? turnsRemaining;
  final int? completionTurn;
  final String blockedLabel;

  bool get hasTurns => turnsRemaining != null;

  String turnsLabel(AppLocalizations l10n) {
    final turns = turnsRemaining;
    if (turns == null) {
      return blockedLabel.isEmpty ? l10n.turnEtaNoProgress : blockedLabel;
    }
    return TurnEtaFormatter.turnsLabel(l10n, turns);
  }

  String? completionTurnLabel(AppLocalizations l10n) {
    final turn = completionTurn;
    if (turn == null) return null;
    return TurnEtaFormatter.turnPillLabel(l10n, turn);
  }

  String compactLabel(AppLocalizations l10n) {
    final turn = completionTurnLabel(l10n);
    final turns = turnsLabel(l10n);
    if (turn == null) return turns;
    return '$turns • $turn';
  }

  String detailLabel(AppLocalizations l10n) {
    final turn = completionTurn;
    final turns = turnsLabel(l10n);
    if (turn == null || turnsRemaining == null) return turns;
    return l10n.turnEtaDetailLabel(turns, turn);
  }

  String tooltipLabel(AppLocalizations l10n) {
    final turn = completionTurn;
    final turns = turnsLabel(l10n);
    if (turnsRemaining == null) return turns;
    if (turn == null) return l10n.turnEtaTooltipNoTurn(turns);
    return l10n.turnEtaTooltipExpectedTurn(turns, turn);
  }
}

abstract final class TurnEtaFormatter {
  static TurnEta fromTurns({
    required int? turnsRemaining,
    int? currentTurn,
    int? completionTurn,
    String blockedLabel = '',
  }) {
    return TurnEta(
      turnsRemaining: turnsRemaining,
      completionTurn:
          completionTurn ??
          expectedCompletionTurn(
            currentTurn: currentTurn,
            turnsRemaining: turnsRemaining,
          ),
      blockedLabel: blockedLabel,
    );
  }

  static TurnEta fromProgress({
    required int remaining,
    required int perTurn,
    int? currentTurn,
    String blockedLabel = '',
  }) {
    return fromTurns(
      turnsRemaining: turnsRemainingFromProgress(
        remaining: remaining,
        perTurn: perTurn,
      ),
      currentTurn: currentTurn,
      blockedLabel: blockedLabel,
    );
  }

  static int? turnsRemainingFromProgress({
    required int remaining,
    required int perTurn,
  }) {
    if (remaining <= 0) return 0;
    if (perTurn <= 0) return null;
    return (remaining / perTurn).ceil();
  }

  static int? expectedCompletionTurn({
    required int? currentTurn,
    required int? turnsRemaining,
  }) {
    if (currentTurn == null || turnsRemaining == null) return null;
    return currentTurn + math.max(0, turnsRemaining);
  }

  static String turnsLabel(AppLocalizations l10n, int turns) {
    if (turns <= 0) return l10n.commonReady.toLowerCase();
    return l10n.turnCountLabel(turns);
  }

  static String turnPillLabel(AppLocalizations l10n, int turn) {
    return l10n.turnPillLabel(turn);
  }
}
