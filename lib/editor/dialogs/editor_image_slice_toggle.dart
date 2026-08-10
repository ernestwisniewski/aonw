import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class EditorImageSliceToggle extends StatelessWidget {
  const EditorImageSliceToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (nextValue) => onChanged(nextValue ?? false),
          side: const BorderSide(color: GameUiTheme.textSecondary),
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? GameUiTheme.textPrimary
                : Colors.transparent,
          ),
          checkColor: GameUiTheme.bg,
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: const Text(
            'Slice image',
            style: TextStyle(color: GameUiTheme.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

String editorImageFileName(String path) {
  return path.split(RegExp(r'[\\/]')).last;
}
