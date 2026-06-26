import 'dart:async';

import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/hud/hud_feedback_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notification_card.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _hudFeedbackHoldDuration = Duration(milliseconds: 2200);
const _hudFeedbackTopOffset = 96.0;

class HudFeedbackOverlay extends ConsumerStatefulWidget {
  const HudFeedbackOverlay({super.key});

  @override
  ConsumerState<HudFeedbackOverlay> createState() => _HudFeedbackOverlayState();
}

class _HudFeedbackOverlayState extends ConsumerState<HudFeedbackOverlay> {
  Timer? _holdTimer;
  Timer? _dismissTimer;
  int? _dismissingId;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pendingHandoff = ref.watch(gameHandoffProvider);
    final messages = ref.watch(hudFeedbackProvider);
    if (pendingHandoff != null || messages.isEmpty) {
      _cancelTimers();
      return const SizedBox.shrink();
    }

    final message = messages.first;
    _scheduleDismissal(message);

    return SafeArea(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              _hudFeedbackTopOffset,
              16,
              0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GameEventNotificationCard(
                key: ValueKey('hudFeedback.${message.id}'),
                message: GameEventNotificationMessage(
                  title: _titleFor(l10n, message),
                  body: _bodyFor(l10n, message),
                  details: [l10n.hudFeedbackNoTurnCostDetail],
                ),
                dismissing: message.id == _dismissingId,
                fadeDuration: GameMotion.scene,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations l10n, HudFeedbackMessage message) {
    if (message.title.isNotEmpty) return message.title;
    return switch (message.kind) {
      HudFeedbackKind.autoExploreNoTarget =>
        l10n.hudFeedbackAutoExploreNoTargetTitle,
      HudFeedbackKind.artifactGuidance => l10n.hudFeedbackArtifactGuidanceTitle,
      HudFeedbackKind.actionBlocked => _actionBlockedTitle(l10n, message),
    };
  }

  String _bodyFor(AppLocalizations l10n, HudFeedbackMessage message) {
    if (message.body.isNotEmpty) return message.body;
    return switch (message.kind) {
      HudFeedbackKind.autoExploreNoTarget =>
        l10n.hudFeedbackAutoExploreNoTargetBody,
      HudFeedbackKind.artifactGuidance => l10n.hudFeedbackArtifactGuidanceBody,
      HudFeedbackKind.actionBlocked => _actionBlockedBody(l10n, message),
    };
  }

  String _actionBlockedTitle(
    AppLocalizations l10n,
    HudFeedbackMessage message,
  ) {
    return switch (message.reason) {
      HudFeedbackReason.attackProtectedByTreaty =>
        l10n.hudFeedbackAttackProtectedByTreatyTitle,
      HudFeedbackReason.movementCityOccupied =>
        l10n.hudFeedbackMovementCityOccupiedTitle,
      HudFeedbackReason.movementEnemyOccupied =>
        l10n.hudFeedbackMovementEnemyOccupiedTitle,
      HudFeedbackReason.movementForeignCity =>
        l10n.hudFeedbackMovementForeignCityTitle,
      HudFeedbackReason.movementHiddenRouteTooFar =>
        l10n.hudFeedbackMovementHiddenRouteTooFarTitle,
      HudFeedbackReason.movementBlockedTerrain =>
        l10n.hudFeedbackMovementBlockedTerrainTitle,
      HudFeedbackReason.movementInsufficientUnitMovement =>
        l10n.hudFeedbackMovementInsufficientUnitMovementTitle,
      HudFeedbackReason.movementNoRoute => l10n.hudFeedbackMovementNoRouteTitle,
      null => l10n.hudFeedbackActionBlockedTitle,
    };
  }

  String _actionBlockedBody(AppLocalizations l10n, HudFeedbackMessage message) {
    return switch (message.reason) {
      HudFeedbackReason.attackProtectedByTreaty =>
        l10n.hudFeedbackAttackProtectedByTreatyBody,
      HudFeedbackReason.movementCityOccupied =>
        l10n.hudFeedbackMovementCityOccupiedBody,
      HudFeedbackReason.movementEnemyOccupied =>
        l10n.hudFeedbackMovementEnemyOccupiedBody,
      HudFeedbackReason.movementForeignCity =>
        l10n.hudFeedbackMovementForeignCityBody,
      HudFeedbackReason.movementHiddenRouteTooFar =>
        l10n.hudFeedbackMovementHiddenRouteTooFarBody,
      HudFeedbackReason.movementBlockedTerrain =>
        l10n.hudFeedbackMovementBlockedTerrainBody,
      HudFeedbackReason.movementInsufficientUnitMovement =>
        l10n.hudFeedbackMovementInsufficientUnitMovementBody,
      HudFeedbackReason.movementNoRoute => l10n.hudFeedbackMovementNoRouteBody,
      null => l10n.hudFeedbackActionBlockedBody,
    };
  }

  void _scheduleDismissal(HudFeedbackMessage message) {
    if (_dismissingId != null) {
      if (_dismissingId == message.id) return;
      _dismissingId = null;
      _cancelTimers();
    }
    if (_holdTimer != null || _dismissTimer != null) return;

    _holdTimer = Timer(_hudFeedbackHoldDuration, () {
      if (!mounted) return;
      setState(() => _dismissingId = message.id);
      _dismissTimer = Timer(GameMotion.scene, () {
        if (!mounted) return;
        ref.read(hudFeedbackProvider.notifier).dismiss(message.id);
        setState(() => _dismissingId = null);
        _cancelTimers();
      });
    });
  }

  void _cancelTimers() {
    _holdTimer?.cancel();
    _dismissTimer?.cancel();
    _holdTimer = null;
    _dismissTimer = null;
    _dismissingId = null;
  }
}
