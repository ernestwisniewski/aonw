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

  void _queueCombatModalOpen(HudCombatPreview preview, int revision) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _modalRevision ||
          _modalPhase != _HudModalPhase.queued ||
          _modalKind != _HudModalKind.combat ||
          _requestedModalKey != _combatModalRequestKey(preview)) {
        return;
      }
      unawaited(_showCombatModal(preview, revision));
    });
  }

  void _queueCombatPreviewNotifierUpdate(
    HudCombatPreview preview,
    int revision,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _modalRevision ||
          _requestedModalKey != _combatModalRequestKey(preview)) {
        return;
      }
      _combatPreviewNotifier.value = preview;
    });
  }

  Future<void> _showCombatModal(HudCombatPreview preview, int revision) async {
    final requestedKey = _combatPreviewKey(preview);
    if (!mounted ||
        revision != _modalRevision ||
        _modalPhase != _HudModalPhase.queued ||
        _modalKind != _HudModalKind.combat ||
        _requestedModalKey != _combatModalRequestKey(preview) ||
        !_combatPreviewIsCurrent(requestedKey)) {
      return;
    }
    await ref
        .read(hudCommandDispatcherProvider)
        .focusUnitMapTarget(preview.attackerUnitId);

    if (!mounted ||
        revision != _modalRevision ||
        _modalPhase != _HudModalPhase.queued ||
        _modalKind != _HudModalKind.combat ||
        _requestedModalKey != _combatModalRequestKey(preview) ||
        !_combatPreviewIsCurrent(requestedKey)) {
      return;
    }

    final currentPreview = _combatConfirmationPreview!;
    final routeRevision = ++_modalRouteRevision;
    _modalSession = _HudModalSession(
      kind: _HudModalKind.combat,
      routeRevision: routeRevision,
      requestKey: _requestedModalKey!,
    );
    _modalPhase = _HudModalPhase.open;
    _combatPreviewNotifier.value = currentPreview;

    Future<void>? routeClosed;
    ModalRoute<void>? shownRoute;
    Animation<double>? routeAnimation;
    void handleRouteStatus(AnimationStatus status) {
      if (status == AnimationStatus.reverse) {
        _markModalRouteClosing(
          kind: _HudModalKind.combat,
          routeRevision: routeRevision,
        );
      }
    }

    await showGameModal<void>(
      context: context,
      barrierDismissible: false,
      builder: (modalContext) {
        final route = ModalRoute.of<void>(modalContext)!;
        if (shownRoute == null) {
          shownRoute = route;
          final session = _modalSession;
          if (session != null &&
              session.kind == _HudModalKind.combat &&
              session.routeRevision == routeRevision) {
            _modalSession = session.attach(
              navigator: Navigator.of(modalContext),
              route: route,
            );
          }
          routeClosed = route.completed.then((_) {});
          routeAnimation = route.animation;
          routeAnimation?.addStatusListener(handleRouteStatus);
        }
        if (_modalPhase == _HudModalPhase.closing && !_modalCloseStarted) {
          _queueModalClose(_modalRevision);
        }
        return PopScope(
          canPop: false,
          child: ValueListenableBuilder<HudCombatPreview?>(
            valueListenable: _combatPreviewNotifier,
            builder: (context, currentPreview, _) {
              if (currentPreview == null) return const SizedBox.shrink();
              return _CombatConfirmationDialog(
                preview: currentPreview,
                onCancel: () {
                  final closeAccepted = _popActiveModal(
                    kind: _HudModalKind.combat,
                    routeRevision: routeRevision,
                    dismissRequest: true,
                  );
                  if (closeAccepted) _cancelCombatAttack();
                },
                onConfirm: () {
                  final closeAccepted = _popActiveModal(
                    kind: _HudModalKind.combat,
                    routeRevision: routeRevision,
                    dismissRequest: true,
                  );
                  if (closeAccepted) {
                    _confirmCombatAttack(
                      currentPreview,
                      CityConquestAction.capture,
                    );
                  }
                },
                onDestroyCity:
                    currentPreview.targetIsCity && currentPreview.defenderKilled
                    ? () {
                        final closeAccepted = _popActiveModal(
                          kind: _HudModalKind.combat,
                          routeRevision: routeRevision,
                          dismissRequest: true,
                        );
                        if (closeAccepted) {
                          _confirmCombatAttack(
                            currentPreview,
                            CityConquestAction.destroy,
                          );
                        }
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
    await routeClosed;
    routeAnimation?.removeStatusListener(handleRouteStatus);

    final route = shownRoute;
    if (!mounted || route == null) return;
    final finish = _finishModalRoute(
      kind: _HudModalKind.combat,
      routeRevision: routeRevision,
      route: route,
    );
    if (finish == _HudModalFinish.stale) return;
    _queueAutoTurnFlow();
  }

  bool _combatPreviewIsCurrent(String requestedKey) {
    final currentPreview = _combatConfirmationPreview;
    return currentPreview != null &&
        _combatPreviewKey(currentPreview) == requestedKey;
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
