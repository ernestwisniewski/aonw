part of 'diplomacy_player_modal.dart';

class _ProposalRow extends StatelessWidget {
  const _ProposalRow({
    required this.proposal,
    required this.l10n,
    required this.activePlayerId,
    required this.onCommand,
  });

  final DiplomaticProposal proposal;
  final AppLocalizations l10n;
  final String activePlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final incoming = proposal.toPlayerId == activePlayerId;
    final label = _proposalLabel(l10n, proposal.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GameUiTheme.bodySmall)),
          if (incoming) ...[
            EpicButton.text(
              label: l10n.diplomacyAccept,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              onPressed: () => unawaited(
                onCommand(
                  RespondDiplomaticProposalCommand(
                    playerId: activePlayerId,
                    proposalId: proposal.id,
                    accepted: true,
                  ),
                ),
              ),
            ),
            EpicButton.text(
              label: l10n.diplomacyDecline,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              onPressed: () => unawaited(
                onCommand(
                  RespondDiplomaticProposalCommand(
                    playerId: activePlayerId,
                    proposalId: proposal.id,
                    accepted: false,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.diplomacy,
    required this.l10n,
    required this.activePlayerId,
    required this.onCommand,
  });

  final DiplomaticMessage message;
  final DiplomacyState diplomacy;
  final AppLocalizations l10n;
  final String activePlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final incoming = message.toPlayerId == activePlayerId && !message.responded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_topicLabel(l10n, message.topic), style: GameUiTheme.bodySmall),
          if (message.response != null)
            Text(
              '${_responseLabel(l10n, message.response!)} (${message.relationScoreDelta > 0 ? '+' : ''}${message.relationScoreDelta})',
              style: GameUiTheme.cardMeta,
            ),
          if (incoming)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final response in DiplomaticMessageResponse.values)
                    EpicButton.text(
                      label: _responseActionLabel(response),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      onPressed: () => unawaited(
                        onCommand(
                          RespondDiplomaticMessageCommand(
                            playerId: activePlayerId,
                            messageId: message.id,
                            response: response,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _responseActionLabel(DiplomaticMessageResponse response) {
    final delta = DiplomaticMessageEffects.relationDeltaForResponse(
      diplomacy,
      message,
      response,
    );
    return '${_responseLabel(l10n, response)} '
        '(${DiplomacyHistoryPresenter.signedDelta(delta)})';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 0,
        borderColor: GameUiTheme.copper,
        border: BorderEmphasis.regular,
        topBorder: true,
        boxShadow: const [],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GameUiTheme.sectionHeader),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _RelationDot extends StatelessWidget {
  const _RelationDot({required this.status});

  final DiplomaticRelationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: ShapeDecoration(
        color: MultiplayerRelationStatusStyle.color(status),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.own,
    required this.target,
  });

  final String label;
  final int own;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GameUiTheme.bodySmall)),
          Text('$own / $target', style: GameUiTheme.bodyStrong),
        ],
      ),
    );
  }
}

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

class _RelationScoreDrivers extends StatelessWidget {
  const _RelationScoreDrivers({required this.entries, required this.l10n});

  final List<DiplomaticScoreEntry> entries;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final recent = entries
        .where((entry) => entry.delta != 0)
        .toList(growable: false)
        .reversed
        .take(4)
        .toList(growable: false);
    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.diplomacyScoreDriversTitle,
            style: GameUiTheme.chipLabel.copyWith(
              color: GameUiTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in recent) _RelationScoreDriverRow(entry, l10n),
        ],
      ),
    );
  }
}

class _RelationScoreDriverRow extends StatelessWidget {
  const _RelationScoreDriverRow(this.entry, this.l10n);

  final DiplomaticScoreEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final positive = entry.delta > 0;
    final color = positive ? GameUiTheme.success : GameUiTheme.danger;
    final delta = '${positive ? '+' : ''}${entry.delta}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          GameIcon(
            positive ? GameIcons.chevronUp : GameIcons.chevronDown,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_scoreReasonLabel(l10n, entry.reason)} · ${l10n.topResourceTurnShortLabel(entry.turn)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(delta, style: GameUiTheme.bodyStrong.copyWith(color: color)),
        ],
      ),
    );
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
