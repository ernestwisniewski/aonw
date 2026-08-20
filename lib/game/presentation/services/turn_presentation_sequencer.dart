import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';

typedef TurnAdvanceEffectsPlayer =
    Future<int> Function(Iterable<UiEffect> effects);
typedef TurnOpeningBeginner = void Function(String playerId);
typedef HumanTurnPreparer = Future<void> Function(String playerId);
typedef HumanTurnReleaser = Future<void> Function(String playerId);
typedef TurnStartFocusRequester = Future<void> Function(String playerId);

final class TurnPresentationSequencer {
  final TurnAdvanceEffectsPlayer playTurnAdvanceEffects;
  final TurnOpeningBeginner beginTurnOpening;
  final HumanTurnPreparer prepareHumanTurn;
  final TurnStartFocusRequester focusTurnStartMapTarget;
  final HumanTurnReleaser releaseHumanTurn;
  final bool Function() canContinue;
  final Stopwatch Function() stopwatchFactory;

  const TurnPresentationSequencer({
    required this.playTurnAdvanceEffects,
    required this.beginTurnOpening,
    required this.prepareHumanTurn,
    required this.focusTurnStartMapTarget,
    required this.releaseHumanTurn,
    this.canContinue = _alwaysContinue,
    this.stopwatchFactory = Stopwatch.new,
  });

  Future<TurnPresentationReport> presentHumanTurnStart({
    required String playerId,
    required bool shouldPlayTurnAdvanceEffects,
    required Iterable<UiEffect> turnAdvanceEffects,
  }) async {
    final progress = _TurnPresentationProgress(
      shouldPlayTurnAdvanceEffects: shouldPlayTurnAdvanceEffects,
    );
    beginTurnOpening(playerId);
    progress.beganTurnOpening = true;
    if (!canContinue()) return progress.report();

    return _continueHumanTurnStart(
      playerId: playerId,
      turnAdvanceEffects: turnAdvanceEffects,
      progress: progress,
    );
  }

  Future<TurnPresentationReport> _continueHumanTurnStart({
    required String playerId,
    required Iterable<UiEffect> turnAdvanceEffects,
    required _TurnPresentationProgress progress,
  }) async {
    var releaseAttempted = false;
    try {
      if (progress.shouldPlayTurnAdvanceEffects) {
        await _playAdvanceEffects(turnAdvanceEffects, progress);
        if (!canContinue()) return progress.report();
      }

      await prepareHumanTurn(playerId);
      progress.preparedHumanTurn = true;
      if (!canContinue()) return progress.report();

      await focusTurnStartMapTarget(playerId);
      progress.focusedTurnStart = true;
      if (!canContinue()) return progress.report();

      releaseAttempted = true;
      await releaseHumanTurn(playerId);
      progress.releasedHumanTurn = true;
      return progress.report();
    } catch (error, stackTrace) {
      await _releaseAfterFailure(playerId, releaseAttempted: releaseAttempted);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _playAdvanceEffects(
    Iterable<UiEffect> effects,
    _TurnPresentationProgress progress,
  ) async {
    final stopwatch = stopwatchFactory()..start();
    progress.turnAdvanceEffectCount = await playTurnAdvanceEffects(effects);
    stopwatch.stop();
    progress
      ..turnAdvanceEffectDuration = stopwatch.elapsed
      ..turnAdvanceEffectsPlayed = true;
  }

  Future<void> _releaseAfterFailure(
    String playerId, {
    required bool releaseAttempted,
  }) async {
    if (releaseAttempted || !canContinue()) return;
    try {
      await releaseHumanTurn(playerId);
    } on Object {
      // Preserve the presentation failure that triggered cleanup.
    }
  }

  static bool _alwaysContinue() => true;
}

final class _TurnPresentationProgress {
  final bool shouldPlayTurnAdvanceEffects;
  bool turnAdvanceEffectsPlayed = false;
  int turnAdvanceEffectCount = 0;
  Duration turnAdvanceEffectDuration = Duration.zero;
  bool beganTurnOpening = false;
  bool preparedHumanTurn = false;
  bool focusedTurnStart = false;
  bool releasedHumanTurn = false;

  _TurnPresentationProgress({required this.shouldPlayTurnAdvanceEffects});

  TurnPresentationReport report() {
    return TurnPresentationReport(
      turnAdvanceEffectsPlayed: turnAdvanceEffectsPlayed,
      turnAdvanceEffectCount: turnAdvanceEffectCount,
      turnAdvanceEffectDuration: turnAdvanceEffectDuration,
      beganTurnOpening: beganTurnOpening,
      preparedHumanTurn: preparedHumanTurn,
      focusedTurnStart: focusedTurnStart,
      releasedHumanTurn: releasedHumanTurn,
    );
  }
}

final class TurnPresentationReport {
  final bool turnAdvanceEffectsPlayed;
  final int turnAdvanceEffectCount;
  final Duration turnAdvanceEffectDuration;
  final bool beganTurnOpening;
  final bool preparedHumanTurn;
  final bool focusedTurnStart;
  final bool releasedHumanTurn;

  const TurnPresentationReport({
    required this.turnAdvanceEffectsPlayed,
    required this.turnAdvanceEffectCount,
    required this.turnAdvanceEffectDuration,
    this.beganTurnOpening = false,
    this.preparedHumanTurn = false,
    this.focusedTurnStart = false,
    this.releasedHumanTurn = false,
  });
}
