final class TurnPresentation {
  const TurnPresentation({required this.turn});

  final int turn;
}

final class TurnPresentationQueue {
  TurnPresentationQueue._({
    required this.latestTurn,
    required this.active,
    required List<TurnPresentation> pending,
  }) : pending = List.unmodifiable(pending);

  factory TurnPresentationQueue.start(int turn) {
    _validateTurn(turn);
    return TurnPresentationQueue._(
      latestTurn: turn,
      active: TurnPresentation(turn: turn),
      pending: const [],
    );
  }

  final int latestTurn;
  final TurnPresentation? active;
  final List<TurnPresentation> pending;

  TurnPresentationQueue observe(int turn) {
    _validateTurn(turn);
    if (turn <= latestTurn) return this;
    final presentation = TurnPresentation(turn: turn);
    if (active == null) {
      return TurnPresentationQueue._(
        latestTurn: turn,
        active: presentation,
        pending: pending,
      );
    }
    return TurnPresentationQueue._(
      latestTurn: turn,
      active: active,
      pending: [...pending, presentation],
    );
  }

  TurnPresentationQueue completeActive() {
    if (active == null) return this;
    if (pending.isEmpty) {
      return TurnPresentationQueue._(
        latestTurn: latestTurn,
        active: null,
        pending: const [],
      );
    }
    return TurnPresentationQueue._(
      latestTurn: latestTurn,
      active: pending.first,
      pending: pending.skip(1).toList(growable: false),
    );
  }

  static void _validateTurn(int turn) {
    if (turn < 1) {
      throw ArgumentError.value(turn, 'turn', 'must be positive');
    }
  }
}
