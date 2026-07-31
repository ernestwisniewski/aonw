part of 'hud_action_deck.dart';

enum _HudModalKind { detail, combat }

enum _HudModalPhase { idle, queued, open, closing }

enum _HudModalFinish { stale, dismissed, reopen }

final class _HudModalSession {
  const _HudModalSession({
    required this.kind,
    required this.routeRevision,
    required this.requestKey,
    this.navigator,
    this.route,
    this.closingAtRevision,
    this.closingRequestKey,
  });

  final _HudModalKind kind;
  final int routeRevision;
  final String requestKey;
  final NavigatorState? navigator;
  final ModalRoute<void>? route;
  final int? closingAtRevision;
  final String? closingRequestKey;

  bool get closeStarted => closingAtRevision != null;

  _HudModalSession withRequestKey(String value) => _copy(requestKey: value);

  _HudModalSession attach({
    required NavigatorState navigator,
    required ModalRoute<void> route,
  }) => _copy(navigator: navigator, route: route);

  _HudModalSession startClosing(int requestRevision) => closeStarted
      ? this
      : _copy(
          closingAtRevision: requestRevision,
          closingRequestKey: requestKey,
        );

  _HudModalSession _copy({
    String? requestKey,
    NavigatorState? navigator,
    ModalRoute<void>? route,
    int? closingAtRevision,
    String? closingRequestKey,
  }) => _HudModalSession(
    kind: kind,
    routeRevision: routeRevision,
    requestKey: requestKey ?? this.requestKey,
    navigator: navigator ?? this.navigator,
    route: route ?? this.route,
    closingAtRevision: closingAtRevision ?? this.closingAtRevision,
    closingRequestKey: closingRequestKey ?? this.closingRequestKey,
  );
}

final class _HudModalRequest {
  const _HudModalRequest.detail(this.detail)
    : kind = _HudModalKind.detail,
      combatPreview = null;

  const _HudModalRequest.combat(this.combatPreview)
    : kind = _HudModalKind.combat,
      detail = null;

  final _HudModalKind kind;
  final SelectionDetailViewModel? detail;
  final HudCombatPreview? combatPreview;
}

extension _HudActionDeckModals on _HudActionDeckState {
  void _syncModals() {
    final request = _availableModalRequest();
    final availableKey = _requestKey(request);
    if (_dismissedModalRequestKey != null &&
        _dismissedModalRequestKey != availableKey) {
      _dismissedModalRequestKey = null;
    }
    final requestDismissed = availableKey == _dismissedModalRequestKey;
    final requestedKey = requestDismissed ? null : availableKey;
    final requestChanged = requestedKey != _requestedModalKey;
    final revision = _updateRequestedModalKey(requestedKey, requestChanged);

    if (requestDismissed || request == null) {
      _syncMissingModal(requestChanged: requestChanged, revision: revision);
      return;
    }
    _queueModalNotifierUpdate(request, revision);
    _syncDesiredModal(
      request,
      requestKey: requestedKey!,
      requestChanged: requestChanged,
      revision: revision,
    );
  }

  _HudModalRequest? _availableModalRequest() {
    final combatPreview = _combatConfirmationPreview;
    if (combatPreview != null) return _HudModalRequest.combat(combatPreview);
    final detail = _activeDetail(AppLocalizations.of(context));
    return detail == null ? null : _HudModalRequest.detail(detail);
  }

  String? _requestKey(_HudModalRequest? request) {
    if (request == null) return null;
    return switch (request.kind) {
      _HudModalKind.combat => _combatModalRequestKey(request.combatPreview!),
      _HudModalKind.detail => _detailModalRequestKey(request.detail!),
    };
  }

  int _updateRequestedModalKey(String? key, bool changed) {
    if (changed) {
      _requestedModalKey = key;
      _modalRevision += 1;
    }
    return _modalRevision;
  }

  void _queueModalNotifierUpdate(_HudModalRequest request, int revision) {
    switch (request.kind) {
      case _HudModalKind.combat:
        _queueCombatPreviewNotifierUpdate(request.combatPreview!, revision);
      case _HudModalKind.detail:
        _queueDetailNotifierUpdate(request.detail!, revision);
    }
  }

  void _syncDesiredModal(
    _HudModalRequest request, {
    required String requestKey,
    required bool requestChanged,
    required int revision,
  }) {
    final desiredKind = request.kind;
    switch (_modalPhase) {
      case _HudModalPhase.idle:
        _modalKind = desiredKind;
        _modalPhase = _HudModalPhase.queued;
        _queueDesiredModalOpen(request, revision);
        return;
      case _HudModalPhase.queued:
        if (requestChanged) {
          _modalKind = desiredKind;
          _queueDesiredModalOpen(request, revision);
        }
        return;
      case _HudModalPhase.open:
        if (_modalKind == desiredKind) {
          _refreshModalSessionKey(requestKey);
          return;
        }
        _modalPhase = _HudModalPhase.closing;
        _queueModalClose(revision);
        return;
      case _HudModalPhase.closing:
        _syncClosingDesiredModal(
          desiredKind,
          requestKey: requestKey,
          requestChanged: requestChanged,
          revision: revision,
        );
        return;
    }
  }

  void _syncClosingDesiredModal(
    _HudModalKind desiredKind, {
    required String requestKey,
    required bool requestChanged,
    required int revision,
  }) {
    if (_modalCloseStarted) return;
    if (_modalKind == desiredKind) {
      _modalPhase = _HudModalPhase.open;
      _refreshModalSessionKey(requestKey);
    } else if (requestChanged) {
      _queueModalClose(revision);
    }
  }

  void _refreshModalSessionKey(String requestKey) {
    final session = _modalSession;
    if (session != null) _modalSession = session.withRequestKey(requestKey);
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

  void _queueDesiredModalOpen(_HudModalRequest request, int revision) {
    switch (request.kind) {
      case _HudModalKind.combat:
        _queueCombatModalOpen(request.combatPreview!, revision);
      case _HudModalKind.detail:
        _queueDetailModalOpen(request.detail!, revision);
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
    if (!_isActiveSession(session, kind, routeRevision)) return false;
    final activeSession = session!;
    if (!_markModalRouteClosing(kind: kind, routeRevision: routeRevision)) {
      return false;
    }
    if (dismissRequest) {
      _dismissedModalRequestKey = activeSession.requestKey;
    }
    final navigator = activeSession.navigator!;
    final route = activeSession.route!;
    if (!route.isActive) return true;
    if (!route.isCurrent) {
      navigator.removeRoute(route);
      return true;
    }
    navigator.pop();
    return true;
  }

  bool _isActiveSession(
    _HudModalSession? session,
    _HudModalKind kind,
    int routeRevision,
  ) =>
      _modalKind == kind &&
      session != null &&
      session.kind == kind &&
      session.routeRevision == routeRevision &&
      session.navigator != null &&
      session.route != null;

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
    if (!_isFinishingSession(session, kind, routeRevision, route)) {
      return _HudModalFinish.stale;
    }
    final requestChangedAfterClose =
        session!.closingAtRevision != null &&
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

  bool _isFinishingSession(
    _HudModalSession? session,
    _HudModalKind kind,
    int routeRevision,
    ModalRoute<void> route,
  ) =>
      _modalKind == kind &&
      session != null &&
      session.kind == kind &&
      session.routeRevision == routeRevision &&
      identical(session.route, route);

  String _detailModalRequestKey(SelectionDetailViewModel detail) {
    return 'detail:${detail.contentKey}';
  }

  String _combatModalRequestKey(HudCombatPreview preview) {
    return 'combat:${_combatPreviewKey(preview)}';
  }
}
