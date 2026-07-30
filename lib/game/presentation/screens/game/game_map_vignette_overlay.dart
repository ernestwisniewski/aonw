import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

final class GameMapVignetteOverlay extends StatelessWidget {
  const GameMapVignetteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      key: const Key('gameScreen.mapVignette'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.92,
            colors: [Colors.transparent, GameUiTheme.bg.withAlpha(120)],
            stops: const [0.68, 1.0],
          ),
        ),
      ),
    );
  }
}
