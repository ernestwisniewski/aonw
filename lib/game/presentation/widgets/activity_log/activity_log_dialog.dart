import 'dart:math' as math;

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/game/game_activity_history_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/notifications/game_event_notification_thumbnail.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_empty_state.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'activity_log_entries.dart';
part 'activity_log_filter.dart';
part 'turn_timeline_popup.dart';

const _activityLogPageSize = 80;

class ActivityLogDialog extends StatelessWidget {
  const ActivityLogDialog({
    required this.entries,
    required this.gameSave,
    this.currentState,
    this.activePlayerId,
    this.onEntrySelected,
    super.key,
  });

  final List<GameEventNotification> entries;
  final GameSave gameSave;
  final GameState? currentState;
  final String? activePlayerId;
  final ValueChanged<GameEventNotification>? onEntrySelected;

  @override
  Widget build(BuildContext context) {
    return ActivityLogPanel(
      entries: entries,
      gameSave: gameSave,
      currentState: currentState,
      activePlayerId: activePlayerId,
      onEntrySelected: onEntrySelected,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

class ActivityLogPanel extends ConsumerStatefulWidget {
  const ActivityLogPanel({
    required this.entries,
    required this.gameSave,
    this.currentState,
    this.activePlayerId,
    this.maxHeight,
    this.onEntrySelected,
    required this.onClose,
    super.key,
  });

  final List<GameEventNotification> entries;
  final GameSave gameSave;
  final GameState? currentState;
  final String? activePlayerId;
  final double? maxHeight;
  final ValueChanged<GameEventNotification>? onEntrySelected;
  final VoidCallback onClose;

  @override
  ConsumerState<ActivityLogPanel> createState() => _ActivityLogPanelState();
}

class _ActivityLogPanelState extends ConsumerState<ActivityLogPanel> {
  ActivityLogFilter _filter = ActivityLogFilter.all;
  int _visibleCount = _activityLogPageSize;

  @override
  void didUpdateWidget(covariant ActivityLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameSave.id != widget.gameSave.id ||
        oldWidget.activePlayerId != widget.activePlayerId) {
      _visibleCount = _activityLogPageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 480;
    final source = _resolveEntries();
    final visibleEntries = [
      for (final entry in source.entries.reversed)
        if (_filter.matches(entry.event)) entry,
    ];
    final pageEntries = visibleEntries
        .take(_visibleCount)
        .toList(growable: false);
    final hasMore = visibleEntries.length > pageEntries.length;
    final panelPadding = compact
        ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
        : const EdgeInsets.fromLTRB(14, 12, 14, 14);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: widget.maxHeight ?? 620,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('activityLogPanel.surface'),
        showCornerDiamonds: false,
        contentPadding: panelPadding,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GameUiEpicHeader(
                    label: GameText.uppercase(l10n.activityLogTitle),
                    alignment: Alignment.centerLeft,
                    compact: compact,
                    textKey: const Key('activityLogPanel.title'),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.closeAction,
                  onPressed: widget.onClose,
                  icon: const GameIcon(
                    GameIcons.close,
                    size: GameIconSize.small,
                    color: GameUiTheme.gold,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            _ActivityLogFilterBar(
              selected: _filter,
              compact: compact,
              onChanged: _setFilter,
            ),
            if (source.entries.isNotEmpty) ...[
              SizedBox(height: compact ? 6 : 8),
              _ActivityLogDistributionBar(
                entries: source.entries,
                compact: compact,
              ),
            ],
            SizedBox(height: compact ? 8 : 10),
            Flexible(
              child: source.error != null
                  ? SingleChildScrollView(
                      child: _ActivityLogHistoryErrorState(
                        error: source.error!,
                        compact: compact,
                        onRetry: () => ref.invalidate(
                          gameActivityHistoryProvider(widget.gameSave.id),
                        ),
                      ),
                    )
                  : source.loading && source.entries.isEmpty
                  ? SingleChildScrollView(
                      child: _ActivityLogHistoryLoadingState(compact: compact),
                    )
                  : visibleEntries.isEmpty
                  ? SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: compact ? 4 : 8,
                        ),
                        child: _ActivityLogEmptyState(
                          filter: _filter,
                          compact: compact,
                          onShowAll: _filter == ActivityLogFilter.all
                              ? null
                              : () => _setFilter(ActivityLogFilter.all),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: pageEntries.length + (hasMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          SizedBox(height: compact ? 6 : 8),
                      itemBuilder: (context, index) {
                        if (index >= pageEntries.length) {
                          return _ActivityLogShowMoreButton(
                            compact: compact,
                            visible: pageEntries.length,
                            total: visibleEntries.length,
                            onPressed: _showMore,
                          );
                        }
                        final entry = pageEntries[index];
                        final message = GameEventNotificationMessage.from(
                          l10n,
                          entry,
                          widget.gameSave,
                        );
                        return _ActivityLogEntryTile(
                          message: message,
                          compact: compact,
                          onTap: widget.onEntrySelected == null
                              ? null
                              : () => widget.onEntrySelected!(entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _setFilter(ActivityLogFilter filter) {
    setState(() {
      _filter = filter;
      _visibleCount = _activityLogPageSize;
    });
  }

  void _showMore() {
    setState(() => _visibleCount += _activityLogPageSize);
  }

  _ActivityLogResolvedEntries _resolveEntries() {
    final currentState = widget.currentState;
    final activePlayerId =
        widget.activePlayerId ?? currentState?.activePlayerId ?? '';
    if (currentState == null ||
        activePlayerId.isEmpty ||
        widget.gameSave.id.isEmpty) {
      return _ActivityLogResolvedEntries(entries: widget.entries);
    }

    final history = ref.watch(gameActivityHistoryProvider(widget.gameSave.id));
    return history.when(
      data: (records) {
        final entries = [
          for (final record in records)
            if (record.isVisibleTo(activePlayerId))
              record.toNotification(currentState),
        ];
        return _ActivityLogResolvedEntries(
          entries: entries.isEmpty && widget.entries.isNotEmpty
              ? widget.entries
              : entries,
        );
      },
      loading: () =>
          _ActivityLogResolvedEntries(entries: widget.entries, loading: true),
      error: (error, _) => _ActivityLogResolvedEntries(error: error),
    );
  }
}

class _ActivityLogResolvedEntries {
  const _ActivityLogResolvedEntries({
    this.entries = const [],
    this.loading = false,
    this.error,
  });

  final List<GameEventNotification> entries;
  final bool loading;
  final Object? error;
}
