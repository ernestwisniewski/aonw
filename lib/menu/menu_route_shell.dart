import 'dart:math' as math;

import 'package:aonw/menu/menu_animated_background.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_canvas_shapes.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class MenuRouteBackdrop extends StatelessWidget {
  const MenuRouteBackdrop({
    required this.child,
    this.maxContentWidth = 1120,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final double maxContentWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return MenuAnimatedBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _MenuRouteBackdropTint()),
          const Positioned.fill(
            child: CustomPaint(painter: _MenuRouteCartographyPainter()),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.min(constraints.maxWidth, maxContentWidth);
              return Align(
                alignment: alignment,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MenuRouteSection extends StatelessWidget {
  const MenuRouteSection({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(14, 13, 14, 14),
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.raised.decoration(
        gradient: GameUiTheme.panelSurfaceGradient(),
        borderColor: GameUiTheme.gold,
        borderAlpha: 120,
        radius: GameUiTheme.radiusCard,
        boxShadow: [
          BoxShadow(
            color: GameUiTheme.bg.withAlpha(165),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(color: GameUiTheme.copper.withAlpha(22), blurRadius: 34),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameUiEpicHeader(
              label: title,
              compact: false,
              leading: icon == null
                  ? null
                  : Icon(icon, size: 18, color: GameUiTheme.goldLight),
              trailing: trailing,
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class MenuActionBar extends StatelessWidget {
  const MenuActionBar({
    this.summary,
    this.primaryLabel,
    this.primaryKey,
    this.primaryIcon,
    this.primaryBusy = false,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryKey,
    this.secondaryIcon,
    this.onSecondary,
    super.key,
  });

  final Widget? summary;
  final String? primaryLabel;
  final Key? primaryKey;
  final IconData? primaryIcon;
  final bool primaryBusy;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasPrimary = primaryLabel != null;
    final hasSecondary = secondaryLabel != null;
    if (!hasPrimary && !hasSecondary && summary == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(248),
        border: Border(
          top: BorderSide(color: GameUiTheme.gold.withAlpha(90), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final actions = _MenuActionButtons(
                compact: compact,
                primaryLabel: primaryLabel,
                primaryKey: primaryKey,
                primaryIcon: primaryBusy
                    ? Icons.hourglass_top_rounded
                    : primaryIcon,
                primaryBusy: primaryBusy,
                onPrimary: primaryBusy ? null : onPrimary,
                secondaryLabel: secondaryLabel,
                secondaryKey: secondaryKey,
                secondaryIcon: secondaryIcon,
                onSecondary: primaryBusy ? null : onSecondary,
              );

              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (summary != null) ...[
                      summary!,
                      const SizedBox(height: 10),
                    ],
                    actions,
                  ],
                );
              }

              return Row(
                children: [
                  if (summary != null) ...[
                    Expanded(child: summary!),
                    const SizedBox(width: 16),
                  ] else
                    const Spacer(),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuActionButtons extends StatelessWidget {
  const _MenuActionButtons({
    required this.compact,
    required this.primaryLabel,
    required this.primaryKey,
    required this.primaryIcon,
    required this.primaryBusy,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryKey,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final bool compact;
  final String? primaryLabel;
  final Key? primaryKey;
  final IconData? primaryIcon;
  final bool primaryBusy;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final primary = primaryLabel == null
        ? null
        : EpicButton.primary(
            key: primaryKey,
            onPressed: onPrimary,
            icon: primaryIcon,
            label: primaryLabel!,
            minWidth: compact ? null : 176,
          );
    final secondary = secondaryLabel == null
        ? null
        : EpicButton.outlined(
            key: secondaryKey,
            onPressed: onSecondary,
            icon: secondaryIcon,
            label: secondaryLabel!,
            minWidth: compact ? null : 132,
          );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (primary != null) SizedBox(width: double.infinity, child: primary),
          if (primary != null && secondary != null) const SizedBox(height: 8),
          if (secondary != null)
            SizedBox(width: double.infinity, child: secondary),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?secondary,
        if (primary != null && secondary != null) const SizedBox(width: 10),
        ?primary,
      ],
    );
  }
}

class MenuMetricPill extends StatelessWidget {
  const MenuMetricPill({
    required this.icon,
    required this.label,
    this.color = GameUiTheme.gold,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(142),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusPill),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.chipLabel.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRouteBackdropTint extends StatelessWidget {
  const _MenuRouteBackdropTint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameUiTheme.bg.withAlpha(238),
            GameUiTheme.surfaceDeep.withAlpha(216),
            GameUiTheme.bg.withAlpha(178),
            GameUiTheme.bg.withAlpha(230),
          ],
          stops: const [0, 0.34, 0.67, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.72, -0.62),
            radius: 1.05,
            colors: [
              GameUiTheme.gold.withAlpha(52),
              Colors.transparent,
              GameUiTheme.bg.withAlpha(180),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

class _MenuRouteCartographyPainter extends CustomPainter {
  const _MenuRouteCartographyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = GameUiTheme.goldDark.withAlpha(34);
    final coast = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = GameUiTheme.copper.withAlpha(56);
    final cell = size.shortestSide < 520 ? 46.0 : 58.0;
    final rowHeight = cell * 0.86;

    for (var y = -rowHeight; y < size.height + rowHeight; y += rowHeight) {
      final row = (y / rowHeight).round();
      for (var x = -cell; x < size.width + cell; x += cell) {
        final cx = x + (row.isOdd ? cell * 0.5 : 0);
        final cy = y;
        if ((row + (x / cell).round()) % 3 == 0) {
          canvas.drawPath(
            HudCanvasShapes.hexOutlinePath(Offset(cx, cy), cell * 0.47),
            stroke,
          );
        }
      }
    }

    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.54,
        size.width * 0.42,
        size.height * 0.92,
        size.width * 0.58,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.18,
        size.width * 0.86,
        size.height * 0.36,
        size.width * 0.96,
        size.height * 0.12,
      );
    canvas.drawPath(route, coast);

    final horizon = Paint()
      ..shader = LinearGradient(
        colors: [
          GameUiTheme.gold.withAlpha(0),
          GameUiTheme.gold.withAlpha(72),
          GameUiTheme.gold.withAlpha(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas
      ..drawRect(Rect.fromLTWH(0, size.height * 0.18, size.width, 1), horizon)
      ..drawRect(Rect.fromLTWH(0, size.height * 0.82, size.width, 1), horizon);
  }

  @override
  bool shouldRepaint(covariant _MenuRouteCartographyPainter oldDelegate) =>
      false;
}
