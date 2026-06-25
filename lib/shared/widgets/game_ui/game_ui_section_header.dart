import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class GameUiSectionHeader extends StatelessWidget {
  final String label;

  const GameUiSectionHeader({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Text(label, style: GameUiTheme.sectionHeader),
    );
  }
}
