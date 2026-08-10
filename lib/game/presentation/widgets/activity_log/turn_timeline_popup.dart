part of 'activity_log_dialog.dart';

class TurnTimelinePopup extends ConsumerStatefulWidget {
  const TurnTimelinePopup({
    required this.entries,
    required this.gameSave,
    required this.currentTurn,
    this.currentState,
    this.activePlayerId,
    this.onEntrySelected,
    this.gamepadInputListenable,
    required this.onClose,
    super.key,
  });

  final List<GameEventNotification> entries;
  final GameSave gameSave;
  final int currentTurn;
  final GameClientState? currentState;
  final String? activePlayerId;
  final ValueChanged<GameEventNotification>? onEntrySelected;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;
  final VoidCallback onClose;

  @override
  ConsumerState<TurnTimelinePopup> createState() => _TurnTimelinePopupState();
}

typedef _TurnTimelineEntries = ({
  _ActivityLogResolvedEntries source,
  List<GameEventNotification> visible,
  List<GameEventNotification> page,
  List<GameEventNotification> chart,
  bool hasMore,
});

class _TurnTimelinePopupState extends ConsumerState<TurnTimelinePopup> {
  ActivityLogFilter _filter = ActivityLogFilter.all;
  int _visibleCount = _activityLogPageSize;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TurnTimelinePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameSave.id != widget.gameSave.id ||
        oldWidget.activePlayerId != widget.activePlayerId) {
      _visibleCount = _activityLogPageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 540;
    final entries = _visibleEntries();
    return GamepadPanelInputListener(
      input: widget.gamepadInputListenable,
      onNavigate: _scrollHistory,
      onCancel: widget.onClose,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 660),
        child: GameModalScaffold(
          surfaceKey: const Key('turnTimelinePopup.surface'),
          size: GameModalSize.wide,
          showCornerDiamonds: false,
          contentPadding: compact
              ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
              : const EdgeInsets.fromLTRB(16, 12, 16, 16),
          centerInAvailableSpace: false,
          scrollable: false,
          content: _content(AppLocalizations.of(context), entries, compact),
        ),
      ),
    );
  }

  Widget _content(
    AppLocalizations l10n,
    _TurnTimelineEntries entries,
    bool compact,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(l10n, entries.source.entries.length, compact),
        SizedBox(height: compact ? 8 : 10),
        _ActivityLogFilterBar(
          selected: _filter,
          compact: compact,
          onChanged: _setFilter,
        ),
        SizedBox(height: compact ? 8 : 10),
        TurnTimelineChart(
          entries: entries.chart,
          filter: _filter,
          currentTurn: widget.currentTurn,
          compact: compact,
        ),
        SizedBox(height: compact ? 8 : 10),
        Flexible(child: _history(l10n, entries, compact)),
      ],
    );
  }

  Widget _header(AppLocalizations l10n, int entryCount, bool compact) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GameUiEpicHeader(
                label: GameText.uppercase(l10n.turnTimelineTitle),
                alignment: Alignment.centerLeft,
                compact: compact,
                textKey: const Key('turnTimelinePopup.title'),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.turnTimelineSubtitle(widget.currentTurn, entryCount),
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textSecondary,
                  fontFeatures: GameUiTheme.tabularFigures,
                ),
              ),
            ],
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
    );
  }

  Widget _history(
    AppLocalizations l10n,
    _TurnTimelineEntries entries,
    bool compact,
  ) {
    final source = entries.source;
    if (source.error != null) {
      return _scrollable(
        _ActivityLogHistoryErrorState(
          error: source.error!,
          compact: compact,
          onRetry: () =>
              ref.invalidate(gameActivityHistoryProvider(widget.gameSave.id)),
        ),
      );
    }
    if (source.loading && source.entries.isEmpty) {
      return _scrollable(_ActivityLogHistoryLoadingState(compact: compact));
    }
    if (entries.visible.isEmpty) return _emptyHistory(compact);
    return _entryList(l10n, entries, compact);
  }

  Widget _emptyHistory(bool compact) {
    return _scrollable(
      Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
        child: _ActivityLogEmptyState(
          filter: _filter,
          compact: compact,
          onShowAll: _filter == ActivityLogFilter.all
              ? null
              : () => _setFilter(ActivityLogFilter.all),
        ),
      ),
    );
  }

  Widget _entryList(
    AppLocalizations l10n,
    _TurnTimelineEntries entries,
    bool compact,
  ) {
    return ListView.separated(
      controller: _historyScrollController,
      itemCount: entries.page.length + (entries.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => SizedBox(height: compact ? 6 : 8),
      itemBuilder: (context, index) {
        if (index >= entries.page.length) {
          return _ActivityLogShowMoreButton(
            compact: compact,
            visible: entries.page.length,
            total: entries.visible.length,
            onPressed: _showMore,
          );
        }
        final entry = entries.page[index];
        return _ActivityLogEntryTile(
          message: GameEventNotificationMessage.from(
            l10n,
            entry,
            widget.gameSave,
          ),
          compact: compact,
          onTap: widget.onEntrySelected == null
              ? null
              : () => widget.onEntrySelected!(entry),
        );
      },
    );
  }

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      controller: _historyScrollController,
      child: child,
    );
  }

  _TurnTimelineEntries _visibleEntries() {
    final source = _resolveEntries();
    final visible = [
      for (final entry in source.entries.reversed)
        if (_filter.matches(entry.event)) entry,
    ];
    final page = visible.take(_visibleCount).toList(growable: false);
    return (
      source: source,
      visible: visible,
      page: page,
      chart: [
        for (final entry in source.entries)
          if (_filter.matches(entry.event)) entry,
      ],
      hasMore: visible.length > page.length,
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
