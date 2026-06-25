part of 'diplomacy_player_modal.dart';

class _ProposalsSection extends StatelessWidget {
  const _ProposalsSection({
    required this.l10n,
    required this.diplomacy,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
  });

  final AppLocalizations l10n;
  final DiplomacyState diplomacy;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final proposals = diplomacy
        .proposalsFor(activePlayerId)
        .where(
          (proposal) =>
              DiplomacyState.relationKey(
                proposal.fromPlayerId,
                proposal.toPlayerId,
              ) ==
              DiplomacyState.relationKey(activePlayerId, targetPlayerId),
        )
        .toList();
    return _Section(
      title: l10n.diplomacyProposalsTitle,
      child: proposals.isEmpty
          ? Text(l10n.diplomacyNoHistory, style: GameUiTheme.bodySmall)
          : Column(
              children: [
                for (final proposal in proposals)
                  _ProposalRow(
                    proposal: proposal,
                    l10n: l10n,
                    activePlayerId: activePlayerId,
                    onCommand: onCommand,
                  ),
              ],
            ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.l10n,
    required this.entries,
    required this.messages,
    required this.proposals,
    required this.playerNameFor,
  });

  final AppLocalizations l10n;
  final List<DiplomaticScoreEntry> entries;
  final List<DiplomaticMessage> messages;
  final List<DiplomaticProposal> proposals;
  final String Function(String playerId) playerNameFor;

  @override
  Widget build(BuildContext context) {
    final history = _historyItems().toList(growable: false)
      ..sort(_compareHistoryItems);
    return _Section(
      title: l10n.diplomacyHistoryTitle,
      child: history.isEmpty
          ? Text(l10n.diplomacyNoHistory, style: GameUiTheme.bodySmall)
          : Column(
              children: [for (final item in history) _HistoryRow(item: item)],
            ),
    );
  }

  Iterable<_HistoryItem> _historyItems() sync* {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final text = DiplomacyHistoryPresenter.scoreEntry(l10n, entry);
      yield _HistoryItem(
        turn: entry.turn,
        sequence: i,
        title: text.title,
        subtitle: text.subtitle,
        detail: text.detail,
        delta: text.delta,
        accent: _scoreColor(entry.scoreAfter),
      );
    }
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final text = DiplomacyHistoryPresenter.message(
        l10n,
        message,
        playerNameFor: playerNameFor,
      );
      yield _HistoryItem(
        turn: message.respondedTurn ?? message.createdTurn,
        sequence: entries.length + i,
        title: text.title,
        subtitle: text.subtitle,
        detail: text.detail,
        delta: text.delta,
        accent: message.response == null
            ? GameUiTheme.info
            : _scoreColor(message.relationScoreAfter ?? 0),
      );
    }
    for (var i = 0; i < proposals.length; i++) {
      final proposal = proposals[i];
      final text = DiplomacyHistoryPresenter.proposal(
        l10n,
        proposal,
        playerNameFor: playerNameFor,
      );
      yield _HistoryItem(
        turn: proposal.createdTurn,
        sequence: entries.length + messages.length + i,
        title: text.title,
        subtitle: text.subtitle,
        detail: text.detail,
        delta: text.delta,
        accent: GameUiTheme.info,
      );
    }
  }
}

class _HistoryItem {
  const _HistoryItem({
    required this.turn,
    required this.sequence,
    required this.title,
    required this.subtitle,
    this.detail,
    this.delta,
    this.accent = GameUiTheme.info,
  });

  final int turn;
  final int sequence;
  final String title;
  final String subtitle;
  final String? detail;
  final int? delta;
  final Color accent;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final delta = item.delta;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: ShapeDecoration(
              color: item.accent,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.bodySmall.copyWith(
                    color: GameUiTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.cardMeta,
                ),
                if (item.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.bodySmall.copyWith(
                      color: GameUiTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Text(
              '${delta > 0 ? '+' : ''}$delta',
              style: GameUiTheme.bodyStrong.copyWith(color: item.accent),
            ),
          ],
        ],
      ),
    );
  }
}

int _compareHistoryItems(_HistoryItem a, _HistoryItem b) {
  final turnCompare = b.turn.compareTo(a.turn);
  if (turnCompare != 0) return turnCompare;
  return b.sequence.compareTo(a.sequence);
}

class _MessagesSection extends StatelessWidget {
  const _MessagesSection({
    required this.l10n,
    required this.diplomacy,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
  });

  final AppLocalizations l10n;
  final DiplomacyState diplomacy;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final messages = diplomacy.messagesBetween(activePlayerId, targetPlayerId);
    return _Section(
      title: l10n.diplomacyMessagesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (messages.isEmpty)
            Text(l10n.diplomacyNoMessages, style: GameUiTheme.bodySmall)
          else
            for (final message in messages.take(3))
              _MessageRow(
                message: message,
                l10n: l10n,
                activePlayerId: activePlayerId,
                onCommand: onCommand,
              ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in DiplomaticMessageTopic.values)
                _TopicDispatchButton(
                  label: _topicLabel(l10n, topic),
                  onPressed: () => unawaited(
                    onCommand(
                      SendDiplomaticMessageCommand(
                        playerId: activePlayerId,
                        targetPlayerId: targetPlayerId,
                        topic: topic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicDispatchButton extends StatefulWidget {
  const _TopicDispatchButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_TopicDispatchButton> createState() => _TopicDispatchButtonState();
}

class _TopicDispatchButtonState extends State<_TopicDispatchButton> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _hovered
        ? GameUiTheme.goldLight
        : SurfaceElevation.flat.strokeColor(color: GameUiTheme.gold, alpha: 95);
    final background = SurfaceElevation.raised.fill(
      background: GameUiTheme.bg,
      alpha: _pressed ? 190 : 145,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 34, maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: ShapeDecoration(
            color: background,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            widget.label,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GameUiTheme.menuButton.copyWith(
              color: _hovered
                  ? GameUiTheme.goldLight
                  : GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
