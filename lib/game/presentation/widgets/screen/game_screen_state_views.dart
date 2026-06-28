import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/screen/game_loading_progress.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_canvas_shapes.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/material.dart';

class GameLoadingView extends StatelessWidget {
  const GameLoadingView({this.progress, super.key});

  final GameLoadingProgress? progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: GameLoadingPanel(progress: progress),
    );
  }
}

class GameLoadingPanel extends StatelessWidget {
  const GameLoadingPanel({this.progress, super.key});

  final GameLoadingProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameUiTheme.surfaceDeep.withAlpha(245),
            GameUiTheme.bg,
            GameUiTheme.surface.withAlpha(235),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 380 || constraints.maxHeight < 560;
          final emblemSize = compact ? 88.0 : 116.0;
          final panelMaxWidth = compact ? 330.0 : 430.0;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('gameLoading.mapBackdrop'),
                  painter: _GameLoadingMapBackdropPainter(compact: compact),
                ),
              ),
              const Positioned.fill(child: _GameLoadingVignette()),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 18 : 28,
                      vertical: compact ? 18 : 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: panelMaxWidth),
                      child: _GameLoadingFrame(
                        compact: compact,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GameLoadingEmblem(size: emblemSize),
                            SizedBox(height: compact ? 16 : 20),
                            Text(
                              l10n.gameLoadingTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GameUiTheme.goldLight,
                                fontFamily: GameUiTheme.headingFont,
                                fontSize: compact ? 22 : 28,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                                height: 1.05,
                                shadows: [
                                  Shadow(
                                    color: GameUiTheme.bg.withAlpha(240),
                                    blurRadius: 0,
                                    offset: const Offset(0, 1),
                                  ),
                                  Shadow(
                                    color: GameUiTheme.copper.withAlpha(125),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _GameLoadingRule(compact: compact),
                            const SizedBox(height: 12),
                            Text(
                              l10n.gameLoadingMessage,
                              textAlign: TextAlign.center,
                              style: GameUiTheme.bodySmall.copyWith(
                                color: GameUiTheme.textSecondary.withAlpha(230),
                                height: 1.38,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: compact ? 22 : 28),
                            _GameLoadingProgress(progress: progress),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GameLoadingFrame extends StatelessWidget {
  const _GameLoadingFrame({required this.compact, required this.child});

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    return DecoratedBox(
      key: const Key('gameLoading.frame'),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: GameUiTheme.panelSurfaceGradient(),
        border: Border.all(color: GameUiTheme.gold.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: GameUiTheme.bg.withAlpha(220),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
          BoxShadow(color: GameUiTheme.copper.withAlpha(42), blurRadius: 46),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameUiTheme.copperDeep.withAlpha(120)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GameLoadingPanelTexturePainter(compact: compact),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 22 : 28,
                    compact ? 24 : 30,
                    compact ? 22 : 28,
                    compact ? 24 : 30,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameLoadingEmblem extends StatelessWidget {
  const _GameLoadingEmblem({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const Key('gameLoading.emblem'),
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: const _GameLoadingCompassPainter(),
          ),
          GameIcon(
            GameIcons.hourglass,
            size: size < 100 ? GameIconSize.large : GameIconSize.hero,
            color: GameUiTheme.goldLight,
          ),
        ],
      ),
    );
  }
}

class _GameLoadingRule extends StatelessWidget {
  const _GameLoadingRule({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final diamond = Transform.rotate(
      angle: math.pi / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: GameUiTheme.goldLight.withAlpha(205),
          boxShadow: [
            BoxShadow(color: GameUiTheme.copper.withAlpha(85), blurRadius: 10),
          ],
        ),
        child: SizedBox.square(dimension: compact ? 5 : 6),
      ),
    );
    return Row(
      children: [
        const Expanded(child: _GameLoadingLine(alignRight: true)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12),
          child: diamond,
        ),
        const Expanded(child: _GameLoadingLine(alignRight: false)),
      ],
    );
  }
}

class _GameLoadingLine extends StatelessWidget {
  const _GameLoadingLine({required this.alignRight});

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignRight ? Alignment.centerLeft : Alignment.centerRight,
          end: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            GameUiTheme.gold.withAlpha(0),
            GameUiTheme.gold.withAlpha(155),
          ],
        ),
      ),
      child: const SizedBox(height: 1.2),
    );
  }
}

class _GameLoadingProgress extends StatelessWidget {
  const _GameLoadingProgress({required this.progress});

  final GameLoadingProgress? progress;

  @override
  Widget build(BuildContext context) {
    final value = progress?.value;
    final percent = value == null ? null : (value * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: DecoratedBox(
            key: const Key('gameLoading.progressFrame'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: GameUiTheme.gold.withAlpha(135)),
              color: GameUiTheme.bg.withAlpha(132),
              boxShadow: [
                BoxShadow(
                  color: GameUiTheme.copper.withAlpha(55),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  color: GameUiTheme.goldLight,
                  backgroundColor: GameUiTheme.chipSurface,
                ),
              ),
            ),
          ),
        ),
        if (percent != null) ...[
          const SizedBox(height: 8),
          Text(
            '$percent%',
            key: const Key('gameLoading.progressPercent'),
            style: GameUiTheme.labelSmall.copyWith(
              color: GameUiTheme.goldLight.withAlpha(220),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

class _GameLoadingVignette extends StatelessWidget {
  const _GameLoadingVignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.02,
          colors: [
            Colors.transparent,
            GameUiTheme.bg.withAlpha(70),
            GameUiTheme.bg.withAlpha(190),
          ],
          stops: const [0.46, 0.74, 1.0],
        ),
      ),
    );
  }
}

