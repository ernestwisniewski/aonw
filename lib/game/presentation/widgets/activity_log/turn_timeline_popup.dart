part of 'activity_log_dialog.dart';

Future<void> showTurnTimelinePopup(
  BuildContext context, {
  required List<GameEventNotification> entries,
  required GameSave gameSave,
  GameState? currentState,
  String? activePlayerId,
  ValueChanged<GameEventNotification>? onEntrySelected,
}) {
  return showGameModal<void>(
    context: context,
    size: GameModalSize.wide,
    builder: (dialogContext) => TurnTimelinePopup(
      entries: entries,
      gameSave: gameSave,
      currentTurn: gameSave.turn,
      currentState: currentState,
      activePlayerId: activePlayerId,
      onEntrySelected: onEntrySelected,
      onClose: () => Navigator.of(dialogContext).maybePop(),
    ),
  );
}

class TurnTimelinePopup extends ConsumerStatefulWidget {
  const TurnTimelinePopup({
    required this.entries,
    required this.gameSave,
    required this.currentTurn,
    this.currentState,
    this.activePlayerId,
    this.onEntrySelected,
    required this.onClose,
    super.key,
  });

  final List<GameEventNotification> entries;
  final GameSave gameSave;
  final int currentTurn;
  final GameState? currentState;
  final String? activePlayerId;
  final ValueChanged<GameEventNotification>? onEntrySelected;
  final VoidCallback onClose;

  @override
  ConsumerState<TurnTimelinePopup> createState() => _TurnTimelinePopupState();
}

class _TurnTimelinePopupState extends ConsumerState<TurnTimelinePopup> {
  ActivityLogFilter _filter = ActivityLogFilter.all;
  int _visibleCount = _activityLogPageSize;

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
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 540;
    final source = _resolveEntries();
    final visibleEntries = [
      for (final entry in source.entries.reversed)
        if (_filter.matches(entry.event)) entry,
    ];
    final pageEntries = visibleEntries
        .take(_visibleCount)
        .toList(growable: false);
    final hasMore = visibleEntries.length > pageEntries.length;
    final chartEntries = [
      for (final entry in source.entries)
        if (_filter.matches(entry.event)) entry,
    ];
    final padding = compact
        ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
        : const EdgeInsets.fromLTRB(16, 12, 16, 16);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 660),
      child: GameModalScaffold(
        surfaceKey: const Key('turnTimelinePopup.surface'),
        size: GameModalSize.wide,
        showCornerDiamonds: false,
        contentPadding: padding,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        l10n.turnTimelineSubtitle(
                          widget.currentTurn,
                          source.entries.length,
                        ),
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
            ),
            SizedBox(height: compact ? 8 : 10),
            _ActivityLogFilterBar(
              selected: _filter,
              compact: compact,
              onChanged: _setFilter,
            ),
            SizedBox(height: compact ? 8 : 10),
            _TurnTimelineChart(
              entries: chartEntries,
              filter: _filter,
              currentTurn: widget.currentTurn,
              compact: compact,
            ),
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

class _TurnTimelineChart extends StatelessWidget {
  const _TurnTimelineChart({
    required this.entries,
    required this.filter,
    required this.currentTurn,
    required this.compact,
  });

