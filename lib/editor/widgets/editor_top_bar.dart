import 'package:aonw/editor/widgets/editor_action_button.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EditorTopBar extends StatelessWidget {
  final MapData? mapData;
  final VoidCallback onAddColumn;
  final VoidCallback onRemoveColumn;
  final VoidCallback onAddRow;
  final VoidCallback onRemoveRow;
  final VoidCallback onReplaceImage;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onClose;

  const EditorTopBar({
    required this.mapData,
    required this.onAddColumn,
    required this.onRemoveColumn,
    required this.onAddRow,
    required this.onRemoveRow,
    required this.onReplaceImage,
    required this.onSave,
    required this.onExport,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cols = mapData?.cols ?? 0;
    final rows = mapData?.rows ?? 0;

    return SafeArea(
      child: Container(
        color: GameUiTheme.bg,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: GameUiTheme.textSecondary,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const Text('✕', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Text('MAP EDITOR', style: GameUiTheme.actionLabel),
              const SizedBox(width: 12),
              Text(
                '$cols×$rows',
                style: const TextStyle(
                  color: GameUiTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              EditorActionButton('+C', onAddColumn),
              EditorActionButton('-C', onRemoveColumn),
              EditorActionButton('+R', onAddRow),
              EditorActionButton('-R', onRemoveRow),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Replace map image',
                onPressed: onReplaceImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                color: GameUiTheme.textSecondary,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                padding: EdgeInsets.zero,
              ),
              EditorActionButton('SAVE', onSave),
              EditorActionButton('EXPORT', onExport),
            ],
          ),
        ),
      ),
    );
  }
}
