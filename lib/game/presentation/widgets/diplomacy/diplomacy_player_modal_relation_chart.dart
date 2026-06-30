part of 'diplomacy_player_modal.dart';

class _RelationScoreChart extends StatelessWidget {
  const _RelationScoreChart({
    required this.entries,
    required this.currentTurn,
    required this.l10n,
  });

  final List<DiplomaticScoreEntry> entries;
  final int currentTurn;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ticks = _relationTurnTicks(entries, currentTurn);
    return SizedBox(
      height: 104,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _RelationScoreChartPainter(
                entries: entries,
                currentTurn: currentTurn,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < ticks.length; i++) ...[
                if (i > 0) const Spacer(),
                Text(
                  l10n.topResourceTurnShortLabel(ticks[i]),
                  key: Key('diplomacy.relationChart.turn.${ticks[i]}'),
                  style: GameUiTheme.chipLabel.copyWith(
                    color: GameUiTheme.textTertiary,
                    fontFeatures: GameUiTheme.tabularFigures,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RelationScoreChartPainter extends CustomPainter {
  const _RelationScoreChartPainter({
    required this.entries,
    required this.currentTurn,
  });

  final List<DiplomaticScoreEntry> entries;
  final int currentTurn;

  @override
  void paint(Canvas canvas, Size size) {
    final indexedEntries =
        [for (var i = 0; i < entries.length; i++) MapEntry(i, entries[i])]
          ..sort((a, b) {
            final turnCompare = a.value.turn.compareTo(b.value.turn);
            if (turnCompare != 0) return turnCompare;
            return a.key.compareTo(b.key);
          });
    final chartEntries = [
      for (final indexedEntry in indexedEntries) indexedEntry.value,
    ];
    final ticks = _relationTurnTicks(chartEntries, currentTurn);
    final minTurn = ticks.first;
    final maxTurn = ticks.last;

    final axisPaint = Paint()
      ..color = GameUiTheme.textTertiary.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final guidePaint = Paint()
      ..color = GameUiTheme.textTertiary.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    final zeroY = _scoreY(0, size.height);
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), axisPaint);
    for (final tick in ticks) {
      final x = _turnX(tick, minTurn, maxTurn, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
    }
    if (chartEntries.isEmpty) return;

    final linePaint = Paint()
      ..color = _scoreColor(chartEntries.last.scoreAfter)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = _scoreColor(chartEntries.last.scoreAfter)
      ..style = PaintingStyle.fill;
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < chartEntries.length; i++) {
      final entry = chartEntries[i];
      final x = _turnX(entry.turn, minTurn, maxTurn, size.width);
      final y = _scoreY(entry.scoreAfter, size.height);
      final point = Offset(x, y);
      points.add(point);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, linePaint);
    for (final point in points) {
      canvas.drawCircle(point, 2.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RelationScoreChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.currentTurn != currentTurn;
  }

  double _turnX(int turn, int minTurn, int maxTurn, double width) {
    if (minTurn == maxTurn) return width;
    return width * (turn - minTurn) / (maxTurn - minTurn);
  }

  double _scoreY(int score, double height) {
    final clamped = score.clamp(-100, 100);
    final normalized = (100 - (clamped + 100)) / 200;
    return height * normalized;
  }
}

List<int> _relationTurnTicks(
  List<DiplomaticScoreEntry> entries,
  int currentTurn,
) {
  final turns = <int>[
    for (final entry in entries) entry.turn,
    currentTurn,
  ].where((turn) => turn >= 0).toList(growable: false);
  if (turns.isEmpty) return [currentTurn];

  final minTurn = turns.reduce(math.min);
  final maxTurn = turns.reduce(math.max);
  if (minTurn == maxTurn) return [maxTurn];

  final middleTurn = ((minTurn + maxTurn) / 2).round();
  return (<int>{minTurn, middleTurn, maxTurn}.toList()..sort());
}

Color _scoreColor(int score) {
  if (score >= DiplomacyState.friendlyScoreThreshold) {
    return GameUiTheme.success;
  }
  if (score <= DiplomacyState.hostileScoreThreshold) return GameUiTheme.danger;
  return GameUiTheme.warning;
}
