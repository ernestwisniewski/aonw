part of 'hud_action_deck.dart';

extension _HudActionDeckLayout on _HudActionDeckState {
  Widget _buildLayout(BuildContext context) {
    final providerAutoActionFlowEnabled = ref.watch(hudAutoActionFlowProvider);
    final providerAutoTurnFlowEnabled = ref.watch(hudAutoTurnFlowProvider);
    if (_autoActionFlowEnabled != providerAutoActionFlowEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setAutoActionFlowEnabled(providerAutoActionFlowEnabled);
      });
    }
    if (_autoTurnFlowEnabled != providerAutoTurnFlowEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setAutoTurnFlowEnabled(providerAutoTurnFlowEnabled);
      });
    }

    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.animatingUnitIdsListenable,
      builder: (context, animatingUnitIds, _) {
        final l10n = AppLocalizations.of(context);
        final viewModel = HudCommandLineViewModel.create(
          gameSave: widget.gameSave,
          activePlayerId: widget.activePlayerId,
          activePlayerCanAct: widget.activePlayerCanAct,
          gameState: widget.gameState,
          isUnitAnimating: animatingUnitIds.isNotEmpty,
          readyToEndTurn: widget.readyToEndTurn,
          remainingActionCount: widget.remainingActionCount,
          actionHintLabel: widget.actionHintLabel,
          l10n: l10n,
        );
        final playerColor = viewModel.activePlayerColorValue != null
            ? PlayerColorTheme.resolve(viewModel.activePlayerColorValue!)
            : GameHudTheme.accentFallback;
        final size = MediaQuery.sizeOf(context);
        final compactLandscape =
            size.height < HudLayoutMetrics.landscapePhoneHeight &&
            size.width > size.height;
        final selection = _canShowSelection ? widget.selection : null;
        final suppressSelectionActions =
            !widget.showSelectionInfo || widget.selection == null;
        final actions = suppressSelectionActions
            ? const <Widget>[]
            : widget.selectionActions;
        final deckMaxWidth = compactLandscape
            ? (size.width - 120)
                  .clamp(360.0, HudActionDeck.compactLandscapeMaxWidth)
                  .toDouble()
            : widget.panelOpen
            ? HudActionDeck.panelOpenMaxWidth
            : size.width >= 900
            ? HudActionDeck.wideMaxWidth
            : size.width;
        final horizontalPadding = size.width >= 900 ? 16.0 : 10.0;
        final leftPadding = compactLandscape
            ? HudActionDeck.compactLandscapeSideMenuReserve
            : horizontalPadding;
        final rightPadding = compactLandscape ? 8.0 : horizontalPadding;
        final contextLine = selection != null
            ? SelectionContextLine(
                selection: selection,
                onChipTap: widget.onToggleSelectionDetail,
              )
            : null;
        final commandLine = HudCommandLine(
          viewModel: viewModel,
          playerColor: playerColor,
          turn: widget.gameSave.turn,
          readyToEndTurn: widget.readyToEndTurn,
          isUnitAnimating: animatingUnitIds.isNotEmpty,
          currentActionIndex: widget.currentActionIndex,
          turnActionOptions: widget.turnActionOptions,
          pulseActionBorder: _actionCompletionPulseVisible,
          forceCompact: compactLandscape,
          onEndTurn: _endTurn,
          onNextAction: _nextAction,
          onActionSelected: _selectTurnAction,
        );

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              leftPadding,
              0,
              rightPadding,
              compactLandscape ? 6 : 10,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                key: FirstTurnCoachmarkTargets.actionDeck,
                child: ConstrainedBox(
                  key: const Key('hudActionDeck.surface'),
                  constraints: BoxConstraints(maxWidth: deckMaxWidth),
                  child: Column(
                    key: const Key('hudActionDeck'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (compactLandscape && _compactDeckCollapsed)
                        _CompactCollapsedDeck(
                          commandLine: commandLine,
                          toggleTooltip: l10n.hudActionDeckExpandTooltip,
                          onToggle: _toggleCompactDeck,
                        )
                      else ...[
                        if (_cityExpansionSelectionActive) ...[
                          _CityExpansionSelectionToolbar(
                            canConfirm: _cityExpansionSelectionReady,
                            confirmLabel: l10n.selectionActionConfirm,
                            cancelLabel: l10n.selectionActionCancel,
                            onConfirm: _confirmCityExpansionSelection,
                            onCancel: _cancelCityExpansionSelection,
                          ),
                          SizedBox(height: compactLandscape ? 4 : 8),
                        ],
                        if (actions.isNotEmpty) ...[
                          HudActionLine(actions: actions),
                          SizedBox(height: compactLandscape ? 4 : 8),
                        ],
                        if (compactLandscape)
                          _CompactSelectionCommandSurface(
                            contextLine: contextLine,
                            commandLine: commandLine,
                            toggleTooltip: l10n.hudActionDeckCollapseTooltip,
                            onToggle: _toggleCompactDeck,
                          )
                        else ...[
                          if (contextLine != null) ...[
                            SelectionContextSurface(child: contextLine),
                            const SizedBox(height: 8),
                          ],
                          commandLine,
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
