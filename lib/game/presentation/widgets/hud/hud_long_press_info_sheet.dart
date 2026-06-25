import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

Future<void> showHudLongPressInfoSheet({
  required BuildContext context,
  required GameIconData icon,
  required String title,
  required String body,
  required Color accent,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showGameBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return _HudLongPressInfoSheet(
        icon: icon,
        title: title,
        body: body,
        accent: accent,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                onAction();
              },
      );
    },
  );
}

class _HudLongPressInfoSheet extends StatelessWidget {
  final GameIconData icon;
  final String title;
  final String body;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HudLongPressInfoSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: GameModalScaffold(
        shape: GameModalShape.bottomSheet,
        showCornerDiamonds: false,
        contentPadding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: SurfaceElevation.floating.decoration(
                    accent: accent,
                    background: accent,
                    backgroundAlpha: 30,
                    border: BorderEmphasis.regular,
                    shape: SurfaceShape.button,
                    includeShadow: false,
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: GameIcon(
                        icon,
                        color: accent,
                        size: GameIconSize.regular,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameUiEpicHeader(
                        label: title,
                        alignment: Alignment.centerLeft,
                        accent: accent,
                        compact: false,
                        textKey: const Key('hudLongPressInfoSheet.title'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: GameUiTheme.body.copyWith(
                          color: GameUiTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.closeAction,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const GameIcon(
                    GameIcons.close,
                    size: GameIconSize.small,
                    color: GameUiTheme.gold,
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onAction,
                  style: GameUiTheme.textButtonStyle(
                    foreground: GameUiTheme.goldLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