  final List<GameEventNotification> entries;
  final ActivityLogFilter filter;
  final int currentTurn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _TurnTimelineChartData.from(
      entries: entries,
      filter: filter,
      currentTurn: currentTurn,
    );

    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.card,
        backgroundAlpha: 210,
        border: BorderEmphasis.subtle,
        borderRadius: GameUiTheme.borderRadius,
        includeShadow: false,
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(10, 9, 10, 10)
            : const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.turnTimelineChartTitle,
                    style: GameUiTheme.sectionHeader.copyWith(
                      color: GameUiTheme.goldLight,
                    ),
                  ),
                ),
                _TimelineMetricPill(
                  label: l10n.turnTimelineMetricEvents,
                  value: '${data.total}',
                  compact: compact,
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            SizedBox(
              height: compact ? 104 : 126,
              child: CustomPaint(
                painter: _TurnTimelineChartPainter(data: data, filter: filter),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < data.ticks.length; i++) ...[
                  if (i > 0) const Spacer(),
                  Text(
                    l10n.topResourceTurnShortLabel(data.ticks[i]),
                    key: Key('turnTimelinePopup.turn.${data.ticks[i]}'),
                    style: GameUiTheme.chipLabel.copyWith(
                      color: GameUiTheme.textTertiary,
                      fontFeatures: GameUiTheme.tabularFigures,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TimelineMetricPill(
                  label: l10n.turnTimelineMetricActiveTurns,
                  value: '${data.activeTurns}',
                  compact: compact,
                ),
                _TimelineMetricPill(
                  label: l10n.turnTimelineMetricCurrentTurn,
                  value: l10n.topResourceTurnShortLabel(currentTurn),
                  compact: compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineMetricPill extends StatelessWidget {
  const _TimelineMetricPill({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 210,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.chip,
        includeShadow: false,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 8,
          vertical: compact ? 4 : 5,
        ),
        child: RichText(
          text: TextSpan(
            style: GameUiTheme.chipLabel.copyWith(
              color: GameUiTheme.textSecondary,
              fontSize: compact ? 10 : null,
            ),
            children: [
              TextSpan(text: '$label '),
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: GameUiTheme.goldLight,
                  fontFeatures: GameUiTheme.tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnTimelineChartPainter extends CustomPainter {
  const _TurnTimelineChartPainter({required this.data, required this.filter});

  final _TurnTimelineChartData data;
  final ActivityLogFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = GameUiTheme.textTertiary.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    final guidePaint = Paint()
      ..color = GameUiTheme.textTertiary.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final plot = Rect.fromLTWH(0, 4, size.width, size.height - 8);

    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      axisPaint,
    );
    for (var i = 1; i <= 3; i++) {
      final y = plot.bottom - plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), guidePaint);
    }

    if (data.buckets.isEmpty || data.maxBucketTotal == 0) return;

    final range = math.max(1, data.maxTurn - data.minTurn);
    final slotWidth = data.buckets.length <= 1
        ? plot.width
        : plot.width / (range + 1);
    final barWidth = slotWidth.clamp(7.0, 18.0).toDouble();
    for (final bucket in data.buckets) {
      final x = data.minTurn == data.maxTurn
          ? plot.center.dx
          : plot.left +
                plot.width *
                    (bucket.turn - data.minTurn) /
                    (data.maxTurn - data.minTurn);
      var bottom = plot.bottom;
      for (final segment in bucket.segmentsFor(filter)) {
        if (segment.count <= 0) continue;
        final height = plot.height * segment.count / data.maxBucketTotal;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - barWidth / 2,
            bottom - height,
            x + barWidth / 2,
            bottom,
          ),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = segment.color.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill,
        );
        bottom -= height;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TurnTimelineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.filter != filter;
  }
}

class _TurnTimelineChartData {
  const _TurnTimelineChartData({
    required this.buckets,
    required this.ticks,
    required this.minTurn,
    required this.maxTurn,
    required this.maxBucketTotal,
    required this.total,
  });

  final List<_TurnTimelineBucket> buckets;
  final List<int> ticks;
  final int minTurn;
  final int maxTurn;
  final int maxBucketTotal;
  final int total;

  int get activeTurns => buckets.length;

  static _TurnTimelineChartData from({
    required List<GameEventNotification> entries,
    required ActivityLogFilter filter,
    required int currentTurn,
  }) {
    final byTurn = <int, _MutableTurnTimelineBucket>{};
    for (final entry in entries) {
      final turn = _notificationTurn(entry, currentTurn);
      byTurn
          .putIfAbsent(turn, () => _MutableTurnTimelineBucket(turn))
          .add(_activityCategoryFor(entry.event));
    }

    final buckets = [for (final bucket in byTurn.values) bucket.freeze()]
      ..sort((a, b) => a.turn.compareTo(b.turn));

    final turns = <int>[for (final bucket in buckets) bucket.turn, currentTurn];
    final minTurn = turns.reduce(math.min);
    final maxTurn = turns.reduce(math.max);
    final ticks = _timelineTurnTicks(minTurn, maxTurn);
    final maxBucketTotal = buckets.fold<int>(0, (max, bucket) {
      final total = bucket.totalFor(filter);
      return math.max(max, total);
    });
    final total = buckets.fold<int>(
      0,
      (sum, bucket) => sum + bucket.totalFor(filter),
    );

    return _TurnTimelineChartData(
      buckets: buckets,
      ticks: ticks,
      minTurn: minTurn,
      maxTurn: maxTurn,
      maxBucketTotal: maxBucketTotal,
      total: total,
    );
  }
}

class _MutableTurnTimelineBucket {
  _MutableTurnTimelineBucket(this.turn);

  final int turn;
  int combat = 0;
  int city = 0;
  int diplomacy = 0;
  int technology = 0;
  int other = 0;

  void add(ActivityLogFilter? category) {
    switch (category) {
      case ActivityLogFilter.combat:
        combat++;
      case ActivityLogFilter.city:
        city++;
      case ActivityLogFilter.diplomacy:
        diplomacy++;
      case ActivityLogFilter.technology:
        technology++;
      case ActivityLogFilter.all:
      case null:
        other++;
    }
  }

  _TurnTimelineBucket freeze() => _TurnTimelineBucket(
    turn: turn,
    combat: combat,
    city: city,
    diplomacy: diplomacy,
    technology: technology,
    other: other,
  );
}

class _TurnTimelineBucket {
  const _TurnTimelineBucket({
    required this.turn,
    required this.combat,
    required this.city,
    required this.diplomacy,
    required this.technology,
    required this.other,
  });

  final int turn;
  final int combat;
  final int city;
  final int diplomacy;
  final int technology;
  final int other;

  int totalFor(ActivityLogFilter filter) {
    return switch (filter) {
      ActivityLogFilter.all => combat + city + diplomacy + technology + other,
      ActivityLogFilter.combat => combat,
      ActivityLogFilter.city => city,
      ActivityLogFilter.diplomacy => diplomacy,
      ActivityLogFilter.technology => technology,
    };
  }

  List<_TurnTimelineSegment> segmentsFor(ActivityLogFilter filter) {
    return switch (filter) {
      ActivityLogFilter.all => [
        _TurnTimelineSegment(
          count: combat,
          color: ActivityLogFilter.combat.emptyAccent,
        ),
        _TurnTimelineSegment(
          count: city,
          color: ActivityLogFilter.city.emptyAccent,
        ),
        _TurnTimelineSegment(
          count: diplomacy,
          color: ActivityLogFilter.diplomacy.emptyAccent,
        ),
        _TurnTimelineSegment(
          count: technology,
          color: ActivityLogFilter.technology.emptyAccent,
        ),
        _TurnTimelineSegment(count: other, color: GameUiTheme.textMuted),
      ],
      ActivityLogFilter.combat => [
        _TurnTimelineSegment(
          count: combat,
          color: ActivityLogFilter.combat.emptyAccent,
        ),
      ],
      ActivityLogFilter.city => [
        _TurnTimelineSegment(
          count: city,
          color: ActivityLogFilter.city.emptyAccent,
        ),
      ],
      ActivityLogFilter.diplomacy => [
        _TurnTimelineSegment(
          count: diplomacy,
          color: ActivityLogFilter.diplomacy.emptyAccent,
        ),
      ],
      ActivityLogFilter.technology => [
        _TurnTimelineSegment(
          count: technology,
          color: ActivityLogFilter.technology.emptyAccent,
        ),
      ],
    };
  }
}

class _TurnTimelineSegment {
  const _TurnTimelineSegment({required this.count, required this.color});

  final int count;
  final Color color;
}

ActivityLogFilter? _activityCategoryFor(GameEvent event) {
  if (ActivityLogFilter.combat.matches(event)) return ActivityLogFilter.combat;
  if (ActivityLogFilter.city.matches(event)) return ActivityLogFilter.city;
  if (ActivityLogFilter.diplomacy.matches(event)) {
    return ActivityLogFilter.diplomacy;
  }
  if (ActivityLogFilter.technology.matches(event)) {
    return ActivityLogFilter.technology;
  }
  return null;
}

int _notificationTurn(GameEventNotification entry, int currentTurn) {
  final turn = entry.turn;
  if (turn != null && turn >= 0) return turn;
  return currentTurn;
}

List<int> _timelineTurnTicks(int minTurn, int maxTurn) {
  if (minTurn == maxTurn) return [maxTurn];
  final middleTurn = ((minTurn + maxTurn) / 2).round();
  return (<int>{minTurn, middleTurn, maxTurn}.toList()..sort());
}
