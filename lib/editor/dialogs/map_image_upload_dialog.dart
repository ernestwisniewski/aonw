import 'package:aonw/editor/dialogs/editor_image_slice_toggle.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';

typedef MapImageUploadOptions = ({bool sliceImage});

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
              editorImageFileName(imageSourcePath),
              style: const TextStyle(
                color: GameUiTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            EditorImageSliceToggle(
              value: sliceImage,
              onChanged: (value) => setDialogState(() => sliceImage = value),
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
