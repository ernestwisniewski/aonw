import 'package:aonw/game/domain/reducer/game_state_transition.dart';

typedef TurnAdvanceEffectsPlayer =
    Future<int> Function(Iterable<UiEffect> effects);
typedef HumanTurnConfirmer = Future<void> Function(String playerId);
typedef TurnStartFocusRequester = Future<void> Function(String playerId);

final class TurnPresentationSequencer {
  final TurnAdvanceEffectsPlayer playTurnAdvanceEffects;
  final HumanTurnConfirmer confirmHumanTurn;
  final TurnStartFocusRequester focusTurnStartMapTarget;
  final bool Function() canContinue;
  final Stopwatch Function() stopwatchFactory;

  const TurnPresentationSequencer({
    required this.playTurnAdvanceEffects,
    required this.confirmHumanTurn,
    required this.focusTurnStartMapTarget,
    this.canContinue = _alwaysContinue,
    this.stopwatchFactory = Stopwatch.new,
  });

  Future<TurnPresentationReport> presentHumanTurnStart({
    required String playerId,
    required bool shouldPlayTurnAdvanceEffects,
    required Iterable<UiEffect> turnAdvanceEffects,
  }) async {
    var effectCount = 0;
    var effectDuration = Duration.zero;

    if (shouldPlayTurnAdvanceEffects) {
      final stopwatch = stopwatchFactory()..start();
      effectCount = await playTurnAdvanceEffects(turnAdvanceEffects);
      stopwatch.stop();
      effectDuration = stopwatch.elapsed;
      if (!canContinue()) {
        return TurnPresentationReport(
          turnAdvanceEffectsPlayed: true,
          turnAdvanceEffectCount: effectCount,
          turnAdvanceEffectDuration: effectDuration,
        );
      }
    }

    await confirmHumanTurn(playerId);
    if (!canContinue()) {
      return TurnPresentationReport(
        turnAdvanceEffectsPlayed: shouldPlayTurnAdvanceEffects,
        turnAdvanceEffectCount: effectCount,
        turnAdvanceEffectDuration: effectDuration,
        confirmedHumanTurn: true,
      );
    }

    await focusTurnStartMapTarget(playerId);
    return TurnPresentationReport(
      turnAdvanceEffectsPlayed: shouldPlayTurnAdvanceEffects,
      turnAdvanceEffectCount: effectCount,
      turnAdvanceEffectDuration: effectDuration,
      confirmedHumanTurn: true,
      focusedTurnStart: true,
    );
  }

  static bool _alwaysContinue() => true;
}

final class TurnPresentationReport {
  final bool turnAdvanceEffectsPlayed;
  final int turnAdvanceEffectCount;
  final Duration turnAdvanceEffectDuration;
  final bool confirmedHumanTurn;
  final bool focusedTurnStart;

  const TurnPresentationReport({
    required this.turnAdvanceEffectsPlayed,
    required this.turnAdvanceEffectCount,
    required this.turnAdvanceEffectDuration,
    this.confirmedHumanTurn = false,
    this.focusedTurnStart = false,
  });
}
