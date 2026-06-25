import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class SelectionEmptyMessage extends StatelessWidget {
  const SelectionEmptyMessage({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: GameUiTheme.bodySmall));
  }
}
