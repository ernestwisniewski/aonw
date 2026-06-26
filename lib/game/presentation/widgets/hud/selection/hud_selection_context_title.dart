import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class SelectionContextTitle extends StatelessWidget {
  const SelectionContextTitle({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameHudTheme.selectionTag.copyWith(
            color: GameUiTheme.textPrimary,
            fontSize: 12.5,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameHudTheme.selectionTag.copyWith(
              color: GameUiTheme.textSecondary,
              fontSize: 10.5,
            ),
          ),
      ],
    );
  }
}
