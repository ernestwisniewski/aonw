import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/presentation/widgets/theme/player_color_theme.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class HotSeatHandoffOverlay extends StatelessWidget {
  final HandoffData handoff;
  final VoidCallback onConfirm;

  const HotSeatHandoffOverlay({
    required this.handoff,
    required this.onConfirm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final playerColor = PlayerColorTheme.resolve(handoff.playerColorValue);
    final initial = handoff.playerName.isNotEmpty
        ? GameText.uppercase(handoff.playerName[0])
        : '?';

    return Material(
      color: const Color(0xEE0a0e1a),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: ShapeDecoration(
                color: playerColor,
                shape: CircleBorder(
                  side: BorderSide(
                    color: Color.lerp(playerColor, Colors.white, 0.45)!,
                    width: 3,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: SurfaceElevation.flat.fill(
                      background: playerColor,
                      alpha: 160,
                    ),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              GameText.uppercase(handoff.playerName),
              style: const TextStyle(
                color: GameUiTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              GameText.sectionLabel(l10n.turnLabel(handoff.turnNumber)),
              style: GameUiTheme.bodySmall,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: GameUiTheme.primaryButtonStyle(),
                child: Text(GameText.actionLabel(l10n.continueAction)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
