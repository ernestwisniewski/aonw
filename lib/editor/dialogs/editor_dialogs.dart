import 'package:aonw/editor/services/map_saver.dart';
import 'package:aonw/map/domain/map_constraints.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';

typedef NewMapDialogResult = ({int cols, int rows, TerrainType defaultTerrain});

typedef SaveMapDialogResult = ({
  String name,
  String? imageSourcePath,
  bool sliceImage,
});

typedef MapImageUploadOptions = ({bool sliceImage});

enum ExportMapDestination { share, saveToDisk }

typedef ExportMapDialogResult = ({
  String filename,
  ExportMapDestination destination,
});

Future<NewMapDialogResult?> showNewMapDialog(BuildContext context) {
  int cols = 10;
  int rows = 8;
  TerrainType defaultTerrain = TerrainType.ocean;

  return showGameModal<NewMapDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => GameModalScaffold(
        header: const GameModalHeader(title: 'New Map'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogSlider(
              label: 'Columns: $cols',
              value: cols.toDouble(),
              min: MapConstraints.minCols.toDouble(),
              max: MapConstraints.maxCols.toDouble(),
              onChanged: (value) => setDialogState(() => cols = value.round()),
            ),
            _DialogSlider(
              label: 'Rows: $rows',
              value: rows.toDouble(),
              min: MapConstraints.minRows.toDouble(),
              max: MapConstraints.maxRows.toDouble(),
              onChanged: (value) => setDialogState(() => rows = value.round()),
            ),
            const SizedBox(height: 8),
            DropdownButton<TerrainType>(
              value: defaultTerrain,
              dropdownColor: GameUiTheme.bg,
              style: const TextStyle(color: GameUiTheme.textPrimary),
              items: TerrainType.values
                  .map(
                    (terrain) => DropdownMenuItem(
                      value: terrain,
                      child: Text(terrain.name),
                    ),
                  )
                  .toList(),
              onChanged: (terrain) =>
                  setDialogState(() => defaultTerrain = terrain!),
            ),
          ],
        ),
        actions: [
          GameModalAction(
            label: 'CREATE',
            variant: EpicButtonVariant.primary,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop((cols: cols, rows: rows, defaultTerrain: defaultTerrain)),
          ),
        ],
      ),
    ),
  );
}

