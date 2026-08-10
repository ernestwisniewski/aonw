import 'dart:math' as math;

import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/widgets/activity_log/activity_log_filter_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter/material.dart';

class TurnTimelineChart extends StatelessWidget {
  const TurnTimelineChart({
    required this.entries,
    required this.filter,
    required this.currentTurn,
    required this.compact,
    super.key,
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
        child: _chartContent(l10n, data),
      ),
    );
  }

  Widget _chartContent(AppLocalizations l10n, _TurnTimelineChartData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chartHeader(l10n, data),
        SizedBox(height: compact ? 8 : 10),
        SizedBox(
          height: compact ? 104 : 126,
          child: CustomPaint(
            painter: _TurnTimelineChartPainter(data: data, filter: filter),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        _turnTicks(l10n, data),
        SizedBox(height: compact ? 8 : 10),
        _summaryMetrics(l10n, data),
      ],
    );
  }

  Widget _chartHeader(AppLocalizations l10n, _TurnTimelineChartData data) {
    return Row(
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
    );
  }

  Widget _turnTicks(AppLocalizations l10n, _TurnTimelineChartData data) {
    return Row(
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
    );
  }

  Widget _summaryMetrics(AppLocalizations l10n, _TurnTimelineChartData data) {
    return Wrap(
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
    _drawGuides(canvas, plot, guidePaint);
    if (data.buckets.isEmpty || data.maxBucketTotal == 0) return;
    _drawBuckets(canvas, plot);
  }

  void _drawGuides(Canvas canvas, Rect plot, Paint guidePaint) {
    for (var i = 1; i <= 3; i++) {
      final y = plot.bottom - plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), guidePaint);
    }
  }

  void _drawBuckets(Canvas canvas, Rect plot) {
    final range = math.max(1, data.maxTurn - data.minTurn);
    final slotWidth = data.buckets.length <= 1
        ? plot.width
        : plot.width / (range + 1);
    final barWidth = slotWidth.clamp(7.0, 18.0).toDouble();
    for (final bucket in data.buckets) {
      _drawBucket(canvas, plot, bucket, barWidth);
    }
  }

  void _drawBucket(
    Canvas canvas,
    Rect plot,
    _TurnTimelineBucket bucket,
    double barWidth,
  ) {
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
    return _chartDataFor(buckets, filter, currentTurn);
  }
}

_TurnTimelineChartData _chartDataFor(
  List<_TurnTimelineBucket> buckets,
  ActivityLogFilter filter,
  int currentTurn,
) {
  final turns = <int>[for (final bucket in buckets) bucket.turn, currentTurn];
  final minTurn = turns.reduce(math.min);
  final maxTurn = turns.reduce(math.max);
  final maxBucketTotal = buckets.fold<int>(
    0,
    (max, bucket) => math.max(max, bucket.totalFor(filter)),
  );
  final total = buckets.fold<int>(
    0,
    (sum, bucket) => sum + bucket.totalFor(filter),
  );
  return _TurnTimelineChartData(
    buckets: buckets,
    ticks: _timelineTurnTicks(minTurn, maxTurn),
    minTurn: minTurn,
    maxTurn: maxTurn,
    maxBucketTotal: maxBucketTotal,
    total: total,
  );
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

  int totalFor(ActivityLogFilter filter) => switch (filter) {
    ActivityLogFilter.all => combat + city + diplomacy + technology + other,
    ActivityLogFilter.combat => combat,
    ActivityLogFilter.city => city,
    ActivityLogFilter.diplomacy => diplomacy,
    ActivityLogFilter.technology => technology,
  };

  List<_TurnTimelineSegment> segmentsFor(ActivityLogFilter filter) {
    if (filter != ActivityLogFilter.all) {
      return [
        _TurnTimelineSegment(
          count: totalFor(filter),
          color: filter.emptyAccent,
        ),
      ];
    }
    return [
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
    ];
  }
}

class _TurnTimelineSegment {
  const _TurnTimelineSegment({required this.count, required this.color});

  final int count;
  final Color color;
}

ActivityLogFilter? _activityCategoryFor(GameEvent event) {
  for (final filter in ActivityLogFilter.values.skip(1)) {
    if (filter.matches(event)) return filter;
  }
  return null;
}

int _notificationTurn(GameEventNotification entry, int currentTurn) {
  final turn = entry.turn;
  return turn != null && turn >= 0 ? turn : currentTurn;
}

List<int> _timelineTurnTicks(int minTurn, int maxTurn) {
  if (minTurn == maxTurn) return [maxTurn];
  final middleTurn = ((minTurn + maxTurn) / 2).round();
  return (<int>{minTurn, middleTurn, maxTurn}.toList()..sort());
}
