import 'dart:async';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_focus_target.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/game/game_actions_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/providers/renderer/renderer_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notification_card.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _minorNotificationHoldDuration = Duration(milliseconds: 2500);
const _criticalNotificationHoldDuration = Duration(seconds: 4);
const _notificationFadeDuration = GameMotion.scene;
const _maxVisibleNotificationCards = 3;

class GameEventNotificationsOverlay extends ConsumerStatefulWidget {
  final GameSave? gameSave;

  const GameEventNotificationsOverlay({this.gameSave, super.key});

  @override
  ConsumerState<GameEventNotificationsOverlay> createState() =>
      _GameEventNotificationsOverlayState();
}

class _GameEventNotificationsOverlayState
    extends ConsumerState<GameEventNotificationsOverlay> {
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
    final pendingHandoff = ref.watch(gameHandoffProvider);
    final notifications = ref.watch(gameEventNotificationsProvider);
    final activePlayerId = ref.watch(
      gamePlayerControlControllerProvider.select(
        (control) => control.activePlayerId,
      ),
    );
    final visibleNotifications = [
      for (final notification in notifications)
        if (notification.isVisibleTo(activePlayerId)) notification,
    ];

    if (pendingHandoff != null || visibleNotifications.isEmpty) {
      _cancelTimers();
      return const SizedBox.shrink();
    }

    _scheduleDismissal(visibleNotifications);
    final visibleCards = visibleNotifications
        .take(_maxVisibleNotificationCards)
        .toList(growable: false);
    final overflowCount = visibleNotifications.length - visibleCards.length;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 480 ? 12.0 : 88.0;
          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final notification in visibleCards)
                      GameEventNotificationCard(
                        key: ValueKey(notification.id),
                        message: GameEventNotificationMessage.from(
                          AppLocalizations.of(context),
                          notification,
                          widget.gameSave,
                        ),
                        dismissing: notification.id == _dismissingId,
                        fadeDuration: _notificationFadeDuration,
                        maxDetailCount:
                            notification.event is CombatResolvedEvent
                            ? 2
                            : null,
                        onTap: _focusTargetFor(notification) == null
                            ? null
                            : () => unawaited(_focusNotification(notification)),
                      ),
                    if (overflowCount > 0)
                      _NotificationOverflowPill(
                        count: overflowCount,
                        onPressed: _requestActivityLogPanel,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _scheduleDismissal(List<GameEventNotification> visibleNotifications) {
    final firstId = visibleNotifications.first.id;
    if (_dismissingId != null) {
      if (visibleNotifications.any(
        (notification) => notification.id == _dismissingId,
      )) {
        return;
      }
      _dismissingId = null;
      _cancelTimers();
    }
    if (_holdTimer != null || _dismissTimer != null) return;

    _holdTimer = Timer(_holdDurationFor(visibleNotifications.first), () {
      if (!mounted) return;
      setState(() => _dismissingId = firstId);
      _dismissTimer = Timer(_notificationFadeDuration, () {
        if (!mounted) return;
        ref.read(gameEventNotificationsProvider.notifier).dismiss(firstId);
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

  Future<void> _focusNotification(GameEventNotification notification) async {
    final target = _focusTargetFor(notification);
    if (target == null) return;

    await ref
        .read(gameCommandControllerProvider.notifier)
        .dispatch(target.selectCommand);
    if (!mounted) return;
    await ref
        .read(activeRendererViewModelProvider)
        ?.handleEffect(JumpCameraEffect(col: target.col, row: target.row));
    if (!mounted) return;
    _cancelTimers();
    ref.read(gameEventNotificationsProvider.notifier).dismiss(notification.id);
  }

  void _requestActivityLogPanel() {
    ref.read(gameActivityLogPanelRequestProvider.notifier).request();
  }

  GameEventNotificationFocusTarget? _focusTargetFor(
    GameEventNotification notification,
  ) {
    final currentState = _currentState();
    final state = currentState ?? notification.state;
    return gameEventNotificationFocusTarget(
      notification.event,
      state,
      viewerPlayerId: notification.playerId,
    );
  }

  GameState? _currentState() {
    final saveId = widget.gameSave?.id;
    if (saveId == null || saveId.isEmpty) return null;
    return ref.read(gameStateProvider(saveId)).value;
  }
}

Duration _holdDurationFor(GameEventNotification notification) {
  if (_isCriticalNotification(notification)) {
    return _criticalNotificationHoldDuration;
  }
  return _minorNotificationHoldDuration;
}

bool _isCriticalNotification(GameEventNotification notification) {
  final unitLookupState = notification.previousState ?? notification.state;
  return switch (notification.event) {
    CityCapturedEvent() ||
    CityDestroyedEvent() ||
    TechnologyResearchedEvent() ||
    CivilizationMetEvent() ||
    DominationThresholdReachedEvent() ||
    UnitKilledEvent() => true,
    CombatResolvedEvent(:final outcome) =>
      (outcome.attackerKilled &&
              _unitBelongsTo(
                unitLookupState,
                outcome.attackerUnitId,
                notification.playerId,
              )) ||
          (outcome.defenderKilled &&
              _unitBelongsTo(
                unitLookupState,
                outcome.defenderUnitId,
                notification.playerId,
              )),
    _ => false,
  };
}

bool _unitBelongsTo(GameState state, String unitId, String playerId) {
  for (final unit in state.units) {
    if (unit.id == unitId) return unit.ownerPlayerId == playerId;
  }
  return false;
}

class _NotificationOverflowPill extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationOverflowPill({
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: DecoratedBox(
              decoration: SurfaceElevation.floating.decoration(
                background: GameUiTheme.surface,
                backgroundAlpha: 212,
                border: BorderEmphasis.regular,
                shape: SurfaceShape.pill,
                includeShadow: false,
                boxShadow: [
                  BoxShadow(
                    color: SurfaceElevation.flat.fill(
                      background: Colors.black,
                      alpha: 86,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Text(
                  '+$count more ↓',
                  style: GameUiTheme.chipLabel.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
