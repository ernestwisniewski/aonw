part of 'replay_screen.dart';

class _ReplayEventSummary extends StatelessWidget {
  final List<GameEventNotificationMessage> messages;
  final ReplayStep? step;

  const _ReplayEventSummary({required this.messages, required this.step});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (step == null) {
      return Text(
        l10n.replayInitialStateLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textSecondary),
      );
    }
    if (messages.isEmpty) {
      final loggedCommand = step!.loggedCommand;
      final command = loggedCommand.command;
      return Text(
        command == null
            ? l10n.replayEventCount(loggedCommand.events.length)
            : _commandLabel(command),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final message in messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${message.title}: ${message.body}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
