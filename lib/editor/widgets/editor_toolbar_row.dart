import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EditorToolbarRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const EditorToolbarRow({
    required this.label,
    required this.icon,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: GameUiTheme.sectionLabel),
                const SizedBox(width: 4),
                Text(label, style: GameUiTheme.toolbarLabel),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
