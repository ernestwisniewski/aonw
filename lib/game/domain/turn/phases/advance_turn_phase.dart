import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';

class AdvanceTurnPhase extends TurnPhase {
  const AdvanceTurnPhase();

  @override
  TurnContext apply(TurnContext context) {
    final save = context.save;
    if (save == null) return context;

    return context.copyWith(
      save: advanceSave(
        save,
        playerId: context.playerId,
        savedAt: context.savedAt,
      ),
    );
  }

  GameSave advanceSave(
    GameSave save, {
    required String playerId,
    DateTime? savedAt,
  }) {
    if (!save.playerStates.containsKey(playerId)) return save;

    return save
        .withPlayerFinished(playerId)
        .copyWith(savedAt: (savedAt ?? save.savedAt).toUtc());
  }
}
