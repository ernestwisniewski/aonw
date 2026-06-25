import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class CompactStatusBadge extends StatelessWidget {
  const CompactStatusBadge({
    required this.status,
    required this.color,
    super.key,
  });

  final MultiplayerAvatarStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('multiplayerCompactAvatarStatus.${status.name}'),
      width: 17,
      height: 17,
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(
          background: GameUiTheme.surfaceDeep,
          alpha: 242,
        ),
        shape: CircleBorder(
          side: BorderSide(
            color: SurfaceElevation.flat.fill(
              background: color,
              alpha: BorderEmphasis.active.alpha,
            ),
            width: 1.1,
          ),
        ),
      ),
      child: Center(
        child: MultiplayerStatusIcon(
          status: status,
          color: color,
          size: GameIconSize.tiny,
        ),
      ),
    );
  }
}

class PlayerColorDot extends StatelessWidget {
  const PlayerColorDot({required this.color, required this.active, super.key});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = active ? 11.0 : 9.0;
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: CircleBorder(
          side: BorderSide(
            color: Color.lerp(color, Colors.white, active ? 0.55 : 0.25)!,
            width: active ? 1.4 : 1,
          ),
        ),
        shadows: active
            ? [
                BoxShadow(
                  color: SurfaceElevation.flat.fill(
                    background: color,
                    alpha: 150,
                  ),
                  blurRadius: 7,
                ),
              ]
            : null,
      ),
    );
  }
}

class MultiplayerStatusIcon extends StatelessWidget {
  const MultiplayerStatusIcon({
    required this.status,
    required this.color,
    this.size = GameIconSize.small,
    super.key,
  });

  final MultiplayerAvatarStatus status;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('multiplayerAvatarStatus.${status.name}'),
      width: 18,
      height: 18,
      child: Center(
        child: switch (status) {
          MultiplayerAvatarStatus.active => GameIcon(
            GameIcons.lightning,
            color: color,
            size: size,
          ),
          MultiplayerAvatarStatus.submitted => GameIcon(
            GameIcons.checkCircle,
            color: color,
            size: size,
          ),
          MultiplayerAvatarStatus.thinking => GameIcon(
            GameIcons.hourglass,
            color: color,
            size: size,
          ),
          MultiplayerAvatarStatus.waiting => Text(
            '...',
            style: GameUiTheme.bodyStrong.copyWith(
              color: color,
              fontSize: 13,
              height: 1,
            ),
          ),
          MultiplayerAvatarStatus.timeout => GameIcon(
            GameIcons.warning,
            color: color,
            size: size,
          ),
        },
      ),
    );
  }
}
