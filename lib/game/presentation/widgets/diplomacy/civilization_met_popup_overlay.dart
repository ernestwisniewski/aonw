import 'dart:async';
import 'dart:collection';

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
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
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _handoffBlocked = ref.watch(gameHandoffProvider) != null;
    _listenForCivilizationNotifications();
    if (settings.loaded && settings.showPopup && !_handoffBlocked) {
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
        if (notification.event is CivilizationMetEvent) {
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
      civilizationMetPopupSettingsProvider(_settingsKeyFor(activePlayerId)),
    );
    if (!settings.loaded) return;

    final pendingCount = _pending.length;
    for (var i = 0; i < pendingCount; i++) {
      final notification = _pending.removeFirst();
      if (!notification.isVisibleTo(activePlayerId)) {
        _pending.add(notification);
        continue;
      }
      final event = notification.event;
      if (event is! CivilizationMetEvent) continue;
      if (!settings.showPopup) continue;
      await _showCivilizationMet(notification, event);
      return;
    }
  }

  Future<void> _showCivilizationMet(
    GameEventNotification notification,
    CivilizationMetEvent event,
  ) async {
    final l10n = AppLocalizations.of(context);
    final model = _CivilizationMetPopupModel.from(
      l10n: l10n,
      save: widget.gameSave,
      state: notification.state,
      playerId: event.metPlayerId,
    );

    _dialogOpen = true;
    final result = await showGameModal<_CivilizationMetDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CivilizationMetDialog(model: model),
    );
    if (!mounted) return;
    _dialogOpen = false;

    if (result == _CivilizationMetDialogResult.disablePopup) {
      ref
          .read(
            civilizationMetPopupSettingsProvider(
              _settingsKeyFor(event.playerId),
            ).notifier,
          )
          .setShowPopup(false);
      _pending.removeWhere(
        (notification) => notification.playerId == event.playerId,
      );
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
    required GameState state,
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

class _CivilizationMetDialog extends StatefulWidget {
  final _CivilizationMetPopupModel model;

  const _CivilizationMetDialog({required this.model});

  @override
  State<_CivilizationMetDialog> createState() => _CivilizationMetDialogState();
}

class _CivilizationMetDialogState extends State<_CivilizationMetDialog> {
  bool _doNotShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GameModalScaffold(
      surfaceKey: const Key('civilizationMetDialog.surface'),
      size: GameModalSize.regular,
      contentPadding: EdgeInsets.zero,
      scrollable: false,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CivilizationMetHeader(model: widget.model),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                l10n.civilizationMetPopupBody(widget.model.civilizationName),
                style: GameUiTheme.body.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            _CivilizationMetFooter(
              doNotShowAgain: _doNotShowAgain,
              onToggleDoNotShowAgain: (value) =>
                  setState(() => _doNotShowAgain = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _CivilizationMetHeader extends StatelessWidget {
  final _CivilizationMetPopupModel model;

  const _CivilizationMetHeader({required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CivilizationMetThumbnail(color: model.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.civilizationMetPopupEyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.gold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5),
                GameUiEpicHeader(
                  label: model.civilizationName,
                  alignment: Alignment.centerLeft,
                  accent: model.color,
                  compact: false,
                  textKey: const Key('civilizationMetDialog.title'),
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.leaderName} - ${model.playerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.cardMeta.copyWith(
                    color: GameUiTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _CivilizationMetFooter extends StatelessWidget {
  final bool doNotShowAgain;
  final ValueChanged<bool> onToggleDoNotShowAgain;

  const _CivilizationMetFooter({
    required this.doNotShowAgain,
    required this.onToggleDoNotShowAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 170,
        borderColor: GameUiTheme.copper,
        border: BorderEmphasis.regular,
        topBorder: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            InkWell(
              borderRadius: GameUiTheme.borderRadius,
              onTap: () => onToggleDoNotShowAgain(!doNotShowAgain),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      key: const Key(
                        'civilizationMetDialog.doNotShowAgain.checkbox',
                      ),
                      value: doNotShowAgain,
                      onChanged: (value) =>
                          onToggleDoNotShowAgain(value ?? false),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      l10n.commonDoNotShowAgain,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                doNotShowAgain
                    ? _CivilizationMetDialogResult.disablePopup
                    : _CivilizationMetDialogResult.dismissed,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: GameUiTheme.gold,
                foregroundColor: GameUiTheme.bg,
                textStyle: GameUiTheme.actionLabel,
                shape: RoundedRectangleBorder(
                  borderRadius: GameUiTheme.borderRadius,
                ),
              ),
              child: Text(l10n.civilizationMetPopupOk),
            ),
          ],
        ),
      ),
    );
  }
}
