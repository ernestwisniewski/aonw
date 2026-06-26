import 'package:aonw/game/presentation/widgets/bottom_toolbar/end_turn_button.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_command_line_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/turn/turn_action_hint.dart';
import 'package:flutter/material.dart';

class HudCommandLine extends StatelessWidget {
  const HudCommandLine({
    required this.viewModel,
    required this.playerColor,
    required this.turn,
    required this.readyToEndTurn,
    required this.isUnitAnimating,
    required this.currentActionIndex,
    required this.turnActionOptions,
    required this.pulseActionBorder,
    required this.onEndTurn,
    required this.onNextAction,
    required this.onActionSelected,
    this.forceCompact = false,
    super.key,
  });

  final HudCommandLineViewModel viewModel;
  final Color playerColor;
  final int turn;
  final bool readyToEndTurn;
  final bool isUnitAnimating;
  final int currentActionIndex;
  final List<HudTurnActionOption> turnActionOptions;
  final bool pulseActionBorder;
  final VoidCallback onEndTurn;
  final VoidCallback onNextAction;
  final ValueChanged<int> onActionSelected;
  final bool forceCompact;

  @override
  Widget build(BuildContext context) {
    final compact = forceCompact || MediaQuery.sizeOf(context).width < 360;
    final showActionMenu =
        !readyToEndTurn && !viewModel.activePlayerFinished && !isUnitAnimating;
    final endTurnWidth = EndTurnButton.preferredWidth(
      compact: compact,
      includeActionSegment: showActionMenu,
    );

    return SizedBox(
      key: const Key('hudActionDeck.line.commands'),
      height: HudActionDeckMetrics.commandLineHeight,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: endTurnWidth,
          child: EndTurnButton(
            playerColor: playerColor,
            turn: turn,
            waiting: viewModel.activePlayerFinished || isUnitAnimating,
            readyToEndTurn: readyToEndTurn,
            actionCount: viewModel.remainingActionCount,
            submitMode: viewModel.multiplayer,
            waitingForLabel: viewModel.waitingForLabel,
            actionHintLabel: viewModel.actionHintLabel,
            currentActionIndex: currentActionIndex,
            actionOptions: turnActionOptions,
            compact: compact,
            showTurnLabel: false,
            minHeight: HudActionDeckMetrics.commandLineHeight,
            showActionMenu: showActionMenu,
            pulseActionBorder: pulseActionBorder,
            onActionSelected: onActionSelected,
            onTap: readyToEndTurn ? onEndTurn : onNextAction,
          ),
        ),
      ),
    );
  }
}

abstract final class HudActionDeckMetrics {
  static const double commandLineHeight = 48;
}
