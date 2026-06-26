import 'dart:async';
import 'dart:collection';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/providers/hud/technology_discovery_popup_settings_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'technology_discovery_popup_dialog.dart';
part 'technology_discovery_popup_helpers.dart';

enum _TechnologyDiscoveryDialogResult { dismissed, disablePopup, minimize }

class TechnologyDiscoveryPopupOverlay extends ConsumerStatefulWidget {
  final GameSave? gameSave;

  const TechnologyDiscoveryPopupOverlay({this.gameSave, super.key});

  @override
  ConsumerState<TechnologyDiscoveryPopupOverlay> createState() =>
      _TechnologyDiscoveryPopupOverlayState();
}

class _TechnologyDiscoveryPopupOverlayState
    extends ConsumerState<TechnologyDiscoveryPopupOverlay> {
  final Queue<GameEventNotification> _pending = Queue();
  final Set<int> _seenNotificationIds = {};
  bool _dialogOpen = false;
  bool _handoffBlocked = false;
  bool _showScheduled = false;

  @override
  Widget build(BuildContext context) {
    final activePlayerId = _watchActivePopupPlayerId();
    final settings = ref.watch(
      technologyDiscoveryPopupSettingsProvider(_settingsKeyFor(activePlayerId)),
    );
    final minimizedState = ref.watch(hudMinimizedPopupsProvider);
    _handoffBlocked = ref.watch(gameHandoffProvider) != null;
    _listenForTechnologyNotifications();
    _listenForRestoreRequests();
    if (!settings.loaded || !minimizedState.loaded || _handoffBlocked) {
      return const SizedBox.shrink();
    }
    if (settings.showPopup) _scheduleShowNext();
    return const SizedBox.shrink();
  }

  void _listenForTechnologyNotifications() {
    ref.listen<List<GameEventNotification>>(gameEventNotificationsProvider, (
      _,
      next,
    ) {
      if (next.isEmpty) {
        _seenNotificationIds.clear();
        _pending.clear();
        return;
      }
      for (final notification in next) {
        if (!_seenNotificationIds.add(notification.id)) continue;
        final event = notification.event;
        if (event is! TechnologyResearchedEvent) continue;
        if (_isDiscoveryMinimized(event)) continue;
        _pending.add(notification);
      }
      _scheduleShowNext();
    });
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
      if (entry == null ||
          entry.kind != HudMinimizedPopupKind.technologyDiscovery ||
          !entry.belongsToSave(_saveId)) {
        return;
      }
      unawaited(_restoreDiscovery(entry));
    });
  }

  void _scheduleShowNext() {
    if (_showScheduled ||
        _dialogOpen ||
        _handoffBlocked ||
        ref.read(gameHandoffProvider) != null ||
        _pending.isEmpty) {
      return;
    }
    _showScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showScheduled = false;
      unawaited(_showNext());
    });
  }

  Future<void> _showNext() async {
    if (!mounted || _dialogOpen || _pending.isEmpty) return;
    if (ref.read(gameHandoffProvider) != null) return;
    final activePlayerId = _readActivePopupPlayerId();
    if (activePlayerId.isEmpty) return;
    final settings = ref.read(
      technologyDiscoveryPopupSettingsProvider(_settingsKeyFor(activePlayerId)),
    );
    if (!ref.read(hudMinimizedPopupsProvider).loaded) return;
    if (!settings.loaded) return;

    final pendingCount = _pending.length;
    for (var i = 0; i < pendingCount; i++) {
      final notification = _pending.removeFirst();
      if (!notification.isVisibleTo(activePlayerId)) {
        _pending.add(notification);
        continue;
      }
      final event = notification.event;
      if (event is! TechnologyResearchedEvent) continue;
      if (_isDiscoveryMinimized(event)) {
        continue;
      }
      if (!settings.showPopup) continue;
      await _showTechnologyNotification(notification);
      return;
    }
  }

  Future<void> _showTechnologyNotification(
    GameEventNotification notification,
  ) async {
    final event = notification.event;
    if (event is! TechnologyResearchedEvent) {
      _scheduleShowNext();
      return;
    }
    await _showTechnologyEvent(event);
  }

  void _minimizeDiscovery({
    required AppLocalizations l10n,
    required TechnologyResearchedEvent event,
    required String technologyName,
    required String playerName,
  }) {
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(
          HudMinimizedPopupEntry(
            id: _popupIdFor(event),
            kind: HudMinimizedPopupKind.technologyDiscovery,
            title: l10n.technologyDiscoveryEyebrow,
            subtitle: '$technologyName - $playerName',
            payload: {
              'playerId': event.playerId,
              'technologyId': event.technologyId.name,
            },
          ),
        );
  }

  bool _isDiscoveryMinimized(TechnologyResearchedEvent event) {
    return ref.read(hudMinimizedPopupsProvider).hasEntry(_popupIdFor(event));
  }

  Future<void> _restoreDiscovery(HudMinimizedPopupEntry entry) async {
    if (!mounted || _dialogOpen) return;
    final playerId = entry.payload['playerId'];
    final technologyId = _technologyIdFromName(entry.payload['technologyId']);
    if (playerId == null || technologyId == null) return;
    final activePlayerId = _readActivePopupPlayerId();
    if (activePlayerId.isNotEmpty && activePlayerId != playerId) return;
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .removeWhere((candidate) => candidate.id == entry.id);
    await _showTechnologyEvent(
      TechnologyResearchedEvent(playerId: playerId, technologyId: technologyId),
    );
  }

  Future<void> _showTechnologyEvent(TechnologyResearchedEvent event) async {
    final l10n = AppLocalizations.of(context);
    final playerName = _playerName(l10n, widget.gameSave, event.playerId);
    final technologyName = GameDisplayNames.technology(
      l10n,
      event.technologyId,
    );

    _dialogOpen = true;
    final result = await showGameModal<_TechnologyDiscoveryDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _TechnologyDiscoveryDialog(
        technologyId: event.technologyId,
        playerName: playerName,
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;

    if (result == _TechnologyDiscoveryDialogResult.disablePopup) {
      ref
          .read(
            technologyDiscoveryPopupSettingsProvider(
              _settingsKeyFor(event.playerId),
            ).notifier,
          )
          .setShowPopup(false);
      _pending.removeWhere(
        (notification) => notification.playerId == event.playerId,
      );
      return;
    }
    if (result == _TechnologyDiscoveryDialogResult.minimize) {
      _minimizeDiscovery(
        l10n: l10n,
        event: event,
        technologyName: technologyName,
        playerName: playerName,
      );
    }
    _scheduleShowNext();
  }

  String _popupIdFor(TechnologyResearchedEvent event) {
    return HudMinimizedPopupIds.technologyDiscovery(
      _saveId,
      '${event.playerId}.${event.technologyId.name}',
    );
  }

  String _settingsKeyFor(String playerId) {
    return TechnologyDiscoveryPopupSettingsKey.forSavePlayer(
      _saveId,
      playerId.isEmpty ? 'unknown' : playerId,
    );
  }

  String _watchActivePopupPlayerId() {
    final activePlayerId = ref.watch(
      gamePlayerControlControllerProvider.select(
        (control) => control.activePlayerId,
      ),
    );
    if (activePlayerId.isNotEmpty) return activePlayerId;
    for (final notification in ref.watch(gameEventNotificationsProvider)) {
      if (notification.playerId.isNotEmpty) return notification.playerId;
    }
    return '';
  }

  String _readActivePopupPlayerId() {
    final activePlayerId = ref
        .read(gamePlayerControlControllerProvider)
        .activePlayerId;
    if (activePlayerId.isNotEmpty) return activePlayerId;
    for (final notification in ref.read(gameEventNotificationsProvider)) {
      if (notification.playerId.isNotEmpty) return notification.playerId;
    }
    return '';
  }

  String get _saveId => widget.gameSave?.id ?? 'transient';
}
