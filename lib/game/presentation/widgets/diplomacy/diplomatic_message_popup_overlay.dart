import 'dart:async';
import 'dart:collection';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/game/game_actions_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'diplomatic_dialog_results.dart';
part 'diplomatic_event_dialog.dart';
part 'diplomatic_message_dialog.dart';
part 'diplomatic_popup_event_policy.dart';
part 'diplomatic_popup_inbox.dart';
part 'diplomatic_popup_notification_router.dart';
part 'diplomatic_popup_payloads.dart';
part 'diplomatic_proposal_dialog.dart';

class DiplomaticMessagePopupOverlay extends ConsumerStatefulWidget {
  final GameSave? gameSave;

  const DiplomaticMessagePopupOverlay({this.gameSave, super.key});

  @override
  ConsumerState<DiplomaticMessagePopupOverlay> createState() =>
      _DiplomaticMessagePopupOverlayState();
}

class _DiplomaticMessagePopupOverlayState
    extends ConsumerState<DiplomaticMessagePopupOverlay> {
  final _DiplomaticPopupInbox _inbox = _DiplomaticPopupInbox();
  bool _dialogOpen = false;
  bool _handoffBlocked = false;
  bool _showScheduled = false;

  @override
  void didUpdateWidget(covariant DiplomaticMessagePopupOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameSave?.id == widget.gameSave?.id) return;
    _inbox.clear();
    _showScheduled = false;
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.gameSave;
    if (save == null) return const SizedBox.shrink();
    final activePlayerId = _watchActivePopupPlayerId();
    final gameState = ref.watch(gameStateProvider(save.id)).value;
    final minimizedState = ref.watch(hudMinimizedPopupsProvider);
    _handoffBlocked = ref.watch(gameHandoffProvider) != null;
    _listenForDiplomacyNotifications();
    _listenForRestoreRequests();
    if (minimizedState.loaded && !_handoffBlocked) {
      _scanIncomingMessages(activePlayerId, gameState);
      _scheduleShowNext();
    }
    return const SizedBox.shrink();
  }

  void _listenForDiplomacyNotifications() {
    ref.listen<List<GameEventNotification>>(gameEventNotificationsProvider, (
      _,
      next,
    ) {
      if (next.isEmpty) {
        _inbox.clear();
        return;
      }
      final router = _notificationRouter();
      for (final notification in next) {
        router.route(notification);
      }
      _scheduleShowNext();
    });
  }

  _DiplomaticPopupNotificationRouter _notificationRouter() {
    return _DiplomaticPopupNotificationRouter(
      inbox: _inbox,
      isMessageMinimized: _isMessageMinimized,
      isProposalMinimized: _isProposalMinimized,
    );
  }

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
      if (entry == null || !entry.belongsToSave(_saveId)) {
        return;
      }
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

  void _scanIncomingMessages(String activePlayerId, GameState? state) {
    if (activePlayerId.isEmpty || state == null) return;
    for (final proposal in state.diplomacy.proposalsFor(activePlayerId)) {
      if (!_shouldPromptProposal(proposal, activePlayerId)) continue;
      _queueProposal(proposal.id);
    }
    for (final message in state.diplomacy.messagesFor(activePlayerId)) {
      if (!_shouldPrompt(message, activePlayerId)) continue;
      _queueMessage(message.id);
    }
  }

  void _queueMessage(String messageId) {
    _inbox.queueMessage(messageId, minimized: _isMessageMinimized(messageId));
  }

  void _queueProposal(String proposalId) {
    _inbox.queueProposal(
      proposalId,
      minimized: _isProposalMinimized(proposalId),
    );
  }

  void _scheduleShowNext() {
    if (!_canSchedulePopupPresentation()) return;
    _showScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showScheduled = false;
      unawaited(_showNext());
    });
  }

  Future<void> _showNext() async {
    if (!_canShowQueuedPopup()) return;
    final activePlayerId = _readActivePopupPlayerId();
    if (activePlayerId.isEmpty) return;

    final proposal = _takeNextProposalFor(activePlayerId);
    if (proposal != null) {
      await _showProposal(proposal);
      return;
    }

    final message = _takeNextMessageFor(activePlayerId);
    if (message != null) {
      await _showMessage(message);
      return;
    }

    final notification = _takeNextDiplomacyEventFor(activePlayerId);
    if (notification != null) {
      await _showDiplomacyEvent(notification);
    }
  }

  bool _canSchedulePopupPresentation() {
    return !_showScheduled &&
        !_dialogOpen &&
        !_handoffBlocked &&
        ref.read(gameHandoffProvider) == null &&
        _hasPendingPopup &&
        ref.read(hudMinimizedPopupsProvider).loaded;
  }

  bool _canShowQueuedPopup() {
    return mounted &&
        !_dialogOpen &&
        _hasPendingPopup &&
        ref.read(gameHandoffProvider) == null &&
        ref.read(hudMinimizedPopupsProvider).loaded;
  }

  bool get _hasPendingPopup => _inbox.hasPendingPopup;

  DiplomaticProposal? _takeNextProposalFor(String activePlayerId) {
    final pendingProposalCount = _inbox.pendingProposalCount;
    for (var i = 0; i < pendingProposalCount; i++) {
      final proposalId = _inbox.takeProposalId();
      final proposal = _proposalById(proposalId);
      if (proposal == null || _isProposalMinimized(proposalId)) continue;
      if (proposal.toPlayerId != activePlayerId) {
        _requeueLiveProposal(proposal);
        continue;
      }
      if (!_shouldPromptProposal(proposal, activePlayerId)) continue;
      _inbox.markProposalSeen(proposal.id);
      return proposal;
    }
    return null;
  }

  DiplomaticMessage? _takeNextMessageFor(String activePlayerId) {
    final pendingMessageCount = _inbox.pendingMessageCount;
    for (var i = 0; i < pendingMessageCount; i++) {
      final messageId = _inbox.takeMessageId();
      final message = _messageById(messageId);
      if (message == null || _isMessageMinimized(messageId)) continue;
      if (message.toPlayerId != activePlayerId) {
        _requeueLiveMessage(message);
        continue;
      }
      if (!_shouldPrompt(message, activePlayerId)) continue;
      _inbox.markMessageSeen(message.id);
      return message;
    }
    return null;
  }

  GameEventNotification? _takeNextDiplomacyEventFor(String activePlayerId) {
    final pendingDiplomacyEventCount = _inbox.pendingDiplomacyEventCount;
    for (var i = 0; i < pendingDiplomacyEventCount; i++) {
      final notification = _inbox.takeDiplomacyEvent();
      if (!notification.isVisibleTo(activePlayerId)) {
        _inbox.queueDiplomacyEvent(notification);
        continue;
      }
      if (!_DiplomaticPopupEventPolicy.isPassivePopupEvent(
        notification.event,
      )) {
        continue;
      }
      return notification;
    }
    return null;
  }

  void _requeueLiveProposal(DiplomaticProposal proposal) {
    if (!_isProposalExpired(proposal)) _inbox.requeueProposal(proposal.id);
  }

  void _requeueLiveMessage(DiplomaticMessage message) {
    if (!_isMessageExpired(message)) _inbox.requeueMessage(message.id);
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

    _dialogOpen = true;
    final result = await showGameModal<_DiplomaticMessageDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiplomaticMessageDialog(
        fromPlayerName: fromPlayerName,
        fromPlayerColor: fromPlayerColor,
        topicLabel: topicLabel,
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
      _dismissNotificationsForMessage(message.id);
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

    _dialogOpen = true;
    final result = await showGameModal<_DiplomaticProposalDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiplomaticProposalDialog(
        fromPlayerName: fromPlayerName,
        fromPlayerColor: fromPlayerColor,
        proposalLabel: proposalLabel,
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
      _dismissNotificationsForProposal(proposal.id);
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

    _dialogOpen = true;
    await showGameModal<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DiplomaticEventDialog(message: message, accent: color),
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

  void _dismissNotificationsForMessage(String messageId) {
    final notifications = [...ref.read(gameEventNotificationsProvider)];
    for (final notification in notifications) {
      final event = notification.event;
      if (event is DiplomaticMessageSentEvent && event.messageId == messageId) {
        ref
            .read(gameEventNotificationsProvider.notifier)
            .dismiss(notification.id);
      }
    }
  }

  void _dismissNotificationsForProposal(String proposalId) {
    final notifications = [...ref.read(gameEventNotificationsProvider)];
    for (final notification in notifications) {
      final event = notification.event;
      if (event is DiplomaticProposalSentEvent &&
          event.proposalId == proposalId) {
        ref
            .read(gameEventNotificationsProvider.notifier)
            .dismiss(notification.id);
      }
    }
  }

  DiplomaticMessage? _messageById(String? messageId) {
    if (messageId == null || messageId.isEmpty) return null;
    final save = widget.gameSave;
    if (save != null) {
      final state = ref.read(gameStateProvider(save.id)).value;
      final stateMessage = state?.diplomacy.messages[messageId];
      if (stateMessage != null) return stateMessage;
    }
    return _inbox.messageById(messageId);
  }

  DiplomaticProposal? _proposalById(String? proposalId) {
    if (proposalId == null || proposalId.isEmpty) return null;
    final save = widget.gameSave;
    if (save != null) {
      final state = ref.read(gameStateProvider(save.id)).value;
      final stateProposal = state?.diplomacy.pendingProposals[proposalId];
      if (stateProposal != null) return stateProposal;
    }
    return _inbox.proposalById(proposalId);
  }

  bool _shouldPrompt(DiplomaticMessage message, String activePlayerId) {
    return message.toPlayerId == activePlayerId &&
        !message.responded &&
        !_isMessageExpired(message) &&
        !_inbox.hasSeenMessage(message.id) &&
        !_isMessageMinimized(message.id);
  }

  bool _shouldPromptProposal(
    DiplomaticProposal proposal,
    String activePlayerId,
  ) {
    return proposal.toPlayerId == activePlayerId &&
        !_isProposalExpired(proposal) &&
        !_inbox.hasSeenProposal(proposal.id) &&
        !_isProposalMinimized(proposal.id);
  }

  bool _isMessageExpired(DiplomaticMessage message) {
    return message.isExpired(widget.gameSave?.turn ?? message.createdTurn);
  }

  bool _isProposalExpired(DiplomaticProposal proposal) {
    return proposal.isExpired(widget.gameSave?.turn ?? proposal.createdTurn);
  }

  bool _isMessageMinimized(String messageId) {
    return ref
        .read(hudMinimizedPopupsProvider)
        .hasEntry(_DiplomaticPopupPayloads.messagePopupId(_saveId, messageId));
  }

  bool _isProposalMinimized(String proposalId) {
    return ref
        .read(hudMinimizedPopupsProvider)
        .hasEntry(
          _DiplomaticPopupPayloads.proposalPopupId(_saveId, proposalId),
        );
  }

  Color _playerColor(String playerId) {
    final player = _playerById(widget.gameSave, playerId);
    if (player != null) return Color(player.colorValue);
    final save = widget.gameSave;
    if (save != null) {
      final state = ref.read(gameStateProvider(save.id)).value;
      final colorValue = state?.colorForPlayer(playerId);
      if (colorValue != null) return Color(colorValue);
    }
    return Color(Player.palette.first);
  }

  String _watchActivePopupPlayerId() {
    final activePlayerId = ref.watch(
      gamePlayerControlControllerProvider.select(
        (control) => control.activePlayerId,
      ),
    );
    if (activePlayerId.isNotEmpty) return activePlayerId;
    return _DiplomaticPopupEventPolicy.activePlayerIdFromNotifications(
      ref.watch(gameEventNotificationsProvider),
    );
  }

  String _readActivePopupPlayerId() {
    final activePlayerId = ref
        .read(gamePlayerControlControllerProvider)
        .activePlayerId;
    if (activePlayerId.isNotEmpty) return activePlayerId;
    return _DiplomaticPopupEventPolicy.activePlayerIdFromNotifications(
      ref.read(gameEventNotificationsProvider),
    );
  }

  String get _saveId => widget.gameSave?.id ?? 'transient';
}
