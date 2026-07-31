part of 'hud_action_deck.dart';

class _SelectionDetailModalModel {
  final SelectionDetailViewModel detail;
  final bool peek;

  const _SelectionDetailModalModel({required this.detail, required this.peek});
}

extension _HudActionDeckDetailModal on _HudActionDeckState {
  void _queueDetailModalOpen(SelectionDetailViewModel detail, int revision) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _modalRevision ||
          _modalPhase != _HudModalPhase.queued ||
          _modalKind != _HudModalKind.detail ||
          _requestedModalKey != _detailModalRequestKey(detail)) {
        return;
      }
      unawaited(_showDetailModal(detail, revision));
    });
  }

  void _queueDetailNotifierUpdate(
    SelectionDetailViewModel detail,
    int revision,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _modalRevision ||
          _requestedModalKey != _detailModalRequestKey(detail)) {
        return;
      }
      _detailNotifier.value = _SelectionDetailModalModel(
        detail: detail,
        peek: widget.selectionDetailPeek,
      );
    });
  }

  Future<void> _showDetailModal(
    SelectionDetailViewModel detail,
    int revision,
  ) async {
    if (!mounted ||
        revision != _modalRevision ||
        _modalPhase != _HudModalPhase.queued ||
        _modalKind != _HudModalKind.detail ||
        _requestedModalKey != _detailModalRequestKey(detail)) {
      return;
    }
    final routeRevision = ++_modalRouteRevision;
    _modalSession = _HudModalSession(
      kind: _HudModalKind.detail,
      routeRevision: routeRevision,
      requestKey: _requestedModalKey!,
    );
    _modalPhase = _HudModalPhase.open;
    _detailNotifier.value = _SelectionDetailModalModel(
      detail: detail,
      peek: widget.selectionDetailPeek,
    );

    Future<void>? routeClosed;
    ModalRoute<void>? shownRoute;
    Animation<double>? routeAnimation;
    void handleRouteStatus(AnimationStatus status) {
      if (status == AnimationStatus.reverse) {
        _markModalRouteClosing(
          kind: _HudModalKind.detail,
          routeRevision: routeRevision,
        );
      }
    }

    await showGameBottomSheet<void>(
      context: context,
      builder: (modalContext) {
        final route = ModalRoute.of<void>(modalContext)!;
        if (shownRoute == null) {
          shownRoute = route;
          final session = _modalSession;
          if (session != null &&
              session.kind == _HudModalKind.detail &&
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
        return Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            0,
            10,
            10 + MediaQuery.viewInsetsOf(modalContext).bottom,
          ),
          child: ValueListenableBuilder<_SelectionDetailModalModel?>(
            valueListenable: _detailNotifier,
            builder: (context, currentModal, _) {
              if (currentModal == null) return const SizedBox.shrink();
              return SelectionDetailSheet(
                model: currentModal.detail,
                compact: MediaQuery.sizeOf(modalContext).width < 380,
                fillWidth: true,
                bottomSheet: true,
                peek: currentModal.peek,
                cityRuleset: widget.cityRuleset,
                technologyRuleset: widget.technologyRuleset,
                onClose: () {
                  final closeAccepted = _popActiveModal(
                    kind: _HudModalKind.detail,
                    routeRevision: routeRevision,
                    dismissRequest: true,
                  );
                  if (closeAccepted) widget.onCloseSelectionDetail();
                },
                onDetachTroop: _detachTroop,
                onSelectWorkerImprovement: _selectWorkerImprovement,
                onConfirmWorkerImprovement: _confirmWorkerImprovement,
                onCancelWorkerActionSelection: _cancelWorkerActionSelection,
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
    final closedDetail = _detailNotifier.value?.detail ?? detail;
    final finish = _finishModalRoute(
      kind: _HudModalKind.detail,
      routeRevision: routeRevision,
      route: route,
    );
    if (finish == _HudModalFinish.stale) return;
    if (finish == _HudModalFinish.dismissed &&
        widget.openSelectionDetailChipId == closedDetail.chipId) {
      widget.onCloseSelectionDetail();
    }
    _queueAutoTurnFlow();
  }
}
