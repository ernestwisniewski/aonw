import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EditorActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const EditorActionButton(this.label, this.onPressed, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: GameUiTheme.textSecondary,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: GameUiTheme.actionLabel,
      ),
      child: Text(label),
    );
  }
}
