import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/providers/editor_providers.dart';
import 'package:aonw/editor/widgets/editor_toolbar_sections.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditorBottomToolbar extends ConsumerStatefulWidget {
  final EditorState editorState;
  final HexDisplaySettings displaySettings;
  final double defaultZoom;
  final ValueChanged<double> onDefaultZoomChanged;

  const EditorBottomToolbar({
    required this.editorState,
    required this.displaySettings,
    required this.defaultZoom,
    required this.onDefaultZoomChanged,
    super.key,
  });

  @override
  ConsumerState<EditorBottomToolbar> createState() =>
      _EditorBottomToolbarState();
}

class _EditorBottomToolbarState extends ConsumerState<EditorBottomToolbar> {
  bool _expanded = true;

  EditorState get _editorState => widget.editorState;
  HexDisplaySettings get _displaySettings => widget.displaySettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: GameUiTheme.surface,
        border: Border(top: BorderSide(color: GameUiTheme.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: _expanded
                ? l10n.editorCollapseToolbarTooltip
                : l10n.editorExpandToolbarTooltip,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _expanded ? Icons.expand_more : Icons.expand_less,
                      size: 14,
                      color: GameUiTheme.sectionLabel,
                    ),
                    const SizedBox(width: 4),
                    const Text('EDITOR', style: GameUiTheme.toolbarLabel),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            EditorTerrainToolbarSection(
              selectedTerrains: _editorState.selectedTerrains,
              onToggleTerrain: ref
                  .read(editorStateProvider.notifier)
                  .toggleTerrain,
            ),
            EditorResourceToolbarSection(
              selectedResources: _editorState.selectedResources,
              onToggleResource: ref
                  .read(editorStateProvider.notifier)
                  .toggleResource,
            ),
            EditorObjectiveToolbarSection(
              selectedObjectiveType: _editorState.selectedObjectiveType,
              objectivePaintMode: _editorState.objectivePaintMode,
              onSelectObjective: ref
                  .read(editorStateProvider.notifier)
                  .selectObjective,
              onEraseObjective: ref
                  .read(editorStateProvider.notifier)
                  .eraseObjective,
              onClearObjectiveTool: ref
                  .read(editorStateProvider.notifier)
                  .clearObjectiveTool,
            ),
            EditorHeightToolbarSection(
              selectedHeight: _editorState.selectedHeight,
              showHeightBadge: _displaySettings.showHeightBadge,
              onToggleHeightBadge: ref
                  .read(hexDisplayProvider.notifier)
                  .toggleHeightBadge,
              onHeightChanged: ref.read(editorStateProvider.notifier).setHeight,
            ),
            EditorStyleToolbarSection(
              displaySettings: _displaySettings,
              defaultZoom: widget.defaultZoom,
              onHexBorderColorChanged: ref
                  .read(hexDisplayProvider.notifier)
                  .setHexBorderColor,
              onSelectedHexColorChanged: ref
                  .read(hexDisplayProvider.notifier)
                  .setSelectedHexColor,
              onWallTintColorChanged: ref
                  .read(hexDisplayProvider.notifier)
                  .setWallTintColor,
              onDefaultZoomChanged: widget.onDefaultZoomChanged,
            ),
          ],
        ],
      ),
    );
  }
}
