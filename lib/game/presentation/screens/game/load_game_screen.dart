import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw/shared/widgets/scrollable_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LoadGameScreen extends ConsumerWidget {
  const LoadGameScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GameSaveIndex save,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showGameConfirmation(
      context: context,
      title: l10n.deleteGameTitle,
      message: l10n.deleteGameMessage(save.name),
      confirmLabel: l10n.deleteAction,
      cancelLabel: l10n.cancelAction,
      tone: GameConfirmationTone.danger,
    );
    if (!context.mounted) return;
    if (confirmed) {
      await ref.read(gameRepositoryProvider).delete(save.id);
      if (context.mounted) {
        ref.invalidate(gameSavesIndexProvider);
      }
    }
  }

  String _relativeDate(BuildContext context, WidgetRef ref, DateTime savedAt) {
    final l10n = AppLocalizations.of(context);
    final now = ref.read(gameClockProvider).now();
    final today = DateTime(now.year, now.month, now.day);
    final saveDay = DateTime(
      savedAt.toLocal().year,
      savedAt.toLocal().month,
      savedAt.toLocal().day,
    );
    final diff = today.difference(saveDay).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    final local = savedAt.toLocal();
    return '${local.day} ${DateFormat.MMM(l10n.localeName).format(local)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: l10n.loadGameTitle,
        onClose: ref.withMenuBack(() => context.go('/')),
      ),
      body: MenuRouteBackdrop(child: _buildBody(context, ref)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(gameSavesIndexProvider)
        .when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GameUiTheme.textSecondary),
          ),
          error: (error, _) => ScrollableErrorView(
            message: l10n.loadGameError(error.toString()),
            actionLabel: l10n.retryAction,
            onAction: ref.withMenuClick(
              () => ref.invalidate(gameSavesIndexProvider),
            ),
          ),
          data: (saves) => _buildSaves(context, ref, saves),
        );
  }

  Widget _buildSaves(
    BuildContext context,
    WidgetRef ref,
    List<GameSaveIndex> saves,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        GameUiScreenHeader(
          icon: Icons.folder_open_outlined,
          title: l10n.loadGameHeaderTitle,
          subtitle: saves.isEmpty
              ? l10n.loadGameHeaderEmptySubtitle
              : l10n.loadGameHeaderSavesSubtitle,
          meta: [
            GameUiMetaPill(
              icon: Icons.save_outlined,
              label: l10n.loadGameSavesCount(saves.length),
            ),
          ],
        ),
        if (saves.isEmpty)
          GameUiEmptyState(
            icon: Icons.flag_outlined,
            title: l10n.noSavedGames,
            action: OutlinedButton.icon(
              onPressed: ref.withMenuClick(() => context.go('/new-game')),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.newGameAction),
              style: GameUiTheme.outlinedButtonStyle(
                foreground: GameUiTheme.goldLight,
              ),
            ),
          )
        else
          for (final save in saves)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _SaveCard(
                save: save,
                relativeDate: _relativeDate(context, ref, save.savedAt),
                turnLabel: save.corrupted
                    ? l10n.loadGameCorruptedStatus
                    : l10n.turnLabel(save.turn),
                resumeLabel: save.corrupted
                    ? l10n.loadGameCorruptedAction
                    : l10n.resumeAction,
                replayLabel: save.corrupted || !save.replayAvailable
                    ? l10n.replayUnavailableAction
                    : l10n.replayAction,
                deleteLabel: l10n.deleteAction,
                corruptedBody: save.corrupted
                    ? l10n.loadGameCorruptedBody
                    : null,
                onResume: save.corrupted
                    ? null
                    : ref.withMenuClick(
                        () => context.go(
                          '/game?saveId=${save.id}'
                          '&name=${Uri.encodeComponent(save.mapName)}'
                          '&source=${save.mapSource.name}',
                        ),
                      ),
                onReplay: save.corrupted || !save.replayAvailable
                    ? null
                    : ref.withMenuClick(
                        () => context.go('/replay?saveId=${save.id}'),
                      ),
                onDelete: ref.withMenuClickAsync(
                  () => _confirmDelete(context, ref, save),
                ),
              ),
            ),
      ],
    );
  }
}

class _SaveCard extends StatelessWidget {
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

  const _SaveCard({
    required this.save,
    required this.relativeDate,
    required this.turnLabel,
    required this.resumeLabel,
    required this.replayLabel,
    required this.deleteLabel,
    this.corruptedBody,
    required this.onResume,
    required this.onReplay,
    required this.onDelete,
  });

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
                      _DatePill(label: relativeDate),
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

class _DatePill extends StatelessWidget {
  final String label;

  const _DatePill({required this.label});

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
