import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class HudAutoFocusTarget {
  String get activePlayerId;
}

bool isTurn(GameClientState? state, String activePlayerId) =>
    state?.activePlayerId == activePlayerId &&
    (state?.activePlayerCanAct ?? false);

extension HudAutoFocusRef on WidgetRef {
  Future<void> auto(HudAutoFocusTarget target, GameClientState? state) =>
      read(hudCommandDispatcherProvider).focusTurnStartMapTarget(
        activePlayerId: target.activePlayerId,
        state: state,
      );
}
