import 'dart:async';

import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_command_dispatcher_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomatic_popup_inbox.dart';
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
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'diplomatic_dialog_results.dart';
part 'diplomatic_event_dialog.dart';
part 'diplomatic_message_dialog.dart';
part 'diplomatic_popup_event_policy.dart';
part 'diplomatic_popup_notification_router.dart';
part 'diplomatic_popup_payloads.dart';
part 'diplomatic_popup_presentation.dart';
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
  final DiplomaticPopupInbox _inbox = DiplomaticPopupInbox();
  bool _dialogOpen = false;
  bool _handoffBlocked = false;
  bool _showScheduled = false;
  bool _restoreScheduled = false;
  HudMinimizedPopupEntry? _deferredRestoreEntry;

  @override
  void didUpdateWidget(covariant DiplomaticMessagePopupOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameSave?.id == widget.gameSave?.id) return;
    _inbox.clear();
    _showScheduled = false;
    _restoreScheduled = false;
    _deferredRestoreEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.gameSave;
    if (save == null) return const SizedBox.shrink();
    final activePlayerId = _watchActivePopupPlayerId();
    final gameState = ref.watch(gameStateProvider(save.id)).value;
    final minimizedState = ref.watch(hudMinimizedPopupsProvider);
    final popupPresentationBlocked = ref.watch(
      gamePlayerControlControllerProvider.select(
        (control) => control.phase.blocksHumanInput,
      ),
    );
    _handoffBlocked = ref.watch(gameHandoffProvider) != null;
    _listenForDiplomacyNotifications();
    _listenForRestoreRequests();
    if (minimizedState.loaded &&
        !_handoffBlocked &&
        !popupPresentationBlocked) {
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

  void _scanIncomingMessages(String activePlayerId, GameClientState? state) {
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
    final player = widget.gameSave?.playerById(playerId);
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
