part of 'game_hud_overlay_host.dart';

class _HudOverlayGamepadFocus {
  const _HudOverlayGamepadFocus({
    required this.focusedTargetId,
    required this.selectionActions,
  });

  final String? focusedTargetId;
  final List<Widget> selectionActions;
}

extension _GameHudOverlayHostGamepadFocus on _GameHudOverlayHostState {
  _HudOverlayGamepadFocus _resolveHudGamepadFocus({
    required HudOverlayFrame frame,
    required HudCommandDispatcher dispatcher,
    required GameState? gameState,
    required String activePlayerId,
    required bool enabled,
    required List<Widget> selectionActions,
  }) {
    final targets = [
      ..._topResourceFocusTargets(
        frame: frame,
        activePlayerId: activePlayerId,
        gameState: gameState,
        onGoldPressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.gold),
        onSciencePressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.science),
        onStabilityPressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.stability),
        onResourcesPressed: () =>
            dispatcher.toggleResourceBreakdown(ResourceBreakdownType.resources),
        onTurnPressed: () => _openTurnTimeline(
          dispatcher: dispatcher,
          frame: frame,
          gameState: gameState,
          activePlayerId: activePlayerId,
        ),
        onVictoryPressed: dispatcher.toggleVictoryBreakdown,
      ),
      ..._selectionActionFocusTargets(
        selectionActions,
        activePlayerId: activePlayerId,
        gameState: gameState,
      ),
    ];
    _publishHudGamepadFocusTargets(targets, enabled: enabled);
    final focusState = ref.read(hudGamepadFocusControllerProvider);
    final focusedTargetId =
        focusState.active &&
            targets.any((target) => target.id == focusState.targetId)
        ? focusState.targetId
        : null;
    return _HudOverlayGamepadFocus(
      focusedTargetId: focusedTargetId,
      selectionActions: _focusSelectionActions(
        selectionActions,
        focusedTargetId,
      ),
    );
  }

  void _openTurnTimeline({
    required HudCommandDispatcher dispatcher,
    required HudOverlayFrame frame,
    required GameState? gameState,
    required String activePlayerId,
  }) {
    dispatcher.closeResourceBreakdown();
    ref
        .read(hudGamepadPopupInputCaptureProvider.notifier)
        .setSourceCaptured('hudOverlay.turnTimeline', true);
    unawaited(
      showTurnTimelinePopup(
        context,
        entries: frame.activityLogEntries,
        gameSave: widget.gameSave,
        currentState: gameState,
        activePlayerId: activePlayerId,
        gamepadInputListenable: widget.gamepadInputListenable,
      ).whenComplete(() {
        if (!mounted) return;
        ref
            .read(hudGamepadPopupInputCaptureProvider.notifier)
            .setSourceCaptured('hudOverlay.turnTimeline', false);
      }),
    );
  }

  void _publishHudGamepadFocusTargets(
    List<HudGamepadFocusTarget> targets, {
    required bool enabled,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _gamepadFocusRegistry.setSource(
        'hudOverlay',
        enabled ? targets : const [],
      );
    });
  }

  List<HudGamepadFocusTarget> _topResourceFocusTargets({
    required HudOverlayFrame frame,
    required String activePlayerId,
    required GameState? gameState,
    required VoidCallback onGoldPressed,
    required VoidCallback onSciencePressed,
    required VoidCallback onStabilityPressed,
    required VoidCallback onResourcesPressed,
    required VoidCallback onTurnPressed,
    required VoidCallback onVictoryPressed,
  }) {
    if (!frame.layoutMetrics.showTopResources) {
      return const <HudGamepadFocusTarget>[];
    }
    final l10n = AppLocalizations.of(context);
    return [
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.topResources,
        id: HudGamepadFocusTargetIds.resourceGold,
        label: l10n.commonGold,
        onActivate: onGoldPressed,
        activationKey: _topResourceActivationKey(
          'gold',
          activePlayerId,
          gameState,
        ),
      ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.topResources,
        id: HudGamepadFocusTargetIds.resourceScience,
        label: l10n.commonScience,
        onActivate: onSciencePressed,
        activationKey: _topResourceActivationKey(
          'science',
          activePlayerId,
          gameState,
        ),
      ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.topResources,
        id: HudGamepadFocusTargetIds.resourceStability,
        label: l10n.commonStability,
        onActivate: onStabilityPressed,
        activationKey: _topResourceActivationKey(
          'stability',
          activePlayerId,
          gameState,
        ),
      ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.topResources,
        id: HudGamepadFocusTargetIds.resourceResources,
        label: l10n.commonResources,
        onActivate: onResourcesPressed,
        activationKey: _topResourceActivationKey(
          'resources',
          activePlayerId,
          gameState,
        ),
      ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.topResources,
        id: HudGamepadFocusTargetIds.resourceTurn,
        label: l10n.commonTurn,
        onActivate: onTurnPressed,
        activationKey: _topResourceActivationKey(
          'turn',
          activePlayerId,
          gameState,
        ),
      ),
      HudGamepadFocusTarget(
        section: HudGamepadFocusSection.topResources,
        id: HudGamepadFocusTargetIds.resourceVictory,
        label: l10n.gameGoalTitle,
        onActivate: onVictoryPressed,
        activationKey: _topResourceActivationKey(
          'victory',
          activePlayerId,
          gameState,
        ),
      ),
    ];
  }

  List<HudGamepadFocusTarget> _selectionActionFocusTargets(
    List<Widget> actions, {
    required String activePlayerId,
    required GameState? gameState,
  }) {
    return [
      for (final action in actions)
        if (action is SelectionCommandChip &&
            action.enabled &&
            action.onTap != null)
          HudGamepadFocusTarget(
            section: HudGamepadFocusSection.selectionActions,
            id: HudGamepadFocusTargetIds.selectionAction(action.actionId),
            label: action.label,
            onActivate: action.onTap!,
            activationKey: Object.hash(
              widget.gameSave.id,
              activePlayerId,
              gameState,
              action.actionId,
            ),
          ),
    ];
  }

  Object _topResourceActivationKey(
    String resourceId,
    String activePlayerId,
    GameState? gameState,
  ) {
    return Object.hash(
      widget.gameSave.id,
      resourceId,
      activePlayerId,
      gameState,
    );
  }

  List<Widget> _focusSelectionActions(List<Widget> actions, String? targetId) {
    return [
      for (final action in actions)
        if (action is SelectionCommandChip)
          HudGamepadFocusRing(
            focused:
                targetId ==
                HudGamepadFocusTargetIds.selectionAction(action.actionId),
            borderRadius: GameUiTheme.chipBorderRadius,
            child: action,
          )
        else
          action,
    ];
  }
}
