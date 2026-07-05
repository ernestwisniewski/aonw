part of 'load_game_screen.dart';

class _SaveCard extends StatelessWidget {
  const _SaveCard({
    required this.save,
    required this.relativeDate,
    required this.turnLabel,
    required this.resumeLabel,
    required this.replayLabel,
    required this.deleteLabel,
    required this.onResume,
    required this.onReplay,
    required this.onDelete,
    this.corruptedBody,
  });

  final GameSaveIndex save;
  final String relativeDate;
  final String turnLabel;
  final String resumeLabel;
  final String replayLabel;
  final String deleteLabel;
  final String? corruptedBody;
  final VoidCallback? onResume;
  final VoidCallback? onReplay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GameUiTheme.card,
      borderRadius: GameUiTheme.borderRadius,
      child: InkWell(
        onTap: onResume,
        borderRadius: GameUiTheme.borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SaveBadge(corrupted: save.corrupted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              save.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GameUiTheme.cardTitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              save.mapName.isEmpty
                                  ? turnLabel
                                  : '${GameText.uppercase(save.mapName)} · $turnLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GameUiTheme.cardMeta,
                            ),
                            if (corruptedBody != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                corruptedBody!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GameUiTheme.bodySmall.copyWith(
                                  color: GameUiTheme.warning,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SaveDatePill(label: relativeDate),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onResume,
                        icon: Icon(
                          save.corrupted
                              ? Icons.block_rounded
                              : Icons.play_arrow_rounded,
                          size: 16,
                        ),
                        label: Text(resumeLabel),
                        style: GameUiTheme.outlinedButtonStyle(
                          foreground: GameUiTheme.goldLight,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onReplay,
                        icon: const Icon(Icons.movie_filter_outlined, size: 16),
                        label: Text(replayLabel),
                        style: GameUiTheme.outlinedButtonStyle(
                          foreground: onReplay == null
                              ? GameUiTheme.textTertiary
                              : GameUiTheme.goldLight,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(deleteLabel),
                        style: GameUiTheme.outlinedButtonStyle(
                          foreground: GameUiTheme.textTertiary,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SaveBadge extends StatelessWidget {
  const _SaveBadge({required this.corrupted});

  final bool corrupted;

  @override
  Widget build(BuildContext context) {
    final accent = corrupted ? GameUiTheme.warning : GameUiTheme.gold;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withAlpha(22),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: accent.withAlpha(120)),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          corrupted ? Icons.warning_amber_rounded : Icons.flag_outlined,
          size: 19,
          color: corrupted ? GameUiTheme.warning : GameUiTheme.goldLight,
        ),
      ),
    );
  }
}

class _SaveDatePill extends StatelessWidget {
  const _SaveDatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(210),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(label, style: GameUiTheme.cardMeta),
      ),
    );
  }
}
