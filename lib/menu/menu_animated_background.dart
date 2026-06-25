import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class MenuAnimatedBackground extends StatefulWidget {
  const MenuAnimatedBackground({
    required this.child,
    this.assetPath = 'assets/main_menu/background.png',
    this.duration = const Duration(seconds: 56),
    super.key,
  });

  final Widget child;
  final String assetPath;
  final Duration duration;

  @override
  State<MenuAnimatedBackground> createState() => _MenuAnimatedBackgroundState();
}

class _MenuAnimatedBackgroundState extends State<MenuAnimatedBackground>
    with SingleTickerProviderStateMixin {
  static const _sourceAspectRatio = 1536 / 1024;
  static const _desktopBaseScale = 1.08;
  static const _desktopPulseScale = 0.012;
  static const _compactBaseScale = 1.04;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant MenuAnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    if (_motionEnabled) {
      if (!_controller.isAnimating) unawaited(_controller.repeat());
      return;
    }
    if (_controller.isAnimating) _controller.stop();
  }

  bool get _motionEnabled {
    final mediaQuery = MediaQuery.maybeOf(context);
    return TickerMode.valuesOf(context).enabled &&
        !(mediaQuery?.disableAnimations ?? false) &&
        !_isRunningWidgetTest;
  }

  @override
  Widget build(BuildContext context) {
    final motionEnabled = _motionEnabled;
    return ColoredBox(
      color: GameUiTheme.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.max(1.0, constraints.maxWidth);
                  final height = math.max(1.0, constraints.maxHeight);
                  final viewportAspect = width / height;
                  final coverWidth = viewportAspect > _sourceAspectRatio
                      ? width
                      : height * _sourceAspectRatio;
                  final coverHeight = viewportAspect > _sourceAspectRatio
                      ? width / _sourceAspectRatio
                      : height;
                  final travelX = (width * 0.028).clamp(12.0, 42.0).toDouble();
                  final travelY = (height * 0.026).clamp(10.0, 36.0).toDouble();
                  final horizontalOverhang = (travelX + width * 0.035)
                      .clamp(56.0, 160.0)
                      .toDouble();
                  final verticalOverhang = (travelY + height * 0.04)
                      .clamp(64.0, 180.0)
                      .toDouble();
                  final desktopScaleMotion = width >= 900 && height >= 620;
                  final image = Image.asset(
                    widget.assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.high,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        widget.assetPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        filterQuality: FilterQuality.high,
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        child: SizedBox(
                          width: coverWidth + horizontalOverhang * 2,
                          height: coverHeight + verticalOverhang * 2,
                          child: image,
                        ),
                        builder: (context, child) {
                          final phase = _controller.value * math.pi * 2;
                          final offset = motionEnabled
                              ? Offset(
                                  math.sin(phase) * travelX,
                                  math.sin(phase * 0.82) * travelY,
                                )
                              : Offset.zero;
                          final baseScale = desktopScaleMotion
                              ? _desktopBaseScale
                              : _compactBaseScale;
                          final scale =
                              baseScale +
                              (motionEnabled && desktopScaleMotion
                                  ? math.sin(phase * 0.5) * _desktopPulseScale
                                  : 0);
                          return Center(
                            child: Transform.translate(
                              offset: offset,
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

bool get _isRunningWidgetTest {
  var result = false;
  assert(() {
    result = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    return true;
  }());
  return result;
}
