import 'dart:async';

import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class PulsingResourcePillSurface extends StatefulWidget {
  const PulsingResourcePillSurface({
    required this.active,
    required this.color,
    required this.compact,
    required this.critical,
    required this.child,
    super.key,
  });

  final bool active;
  final Color color;
  final bool compact;
  final bool critical;
  final Widget child;

  @override
  State<PulsingResourcePillSurface> createState() =>
      _PulsingResourcePillSurfaceState();
}

class _PulsingResourcePillSurfaceState extends State<PulsingResourcePillSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    if (widget.critical) unawaited(_pulse.repeat(reverse: true));
  }

  @override
  void didUpdateWidget(covariant PulsingResourcePillSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.critical && !_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    } else if (!widget.critical && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.critical) return _buildSurface(0, widget.child);
    return AnimatedBuilder(
      animation: _pulse,
      child: widget.child,
      builder: (context, child) => _buildSurface(_pulse.value, child!),
    );
  }

  Widget _buildSurface(double pulse, Widget child) {
    final border = _borderStyle(pulse);
    final surface = widget.active
        ? SurfaceElevation.modal
        : SurfaceElevation.floating;
    return Container(
      height: 34,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 7 : 9),
      decoration: surface.decoration(
        accent: widget.color,
        background: widget.active ? widget.color : null,
        backgroundAlpha: widget.active ? 230 : null,
        border: border.color,
        borderAlpha: border.alpha,
        borderWidth: border.width,
        shape: SurfaceShape.pill,
      ),
      child: child,
    );
  }

  ({Color color, int alpha, double width}) _borderStyle(double pulse) {
    if (widget.critical) {
      return (
        color: GameUiTheme.danger,
        alpha: (160 + pulse * 95).round(),
        width: 1.5 + pulse * 0.7,
      );
    }
    if (widget.active) {
      return (color: GameUiTheme.goldLight, alpha: 255, width: 1.4);
    }
    return (
      color: widget.color,
      alpha: SurfaceElevation.floating.borderAlpha,
      width: 1.0,
    );
  }
}
