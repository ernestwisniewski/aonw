import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/map/widgets/map_selection_tile.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_section_header.dart';
import 'package:aonw/shared/widgets/scrollable_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditorMapPickerScreen extends ConsumerWidget {
  const EditorMapPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mapsAsync = ref.watch(availableMapsProvider);

    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: GameText.screenTitle(l10n.mainMenuMapEditor),
        onClose: ref.withMenuBack(() => context.go('/')),
      ),
      body: MenuRouteBackdrop(
        child: mapsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GameUiTheme.textSecondary),
          ),
          error: (error, _) => ScrollableErrorView(
            message: l10n.mapsLoadError('$error'),
            actionLabel: l10n.retryAction,
            onAction: ref.withMenuClick(
              () => ref.invalidate(availableMapsProvider),
            ),
          ),
          data: (maps) {
            final official = maps
                .where((m) => m.source == MapSource.asset)
                .toList();
            final yours = maps
                .where((m) => m.source == MapSource.saved)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: [
                GameUiScreenHeader(
                  icon: Icons.map_outlined,
                  title: l10n.editorMapPickerTitle,
                  subtitle: l10n.editorMapPickerSubtitle,
                  meta: [
                    GameUiMetaPill(
                      icon: Icons.edit_location_alt_outlined,
                      label: l10n.yourMapsCount(yours.length),
                    ),
                    GameUiMetaPill(
                      icon: Icons.public_outlined,
                      label: l10n.officialMapsCount(official.length),
                    ),
                  ],
                  trailing: _CreateMapButton(
                    onTap: ref.withMenuClick(() => context.go('/editor/map')),
                  ),
                ),

                if (yours.isNotEmpty) ...[
                  _ListInset(
                    child: GameUiSectionHeader(
                      label: GameText.sectionLabel(l10n.yourMapsSection),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...yours.map(
                    (map) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _DeletableMapTile(
                        map: map,
                        onTap: ref.withMenuClick(
                          () => _openEditor(context, map),
                        ),
                        onDelete: ref.withMenuClickAsync(
                          () => _confirmDelete(context, ref, map),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (official.isNotEmpty) ...[
                  _ListInset(
                    child: GameUiSectionHeader(
                      label: GameText.sectionLabel(l10n.officialMapsSection),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...official.map(
                    (map) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: MapSelectionTile(
                        map: map,
                        actionLabel: GameText.actionLabel(l10n.editAction),
                        onTap: ref.withMenuClick(
                          () => _openEditor(context, map),
                        ),
                      ),
                    ),
                  ),
                ],
                if (maps.isEmpty)
                  GameUiEmptyState(
                    icon: Icons.map_outlined,
                    title: l10n.editorMapPickerEmptyTitle,
                    message: l10n.editorMapPickerEmptyMessage,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, MapSelection map) {
    context.go('/editor/map?source=${map.sourceQueryValue}&name=${map.name}');
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MapSelection map,
  ) async {
    final confirmed = await showGameConfirmation(
      context: context,
      title: context.l10n.editorDeleteMapTitle,
      message: context.l10n.editorDeleteMapMessage(map.displayName),
      confirmLabel: context.l10n.deleteAction,
      cancelLabel: context.l10n.cancelAction,
      tone: GameConfirmationTone.danger,
    );

    if (confirmed) {
      await ref.read(mapRepositoryProvider).deleteSavedMap(map.name);
      ref.invalidate(availableMapsProvider);
    }
  }
}

class _DeletableMapTile extends StatelessWidget {
  final MapSelection map;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeletableMapTile({
    required this.map,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: MapSelectionTile(
            map: map,
            actionLabel: GameText.actionLabel(l10n.editAction),
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 8),
        _DeleteButton(onDelete: onDelete),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.editorDeleteMapTooltip,
      child: Material(
        color: GameUiTheme.surface.withAlpha(210),
        borderRadius: GameUiTheme.borderRadius,
        child: InkWell(
          onTap: onDelete,
          borderRadius: GameUiTheme.borderRadius,
          child: Container(
            width: 46,
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              borderRadius: GameUiTheme.borderRadius,
              border: Border.all(color: GameUiTheme.danger.withAlpha(120)),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xCCE05050),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateMapButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateMapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 16),
      label: Text(GameText.actionLabel(context.l10n.editorNewMapAction)),
      style: GameUiTheme.outlinedButtonStyle(
        foreground: GameUiTheme.goldLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _ListInset extends StatelessWidget {
  final Widget child;

  const _ListInset({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}
