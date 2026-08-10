import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';

enum ExportMapDestination { share, saveToDisk }

typedef ExportMapDialogResult = ({
  String filename,
  ExportMapDestination destination,
});

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
