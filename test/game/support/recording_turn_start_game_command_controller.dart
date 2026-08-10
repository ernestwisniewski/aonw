import 'package:aonw/game/presentation/providers/game/game_actions_provider.dart';
import 'package:aonw_core/game/domain/command.dart';

final class RecordingTurnStartGameCommandController
    extends GameCommandController {
  RecordingTurnStartGameCommandController(this.commands);

  final List<Object> commands;

  @override
  void build() {}

  @override
  Future<bool> focusTurnStartMapTarget(
    String playerId, {
    bool moveCamera = true,
  }) async {
    commands.add(FocusTurnStartActionCommand(playerId));
    return true;
  }
}
