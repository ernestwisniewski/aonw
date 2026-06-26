part of 'replay_screen.dart';

class _ReplayErrorView extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onBack;

  const _ReplayErrorView({
    required this.title,
    required this.body,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: ScrollableErrorView(
        message: '$title\n\n$body',
        actionLabel: l10n.backAction,
        onAction: onBack,
      ),
    );
  }
}

String _replayErrorBody(AppLocalizations l10n, Object error) {
  if (error is ReplayBuildException) {
    return switch (error.reason) {
      ReplayBuildFailureReason.missingInitialSnapshot =>
        l10n.replayMissingInitialSnapshotBody,
      ReplayBuildFailureReason.offsetGap => l10n.replayCorruptLogBody,
      ReplayBuildFailureReason.corruptLog => l10n.replayCorruptLogBody,
    };
  }
  return l10n.replayErrorBody(error.toString());
}

String _commandLabel(GameCommand command) {
  final raw = command.runtimeType.toString().replaceAll('Command', '');
  return raw.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (match) => ' ');
}

extension on double {
  String get g => this == roundToDouble() ? toInt().toString() : toString();
}
