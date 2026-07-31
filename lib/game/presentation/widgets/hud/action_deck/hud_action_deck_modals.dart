part of 'hud_action_deck.dart';

extension _HudActionDeckModals on _HudActionDeckState {
  void _syncModals() {
    final combatPreview = _combatConfirmationPreview;
    // Combat confirmation owns the modal lane; detail waits for its route.
    final detail = combatPreview == null
        ? _activeDetail(AppLocalizations.of(context))
        : null;
    final availableKind = combatPreview != null
        ? _HudModalKind.combat
        : detail != null
        ? _HudModalKind.detail
        : null;
    final availableKey = combatPreview != null
        ? _combatModalRequestKey(combatPreview)
        : detail != null
        ? _detailModalRequestKey(detail)
        : null;
    if (_dismissedModalRequestKey != null &&
        _dismissedModalRequestKey != availableKey) {
      _dismissedModalRequestKey = null;
    }
    final requestDismissed =
        availableKey != null && availableKey == _dismissedModalRequestKey;
    final desiredKind = requestDismissed ? null : availableKind;
    final requestedKey = requestDismissed ? null : availableKey;
    final requestChanged = requestedKey != _requestedModalKey;
    if (requestChanged) {
      _requestedModalKey = requestedKey;
      _modalRevision += 1;
    }
    final revision = _modalRevision;

    if (!requestDismissed && combatPreview != null) {
      _queueCombatPreviewNotifierUpdate(combatPreview, revision);
    } else if (!requestDismissed && detail != null) {
      _queueDetailNotifierUpdate(detail, revision);
    }

    if (desiredKind == null) {
      _syncMissingModal(requestChanged: requestChanged, revision: revision);
      return;
    }

    switch (_modalPhase) {
      case _HudModalPhase.idle:
        _modalKind = desiredKind;
        _modalPhase = _HudModalPhase.queued;
        _queueDesiredModalOpen(
          detail: detail,
          combatPreview: combatPreview,
          revision: revision,
        );
        return;
      case _HudModalPhase.queued:
        if (requestChanged) {
          _modalKind = desiredKind;
          _queueDesiredModalOpen(
            detail: detail,
            combatPreview: combatPreview,
            revision: revision,
          );
        }
        return;
      case _HudModalPhase.open:
        if (_modalKind == desiredKind) {
          final session = _modalSession;
          if (session != null) {
            _modalSession = session.withRequestKey(requestedKey!);
          }
          return;
        }
        _modalPhase = _HudModalPhase.closing;
        _queueModalClose(revision);
        return;
      case _HudModalPhase.closing:
        if (_modalKind == desiredKind && !_modalCloseStarted) {
          _modalPhase = _HudModalPhase.open;
          final session = _modalSession;
          if (session != null) {
            _modalSession = session.withRequestKey(requestedKey!);
          }
        } else if (requestChanged && !_modalCloseStarted) {
          _queueModalClose(revision);
        }
        return;
    }
  }

  void _syncMissingModal({
    required bool requestChanged,
    required int revision,
  }) {
    switch (_modalPhase) {
      case _HudModalPhase.idle:
        return;
      case _HudModalPhase.queued:
        _modalPhase = _HudModalPhase.idle;
        _modalKind = null;
        return;
      case _HudModalPhase.open:
        _modalPhase = _HudModalPhase.closing;
        _queueModalClose(revision);
        return;
      case _HudModalPhase.closing:
        if (requestChanged && !_modalCloseStarted) {
          _queueModalClose(revision);
        }
        return;
    }
  }

  void _queueDesiredModalOpen({
    required SelectionDetailViewModel? detail,
    required HudCombatPreview? combatPreview,
    required int revision,
  }) {
    if (combatPreview != null) {
      _queueCombatModalOpen(combatPreview, revision);
    } else if (detail != null) {
      _queueDetailModalOpen(detail, revision);
    }
  }

  void _queueModalClose(int revision) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _modalRevision ||
          _modalPhase != _HudModalPhase.closing ||
          _modalCloseStarted) {
        return;
      }
      final session = _modalSession;
      final kind = _modalKind;
      if (session == null || kind == null) return;
      _popActiveModal(kind: kind, routeRevision: session.routeRevision);
    });
  }

  bool _popActiveModal({
    required _HudModalKind kind,
    required int routeRevision,
    bool dismissRequest = false,
  }) {
    if (_modalCloseStarted) return false;
    final session = _modalSession;
    if (_modalKind != kind ||
        session == null ||
        session.kind != kind ||
        session.routeRevision != routeRevision ||
        session.navigator == null ||
        session.route == null) {
      return false;
    }
    if (!_markModalRouteClosing(kind: kind, routeRevision: routeRevision)) {
      return false;
    }
    if (dismissRequest) {
      _dismissedModalRequestKey = session.requestKey;
    }
    final navigator = session.navigator!;
    final route = session.route!;
    if (!route.isActive) return true;
    if (!route.isCurrent) {
      navigator.removeRoute(route);
      return true;
    }
    navigator.pop();
    return true;
  }

  bool _markModalRouteClosing({
    required _HudModalKind kind,
    required int routeRevision,
  }) {
    final session = _modalSession;
    if (_modalKind != kind ||
        session == null ||
        session.kind != kind ||
        session.routeRevision != routeRevision) {
      return false;
    }
    _modalSession = session.startClosing(_modalRevision);
    _modalPhase = _HudModalPhase.closing;
    return true;
  }

  _HudModalFinish _finishModalRoute({
    required _HudModalKind kind,
    required int routeRevision,
    required ModalRoute<void> route,
  }) {
    final session = _modalSession;
    if (_modalKind != kind ||
        session == null ||
        session.kind != kind ||
        session.routeRevision != routeRevision ||
        !identical(session.route, route)) {
      return _HudModalFinish.stale;
    }
    final requestChangedAfterClose =
        session.closingAtRevision != null &&
        _modalRevision != session.closingAtRevision;
    final reopen =
        _modalPhase == _HudModalPhase.closing &&
        _requestedModalKey != null &&
        (_requestedModalKey != session.closingRequestKey ||
            requestChangedAfterClose);
    _modalPhase = _HudModalPhase.idle;
    _modalKind = null;
    _modalSession = null;
    if (reopen) {
      _syncModals();
    } else if (_requestedModalKey != null) {
      _requestedModalKey = null;
      _modalRevision += 1;
    }
    return reopen ? _HudModalFinish.reopen : _HudModalFinish.dismissed;
  }

  String _detailModalRequestKey(SelectionDetailViewModel detail) {
    return 'detail:${detail.contentKey}';
  }

  String _combatModalRequestKey(HudCombatPreview preview) {
    return 'combat:${_combatPreviewKey(preview)}';
  }
}
