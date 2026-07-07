part of 'hud_action_deck.dart';

extension _HudActionDeckGamepadFocus on _HudActionDeckState {
  String? _focusedHudTargetId() {
    final state = ref.watch(hudGamepadFocusControllerProvider);
    if (!state.active) return null;
    if (state.targetId != null) return state.targetId;
    if (state.section == HudGamepadFocusSection.selectionActions) {
      return HudGamepadFocusTargetIds.bottomCommand;
    }
    return null;
  }

  void _syncActionDeckGamepadFocusTargets({
    required AppLocalizations l10n,
    required HudCommandLineViewModel viewModel,
    required bool isUnitAnimating,
  }) {
    final targets = <HudGamepadFocusTarget>[
      if (!_commandLineGamepadDisabled(viewModel, isUnitAnimating))
        HudGamepadFocusTarget(
          section: HudGamepadFocusSection.selectionActions,
          id: HudGamepadFocusTargetIds.bottomCommand,
          label: _commandLineGamepadLabel(l10n, viewModel),
          onActivate: widget.readyToEndTurn ? _endTurn : _nextAction,
          activationKey: Object.hash(
            widget.gameSave.id,
            widget.activePlayerId,
            widget.gameState,
            widget.readyToEndTurn,
          ),
        ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(hudGamepadFocusTargetRegistryProvider.notifier)
          .setSource('hudActionDeck', targets);
    });
  }

  Widget _focusCommandLine(Widget commandLine, String? focusedTargetId) {
    return HudGamepadFocusRing(
      focused: focusedTargetId == HudGamepadFocusTargetIds.bottomCommand,
      borderRadius: BorderRadius.circular(GameHudTheme.buttonRadius),
      child: commandLine,
    );
  }

  bool _commandLineGamepadDisabled(
    HudCommandLineViewModel viewModel,
    bool isUnitAnimating,
  ) {
    return widget.panelOpen ||
        widget.cityProductionPanelOpen ||
        viewModel.activePlayerFinished ||
        isUnitAnimating;
  }

  String _commandLineGamepadLabel(
    AppLocalizations l10n,
    HudCommandLineViewModel viewModel,
  ) {
    if (widget.readyToEndTurn) return l10n.endTurnTooltip(widget.gameSave.turn);
    return viewModel.actionHintLabel ?? l10n.nextActionTooltip;
  }
}
