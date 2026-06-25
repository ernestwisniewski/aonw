import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:flutter/material.dart';

enum GameConfirmationTone { neutral, danger }

Future<T?> showGameModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  GameModalSize size = GameModalSize.adaptive,
  bool barrierDismissible = true,
  bool? requestFocus,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    requestFocus: requestFocus,
    barrierColor: SurfaceElevation.flat.fill(
      background: Colors.black,
      alpha: 150,
    ),
    builder: (dialogContext) {
      return Material(
        type: MaterialType.transparency,
        child: SafeArea(child: Center(child: builder(dialogContext))),
      );
    },
  );
}

Future<T?> showGameBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: SurfaceElevation.flat.fill(
      background: Colors.black,
      alpha: 118,
    ),
    builder: (sheetContext) {
      return Material(
        type: MaterialType.transparency,
        child: builder(sheetContext),
      );
    },
  );
}

Future<bool> showGameConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  GameConfirmationTone tone = GameConfirmationTone.neutral,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showGameModal<bool>(
    context: context,
    size: GameModalSize.compact,
    builder: (dialogContext) {
      return GameModalScaffold(
        size: GameModalSize.compact,
        header: GameModalHeader(
          title: title,
          icon: tone == GameConfirmationTone.danger
              ? Icons.warning_amber_rounded
              : Icons.help_outline_rounded,
          onClose: () => Navigator.of(dialogContext).pop(false),
        ),
        content: Text(message),
        actions: [
          GameModalAction(
            label: cancelLabel ?? l10n.selectionActionCancel,
            variant: EpicButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          GameModalAction(
            label: confirmLabel ?? l10n.selectionActionConfirm,
            variant: EpicButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
