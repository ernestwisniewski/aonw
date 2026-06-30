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
