import 'dart:async';
import 'dart:collection';

import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/hud/civilization_met_popup_settings_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw/game/presentation/providers/player/player_control_provider.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'civilization_met_dialog.dart';

enum _CivilizationMetDialogResult { dismissed, disablePopup }

class CivilizationMetPopupOverlay extends ConsumerStatefulWidget {
  final GameSave? gameSave;

  const CivilizationMetPopupOverlay({this.gameSave, super.key});

  @override
  ConsumerState<CivilizationMetPopupOverlay> createState() =>
      _CivilizationMetPopupOverlayState();
}

class _CivilizationMetPopupOverlayState
    extends ConsumerState<CivilizationMetPopupOverlay> {
  final Queue<GameEventNotification> _pending = Queue();
  final Set<int> _seenNotificationIds = {};
  bool _dialogOpen = false;
  bool _handoffBlocked = false;
  bool _showScheduled = false;

  @override
  Widget build(BuildContext context) {
    final activePlayerId = _watchActivePopupPlayerId();
    final settings = ref.watch(
      civilizationMetPopupSettingsProvider(_settingsKeyFor(activePlayerId)),
    );
    final popupPresentationBlocked = ref.watch(
      gamePlayerControlControllerProvider.select(
        (control) => control.phase.blocksHumanInput,
      ),
    );
    _handoffBlocked = ref.watch(gameHandoffProvider) != null;
    _listenForCivilizationNotifications();
    if (settings.loaded &&
        settings.showPopup &&
        !_handoffBlocked &&
        !popupPresentationBlocked) {
      _scheduleShowNext();
    }
    return const SizedBox.shrink();
  }

  void _listenForCivilizationNotifications() {
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
        final descriptor = GameEventDescriptor.forEvent(notification.event);
        if (descriptor.civilizationMetPlayerId != null) {
          _pending.add(notification);
        }
      }
      _scheduleShowNext();
    });
  }

  void _scheduleShowNext() {
    if (_showScheduled ||
        _dialogOpen ||
        _handoffBlocked ||
        _popupPresentationBlocked ||
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
    final popupContext = _nextPopupContext();
    if (popupContext == null) return;
    final activePlayerId = popupContext.activePlayerId;
    final pendingCount = _pending.length;
    for (var i = 0; i < pendingCount; i++) {
      final notification = _pending.removeFirst();
      if (!notification.isVisibleTo(activePlayerId)) {
        _pending.add(notification);
        continue;
      }
      final descriptor = GameEventDescriptor.forEvent(notification.event);
      if (descriptor.civilizationMetPlayerId == null) continue;
      if (!popupContext.showPopup) continue;
      await _showCivilizationMet(notification, descriptor);
      return;
    }
  }

  ({String activePlayerId, bool showPopup})? _nextPopupContext() {
    if (!mounted ||
        _dialogOpen ||
        _pending.isEmpty ||
        _popupPresentationBlocked ||
        ref.read(gameHandoffProvider) != null) {
      return null;
    }
    final activePlayerId = _readActivePopupPlayerId();
    if (activePlayerId.isEmpty) return null;
    final settings = ref.read(
      civilizationMetPopupSettingsProvider(_settingsKeyFor(activePlayerId)),
    );
    if (!settings.loaded) return null;
    return (activePlayerId: activePlayerId, showPopup: settings.showPopup);
  }

  Future<void> _showCivilizationMet(
    GameEventNotification notification,
    GameEventDescriptor descriptor,
  ) async {
    final l10n = AppLocalizations.of(context);
    final playerId = descriptor.civilizationPlayerId!;
    final model = _CivilizationMetPopupModel.from(
      l10n: l10n,
      save: widget.gameSave,
      state: notification.state,
      playerId: descriptor.civilizationMetPlayerId!,
    );
    final gamepadRouter = GamepadInputRouterScope.maybeOf(context);
    _dialogOpen = true;
    final result = await showGameModal<_CivilizationMetDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          _CivilizationMetDialog(model: model, gamepadRouter: gamepadRouter),
    );
    if (!mounted) return;
    _dialogOpen = false;

    if (result == _CivilizationMetDialogResult.disablePopup) {
      ref
          .read(
            civilizationMetPopupSettingsProvider(
              _settingsKeyFor(playerId),
            ).notifier,
          )
          .setShowPopup(false);
      _pending.removeWhere((notification) => notification.playerId == playerId);
      return;
    }
    _scheduleShowNext();
  }

  String _settingsKeyFor(String playerId) {
    return CivilizationMetPopupSettingsKey.forSavePlayer(
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

  bool get _popupPresentationBlocked =>
      ref.read(gamePlayerControlControllerProvider).phase.blocksHumanInput;

  String get _saveId => widget.gameSave?.id ?? 'transient';
}

class _CivilizationMetPopupModel {
  final String civilizationName;
  final String playerName;
  final String leaderName;
  final Color color;

  const _CivilizationMetPopupModel({
    required this.civilizationName,
    required this.playerName,
    required this.leaderName,
    required this.color,
  });

  factory _CivilizationMetPopupModel.from({
    required AppLocalizations l10n,
    required GameSave? save,
    required GameClientState state,
    required String playerId,
  }) {
    final player = save?.playerById(playerId);
    final country = player?.country ?? state.countryForPlayer(playerId);
    return _CivilizationMetPopupModel(
      civilizationName: GameDisplayNames.playerCountry(l10n, country),
      playerName: player == null
          ? playerId
          : GameDisplayNames.player(l10n, player),
      leaderName: GameDisplayNames.playerCountryLeader(l10n, country),
      color: Color(
        player?.colorValue ??
            state.colorForPlayer(playerId) ??
            Player.palette.first,
      ),
    );
  }
}

class _CivilizationMetThumbnail extends StatelessWidget {
  final Color color;

  const _CivilizationMetThumbnail({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 185,
        accent: color,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(8),
        includeShadow: false,
      ),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withAlpha(52),
                  shape: BoxShape.circle,
                ),
              ),
              GameIcon(GameIcons.flag, size: 46, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
