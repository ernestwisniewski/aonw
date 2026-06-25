part of 'hud_action_deck.dart';

extension _HudActionDeckCombatModal on _HudActionDeckState {
  HudCombatPreview? get _combatConfirmationPreview {
    final pendingAction = widget.gameState?.pendingAction;
    if (pendingAction is! PendingAttackTargeting ||
        !pendingAction.hasDefenderTarget) {
      return null;
    }
    final preview = widget.combatPreview;
    if (preview == null ||
        preview.attackerUnitId != pendingAction.attackerUnitId ||
        preview.defenderUnitId.isEmpty) {
      return null;
    }
    return preview;
  }

  void _syncCombatModal() {
    final preview = _combatConfirmationPreview;
    _queueCombatPreviewNotifierUpdate(preview);
    if (preview == null) {
      _lastRequestedCombatPreviewKey = null;
      if (_combatModalOpen && _combatModalContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final modalContext = _combatModalContext;
          if (modalContext == null) return;
          unawaited(Navigator.of(modalContext).maybePop());
        });
      }
      return;
    }

    final key = _combatPreviewKey(preview);
    if (_combatModalOpen || _lastRequestedCombatPreviewKey == key) return;
    _lastRequestedCombatPreviewKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_showCombatModal(preview));
    });
  }

  void _queueCombatPreviewNotifierUpdate(HudCombatPreview? preview) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _combatPreviewNotifier.value = preview;
    });
  }

  Future<void> _showCombatModal(HudCombatPreview preview) async {
    if (_combatModalOpen || !mounted) return;
    _combatModalOpen = true;
    _combatPreviewNotifier.value = preview;

    await showGameModal<void>(
      context: context,
      barrierDismissible: false,
      builder: (modalContext) {
        _combatModalContext = modalContext;
        return ValueListenableBuilder<HudCombatPreview?>(
          valueListenable: _combatPreviewNotifier,
          builder: (context, currentPreview, _) {
            if (currentPreview == null) return const SizedBox.shrink();
            return _CombatConfirmationDialog(
              preview: currentPreview,
              onCancel: () {
                unawaited(Navigator.of(modalContext).maybePop());
                _cancelCombatAttack();
              },
              onConfirm: () {
                unawaited(Navigator.of(modalContext).maybePop());
                _confirmCombatAttack(
                  currentPreview,
                  CityConquestAction.capture,
                );
              },
              onDestroyCity:
                  currentPreview.targetIsCity && currentPreview.defenderKilled
                  ? () {
                      unawaited(Navigator.of(modalContext).maybePop());
                      _confirmCombatAttack(
                        currentPreview,
                        CityConquestAction.destroy,
                      );
                    }
                  : null,
            );
          },
        );
      },
    );

    if (!mounted) return;
    _combatModalOpen = false;
    _combatModalContext = null;
    _lastRequestedCombatPreviewKey = null;
  }

  void _confirmCombatAttack(
    HudCombatPreview preview,
    CityConquestAction cityConquestAction,
  ) {
    final pendingAction = _currentGameState()?.pendingAction;
    if (pendingAction is! PendingAttackTargeting ||
        pendingAction.attackerUnitId != preview.attackerUnitId ||
        !pendingAction.hasDefenderTarget) {
      return;
    }
    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .dispatch(
            AttackHexCommand(
              pendingAction.attackerUnitId,
              pendingAction.defenderCol!,
              pendingAction.defenderRow!,
              cityConquestAction: cityConquestAction,
            ),
          ),
    );
  }

  void _cancelCombatAttack() {
    final pendingAction = _currentGameState()?.pendingAction;
    if (pendingAction is! PendingAttackTargeting) return;
    unawaited(
      ref
          .read(hudCommandDispatcherProvider)
          .dispatch(CancelAttackTargetingCommand(pendingAction.attackerUnitId)),
    );
  }

  String _combatPreviewKey(HudCombatPreview preview) {
    return [
      preview.attackerUnitId,
      preview.defenderUnitId,
      preview.attackerHpBefore,
      preview.defenderHpBefore,
      preview.attackerHpAfter,
      preview.defenderHpAfter,
    ].join(':');
  }
}