class _GameLoadingMapBackdropPainter extends CustomPainter {
  const _GameLoadingMapBackdropPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = compact ? 44.0 : 58.0;
    final hexHeight = cell * 0.86;
    final rows = (size.height / hexHeight).ceil() + 3;
    final cols = (size.width / cell).ceil() + 3;
    final offsetX = -cell * 0.65;
    final offsetY = -hexHeight;

    final waterPaint = Paint()
      ..color = GameUiTheme.info.withAlpha(22)
      ..style = PaintingStyle.fill;
    final landPaint = Paint()
      ..color = GameUiTheme.successDim.withAlpha(34)
      ..style = PaintingStyle.fill;
    final coastPaint = Paint()
      ..color = GameUiTheme.gold.withAlpha(28)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = GameUiTheme.goldDark.withAlpha(58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final center = Offset(
          offsetX + col * cell + (row.isOdd ? cell * 0.5 : 0),
          offsetY + row * hexHeight,
        );
        final value = (col * 11 + row * 7 + (col - row).abs() * 3) % 17;
        final paint = value < 5
            ? waterPaint
            : value < 11
            ? landPaint
            : coastPaint;
        final path = HudCanvasShapes.hexOutlinePath(center, cell * 0.48);
        canvas
          ..drawPath(path, paint)
          ..drawPath(path, strokePaint);
      }
    }

    final routePaint = Paint()
      ..color = GameUiTheme.copper.withAlpha(72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.1 : 1.35
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.55,
        size.width * 0.38,
        size.height * 0.82,
        size.width * 0.55,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.39,
        size.width * 0.84,
        size.height * 0.47,
        size.width * 0.94,
        size.height * 0.25,
      );
    canvas.drawPath(route, routePaint);

    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          GameUiTheme.gold.withAlpha(0),
          GameUiTheme.gold.withAlpha(64),
          GameUiTheme.gold.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.18, size.width, 1),
        horizonPaint,
      )
      ..drawRect(
        Rect.fromLTWH(0, size.height * 0.82, size.width, 1),
        horizonPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _GameLoadingMapBackdropPainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _GameLoadingPanelTexturePainter extends CustomPainter {
  const _GameLoadingPanelTexturePainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = GameUiTheme.goldDark.withAlpha(compact ? 22 : 26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final step = compact ? 22.0 : 26.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameUiTheme.gold.withAlpha(36),
          Colors.transparent,
          GameUiTheme.copperDeep.withAlpha(24),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, topPaint);
  }

  @override
  bool shouldRepaint(covariant _GameLoadingPanelTexturePainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _GameLoadingCompassPainter extends CustomPainter {
  const _GameLoadingCompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final glowPaint = Paint()
      ..color = GameUiTheme.copper.withAlpha(72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    final ringPaint = Paint()
      ..color = GameUiTheme.gold.withAlpha(185)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.025;
    final finePaint = Paint()
      ..color = GameUiTheme.goldLight.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.014;
    final fillPaint = Paint()
      ..color = GameUiTheme.bg.withAlpha(142)
      ..style = PaintingStyle.fill;

    canvas
      ..drawCircle(center, radius * 0.43, fillPaint)
      ..drawCircle(center, radius * 0.44, glowPaint)
      ..drawCircle(center, radius * 0.44, ringPaint)
      ..drawCircle(center, radius * 0.32, finePaint);

    final rosePaint = Paint()
      ..color = GameUiTheme.gold.withAlpha(135)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.018
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final start = Offset(
        center.dx + math.cos(angle) * radius * 0.18,
        center.dy + math.sin(angle) * radius * 0.18,
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius * (i.isEven ? 0.64 : 0.52),
        center.dy + math.sin(angle) * radius * (i.isEven ? 0.64 : 0.52),
      );
      canvas.drawLine(start, end, rosePaint);
    }

    final diamondPaint = Paint()
      ..color = GameUiTheme.goldLight.withAlpha(175)
      ..style = PaintingStyle.fill;
    for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
      final point = Offset(
        center.dx + math.cos(angle) * radius * 0.72,
        center.dy + math.sin(angle) * radius * 0.72,
      );
      canvas.drawPath(_diamond(point, radius * 0.035), diamondPaint);
    }
  }

  Path _diamond(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _GameLoadingCompassPainter oldDelegate) => false;
}

class GameLoadErrorView extends StatelessWidget {
  final String mapName;
  final Object error;
  final VoidCallback onBack;

  const GameLoadErrorView({
    required this.mapName,
    required this.error,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: GameUiEmptyState(
        iconWidget: const GameIcon(
          GameIcons.error,
          size: GameIconSize.hero,
          color: GameUiTheme.goldLight,
        ),
        title: l10n.gameLoadMapErrorTitle,
        message: l10n.gameLoadMapErrorMessage(mapName, error.toString()),
        action: OutlinedButton.icon(
          onPressed: onBack,
          icon: const GameIcon(
            GameIcons.back,
            size: GameIconSize.small,
            color: GameUiTheme.goldLight,
          ),
          label: Text(GameText.actionLabel(l10n.backAction)),
          style: GameUiTheme.outlinedButtonStyle(
            foreground: GameUiTheme.goldLight,
          ),
        ),
      ),
    );
  }
}