Future<ExportMapDialogResult?> showExportMapDialog(
  BuildContext context, {
  String initialFilename = 'map',
}) async {
  String filename = initialFilename;
  final controller = TextEditingController(text: filename);
  final filenameFocusNode = FocusNode();

  ExportMapDialogResult build(ExportMapDestination destination) =>
      (filename: filename.isEmpty ? 'map' : filename, destination: destination);

  try {
    return await showGameModal<ExportMapDialogResult>(
      context: context,
      requestFocus: true,
      builder: (dialogContext) => GameModalScaffold(
        header: const GameModalHeader(title: 'Export Map'),
        content: TextField(
          controller: controller,
          focusNode: filenameFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: GameUiTheme.inputText,
          decoration: const InputDecoration(
            labelText: 'Filename',
            labelStyle: TextStyle(color: GameUiTheme.textSecondary),
          ),
          onChanged: (value) => filename = value.isEmpty ? 'map' : value,
          onSubmitted: (value) {
            filename = value.isEmpty ? 'map' : value;
            Navigator.of(dialogContext).pop(build(ExportMapDestination.share));
          },
        ),
        actions: [
          GameModalAction(
            label: 'CANCEL',
            variant: EpicButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          GameModalAction(
            label: 'SAVE TO DISK',
            variant: EpicButtonVariant.outlined,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(build(ExportMapDestination.saveToDisk)),
          ),
          GameModalAction(
            label: 'SHARE',
            variant: EpicButtonVariant.primary,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(build(ExportMapDestination.share)),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
    filenameFocusNode.dispose();
  }
}

Future<SaveMapDialogResult?> showSaveMapDialog(
  BuildContext context, {
  required String initialName,
}) async {
  String name = initialName;
  String? imageSourcePath;
  bool sliceImage = false;
  final controller = TextEditingController(text: initialName);
  final nameFocusNode = FocusNode();

  try {
    return await showGameModal<SaveMapDialogResult>(
      context: context,
      requestFocus: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => GameModalScaffold(
          header: const GameModalHeader(title: 'Save Map'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                focusNode: nameFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: GameUiTheme.inputText,
                decoration: const InputDecoration(
                  labelText: 'Map name',
                  labelStyle: TextStyle(color: GameUiTheme.textSecondary),
                ),
                onChanged: (value) => name = value.isEmpty ? 'map' : value,
                onSubmitted: (value) => Navigator.of(dialogContext).pop((
                  name: value.isEmpty ? 'map' : value,
                  imageSourcePath: imageSourcePath,
                  sliceImage: sliceImage,
                )),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final pickedPath = await MapSaver.pickImage();
                  if (pickedPath != null) {
                    setDialogState(() => imageSourcePath = pickedPath);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: GameUiTheme.textPrimary,
                  padding: EdgeInsets.zero,
                  textStyle: GameUiTheme.actionLabel,
                ),
                child: Text(
                  imageSourcePath != null
                      ? 'Image: ${_displayFileName(imageSourcePath!)}'
                      : 'CHOOSE IMAGE (optional)',
                ),
              ),
              if (imageSourcePath != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Checkbox(
                      value: sliceImage,
                      onChanged: (v) =>
                          setDialogState(() => sliceImage = v ?? false),
                      side: const BorderSide(color: GameUiTheme.textSecondary),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? GameUiTheme.textPrimary
                            : Colors.transparent,
                      ),
                      checkColor: GameUiTheme.bg,
                    ),
                    GestureDetector(
                      onTap: () =>
                          setDialogState(() => sliceImage = !sliceImage),
                      child: const Text(
                        'Slice image',
                        style: TextStyle(
                          color: GameUiTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            GameModalAction(
              label: 'CANCEL',
              variant: EpicButtonVariant.text,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            GameModalAction(
              label: 'SAVE',
              variant: EpicButtonVariant.primary,
              onPressed: () => Navigator.of(dialogContext).pop((
                name: name,
                imageSourcePath: imageSourcePath,
                sliceImage: sliceImage,
              )),
            ),
          ],
        ),
      ),
    );
  } finally {
    controller.dispose();
    nameFocusNode.dispose();
  }
}

Future<MapImageUploadOptions?> showMapImageUploadOptionsDialog(
  BuildContext context, {
  required String imageSourcePath,
  required bool initialSliceImage,
}) async {
  var sliceImage = initialSliceImage;

  return showGameModal<MapImageUploadOptions>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => GameModalScaffold(
        header: const GameModalHeader(title: 'Map Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayFileName(imageSourcePath),
              style: const TextStyle(
                color: GameUiTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: sliceImage,
                  onChanged: (value) =>
                      setDialogState(() => sliceImage = value ?? false),
                  side: const BorderSide(color: GameUiTheme.textSecondary),
                  fillColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? GameUiTheme.textPrimary
                        : Colors.transparent,
                  ),
                  checkColor: GameUiTheme.bg,
                ),
                GestureDetector(
                  onTap: () => setDialogState(() => sliceImage = !sliceImage),
                  child: const Text(
                    'Slice image',
                    style: TextStyle(
                      color: GameUiTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          GameModalAction(
            label: 'CANCEL',
            variant: EpicButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          GameModalAction(
            label: 'APPLY',
            variant: EpicButtonVariant.primary,
            onPressed: () =>
                Navigator.of(dialogContext).pop((sliceImage: sliceImage)),
          ),
        ],
      ),
    ),
  );
}

String _displayFileName(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}

class _DialogSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _DialogSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: GameUiTheme.textPrimary, fontSize: 13),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
