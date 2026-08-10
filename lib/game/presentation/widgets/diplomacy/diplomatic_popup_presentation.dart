part of 'diplomatic_message_popup_overlay.dart';

extension _PopupPresentation on _DiplomaticMessagePopupOverlayState {
  void _listenForRestoreRequests() {
    ref.listen<HudMinimizedPopupsState>(hudMinimizedPopupsProvider, (
      previous,
      next,
    ) {
      final request = next.restoreRequest;
      if (request == null ||
          request.sequence == previous?.restoreRequest?.sequence) {
        return;
      }
      final entry = next.entryFor(request.popupId) ?? request.entry;
      if (entry == null || !entry.belongsToSave(_saveId)) return;
      _restoreEntry(entry);
    });
  }

  void _restoreEntry(HudMinimizedPopupEntry entry) {
    switch (entry.kind) {
      case HudMinimizedPopupKind.diplomaticMessage:
        unawaited(_restoreMessage(entry));
      case HudMinimizedPopupKind.diplomaticProposal:
        unawaited(_restoreProposal(entry));
      case HudMinimizedPopupKind.firstTurnCoachmarks ||
          HudMinimizedPopupKind.modeBanner ||
          HudMinimizedPopupKind.technologyDiscovery ||
          HudMinimizedPopupKind.autoTurnHint:
        return;
    }
  }

  Future<void> _restoreMessage(HudMinimizedPopupEntry entry) async {
    if (!mounted || _dialogOpen) return;
    final messageId =
        entry.payload['messageId'] ??
        _DiplomaticPopupPayloads.messageIdFromPopupId(entry.id);
    final message =
        _messageById(messageId) ??
        _DiplomaticPopupPayloads.messageFromEntry(entry);
    if (message == null) return;
    final activePlayerId = _readActivePopupPlayerId();
    if (activePlayerId.isNotEmpty && message.toPlayerId != activePlayerId) {
      return;
    }
    if (message.responded || _isMessageExpired(message)) return;
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .removeWhere((candidate) => candidate.id == entry.id);
    await _showMessage(message);
  }

  Future<void> _restoreProposal(HudMinimizedPopupEntry entry) async {
    if (!mounted || _dialogOpen) return;
    final proposalId =
        entry.payload['proposalId'] ??
        _DiplomaticPopupPayloads.proposalIdFromPopupId(entry.id);
    final proposal =
        _proposalById(proposalId) ??
        _DiplomaticPopupPayloads.proposalFromEntry(entry);
    if (proposal == null) return;
    final activePlayerId = _readActivePopupPlayerId();
    if (activePlayerId.isNotEmpty && proposal.toPlayerId != activePlayerId) {
      return;
    }
    if (_isProposalExpired(proposal)) return;
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .removeWhere((candidate) => candidate.id == entry.id);
    await _showProposal(proposal);
  }

  Future<void> _showMessage(DiplomaticMessage message) async {
    final l10n = AppLocalizations.of(context);
    final fromPlayerName = _playerName(
      l10n,
      widget.gameSave,
      message.fromPlayerId,
    );
    final fromPlayerColor = _playerColor(message.fromPlayerId);
    final topicLabel = _topicLabel(l10n, message.topic);
    final gamepadRouter = GamepadInputRouterScope.maybeOf(context);

    _dialogOpen = true;
    final result = await showGameModal<_DiplomaticMessageDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiplomaticMessageDialog(
        fromPlayerName: fromPlayerName,
        fromPlayerColor: fromPlayerColor,
        topicLabel: topicLabel,
        gamepadRouter: gamepadRouter,
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;

    if (result?.response != null) {
      await ref
          .read(gameCommandControllerProvider.notifier)
          .dispatch(
            RespondDiplomaticMessageCommand(
              playerId: message.toPlayerId,
              messageId: message.id,
              response: result!.response!,
            ),
          );
      if (!mounted) return;
      _dismissNotifications(message.id, proposal: false);
    } else if (result == null || result.minimize) {
      _minimizeMessage(
        l10n: l10n,
        message: message,
        topicLabel: topicLabel,
        fromPlayerName: fromPlayerName,
      );
    }
    _scheduleShowNext();
  }

  Future<void> _showProposal(DiplomaticProposal proposal) async {
    final l10n = AppLocalizations.of(context);
    final fromPlayerName = _playerName(
      l10n,
      widget.gameSave,
      proposal.fromPlayerId,
    );
    final fromPlayerColor = _playerColor(proposal.fromPlayerId);
    final proposalLabel = _proposalKindLabel(l10n, proposal.kind);
    final gamepadRouter = GamepadInputRouterScope.maybeOf(context);

    _dialogOpen = true;
    final result = await showGameModal<_DiplomaticProposalDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiplomaticProposalDialog(
        fromPlayerName: fromPlayerName,
        fromPlayerColor: fromPlayerColor,
        proposalLabel: proposalLabel,
        gamepadRouter: gamepadRouter,
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;

    if (result?.accepted != null) {
      await ref
          .read(gameCommandControllerProvider.notifier)
          .dispatch(
            RespondDiplomaticProposalCommand(
              playerId: proposal.toPlayerId,
              proposalId: proposal.id,
              accepted: result!.accepted!,
            ),
          );
      if (!mounted) return;
      _dismissNotifications(proposal.id, proposal: true);
    } else if (result == null || result.minimize) {
      _minimizeProposal(
        l10n: l10n,
        proposal: proposal,
        proposalLabel: proposalLabel,
        fromPlayerName: fromPlayerName,
      );
    }
    _scheduleShowNext();
  }

  Future<void> _showDiplomacyEvent(GameEventNotification notification) async {
    final l10n = AppLocalizations.of(context);
    final message = GameEventNotificationMessage.from(
      l10n,
      notification,
      widget.gameSave,
    );
    final color = _DiplomaticPopupEventPolicy.accentFor(notification.event);
    final gamepadRouter = GamepadInputRouterScope.maybeOf(context);

    _dialogOpen = true;
    await showGameModal<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DiplomaticEventDialog(
        message: message,
        accent: color,
        gamepadRouter: gamepadRouter,
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;
    _scheduleShowNext();
  }

  void _minimizeMessage({
    required AppLocalizations l10n,
    required DiplomaticMessage message,
    required String topicLabel,
    required String fromPlayerName,
  }) {
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(
          _DiplomaticPopupPayloads.messageEntry(
            saveId: _saveId,
            title: l10n.diplomacyIncomingMessageTitle,
            subtitle: '$fromPlayerName - $topicLabel',
            message: message,
          ),
        );
  }

  void _minimizeProposal({
    required AppLocalizations l10n,
    required DiplomaticProposal proposal,
    required String proposalLabel,
    required String fromPlayerName,
  }) {
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(
          _DiplomaticPopupPayloads.proposalEntry(
            saveId: _saveId,
            title: l10n.diplomacyIncomingProposalTitle,
            subtitle: '$fromPlayerName - $proposalLabel',
            proposal: proposal,
          ),
        );
  }

  void _dismissNotifications(String id, {required bool proposal}) {
    final notifications = [...ref.read(gameEventNotificationsProvider)];
    final notifier = ref.read(gameEventNotificationsProvider.notifier);
    for (final notification in notifications) {
      final descriptor = GameEventDescriptor.forEvent(notification.event);
      final linkedId = proposal
          ? descriptor.diplomaticProposalId
          : descriptor.diplomaticMessageId;
      if (linkedId == id) notifier.dismiss(notification.id);
    }
  }
}
