import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

class TurnStartBannerOverlay extends StatefulWidget {
  const TurnStartBannerOverlay({
    required this.turnNumber,
    this.showOnFirstBuild = false,
    this.showSignal = 0,
    this.duration = const Duration(milliseconds: 2200),
    super.key,
  });

  final int? turnNumber;
  final bool showOnFirstBuild;
  final int showSignal;
  final Duration duration;

  @override
  State<TurnStartBannerOverlay> createState() => _TurnStartBannerOverlayState();
}

class _TurnStartBannerOverlayState extends State<TurnStartBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _visibleTurnNumber;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleStatus);
    _visibleTurnNumber = widget.turnNumber;
    if (widget.showOnFirstBuild && widget.turnNumber != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _show(widget.turnNumber!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant TurnStartBannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    final turnNumber = widget.turnNumber;
    if (turnNumber == null) {
      _hide();
      return;
    }
    if (widget.showSignal != oldWidget.showSignal) {
      _show(turnNumber);
      return;
    }
    if (turnNumber == oldWidget.turnNumber) return;
    if (oldWidget.turnNumber == null && !widget.showOnFirstBuild) {
      _visibleTurnNumber = turnNumber;
      return;
    }
    _show(turnNumber);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  void _show(int turnNumber) {
    setState(() {
      _visibleTurnNumber = turnNumber;
      _visible = true;
    });
    unawaited(_controller.forward(from: 0));
  }

  void _hide() {
    _controller.stop();
    if (!_visible) return;
    setState(() => _visible = false);
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final turnNumber = _visibleTurnNumber;
    if (!_visible || turnNumber == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox.expand(
        child: SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.24),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = _controller.value;
                final opacity = _opacityFor(value);
                final offsetY = lerpDouble(10, -18, value)!;
                final scale = lerpDouble(0.94, 1.04, value)!;
                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, offsetY),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: _TurnStartBannerText(turnNumber: turnNumber),
            ),
          ),
        ),
      ),
    );
  }

  double _opacityFor(double value) {
    if (value < 0.18) return Curves.easeOutCubic.transform(value / 0.18);
    if (value < 0.68) return 1;
    return 1 - Curves.easeInCubic.transform((value - 0.68) / 0.32);
  }
}

class _TurnStartBannerText extends StatelessWidget {
  const _TurnStartBannerText({required this.turnNumber});

  final int turnNumber;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.turnLabel(turnNumber);
    final parts = _TurnStartLabelParts.from(label: label, number: turnNumber);

    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: FittedBox(
          key: const Key('gameHud.turnStartBanner.text'),
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TurnStartBannerRule(),
              const SizedBox(height: 5),
              Text(
                parts.prefix,
                key: const Key('gameHud.turnStartBanner.prefix'),
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xCCEBD9B0),
                  fontFamily: GameUiTheme.bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: Color(0xD9000000),
                      blurRadius: 9,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              _OutlinedBannerNumber(text: parts.number),
              const SizedBox(height: 6),
              const _TurnStartBannerRule(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnStartLabelParts {
  const _TurnStartLabelParts({required this.prefix, required this.number});

  final String prefix;
  final String number;

  static _TurnStartLabelParts from({
    required String label,
    required int number,
  }) {
    final numberText = number.toString();
    final prefix = label.replaceFirst(
      RegExp('\\s*${RegExp.escape(numberText)}\\s*\$'),
      '',
    );
    return _TurnStartLabelParts(
      prefix: prefix.trim().isEmpty ? label : prefix.trim(),
      number: numberText,
    );
  }
}

class _OutlinedBannerNumber extends StatelessWidget {
  const _OutlinedBannerNumber({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          key: const Key('gameHud.turnStartBanner.numberOutline'),
          maxLines: 1,
          textAlign: TextAlign.center,
          style: _numberStyle(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.7
              ..strokeJoin = StrokeJoin.round
              ..color = GameUiTheme.bg.withAlpha(230),
          ),
        ),
        Text(
          text,
          key: const Key('gameHud.turnStartBanner.numberFill'),
          maxLines: 1,
          textAlign: TextAlign.center,
          style: _numberStyle(color: GameUiTheme.goldLight),
        ),
      ],
    );
  }

  TextStyle _numberStyle({Color? color, Paint? foreground}) {
    return TextStyle(
      color: color,
      foreground: foreground,
      fontFamily: GameUiTheme.headingFont,
      fontSize: 54,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 0.92,
      fontFeatures: GameUiTheme.tabularFigures,
      shadows: [
        Shadow(
          color: GameUiTheme.bg.withAlpha(245),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
        Shadow(color: GameUiTheme.gold.withAlpha(150), blurRadius: 28),
        Shadow(color: GameUiTheme.goldLight.withAlpha(76), blurRadius: 42),
      ],
    );
  }
}

class _TurnStartBannerRule extends StatelessWidget {
  const _TurnStartBannerRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Expanded(child: _TurnStartBannerRuleLine(reverse: true)),
          const SizedBox(width: 7),
          Transform.rotate(
            angle: 0.7853981634,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GameUiTheme.goldLight.withAlpha(190),
                boxShadow: [
                  BoxShadow(
                    color: GameUiTheme.gold.withAlpha(85),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const SizedBox(width: 5, height: 5),
            ),
          ),
          const SizedBox(width: 7),
          const Expanded(child: _TurnStartBannerRuleLine()),
        ],
      ),
    );
  }
}

class _TurnStartBannerRuleLine extends StatelessWidget {
  const _TurnStartBannerRuleLine({this.reverse = false});

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
          end: reverse ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            GameUiTheme.goldLight.withAlpha(0),
            GameUiTheme.gold.withAlpha(150),
          ],
        ),
        boxShadow: [
          BoxShadow(color: GameUiTheme.bg.withAlpha(190), blurRadius: 5),
        ],
      ),
      child: const SizedBox(height: 1.2),
    );
  }
}
