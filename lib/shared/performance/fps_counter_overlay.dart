import 'dart:async';

import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FpsCounterOverlay extends StatefulWidget {
  const FpsCounterOverlay({
    this.showFps = true,
    this.showMapZoom = false,
    this.mapZoom,
    super.key,
  });

  final bool showFps;
  final bool showMapZoom;
  final double? mapZoom;

  @override
  State<FpsCounterOverlay> createState() => _FpsCounterOverlayState();
}

class _FpsCounterOverlayState extends State<FpsCounterOverlay>
    with SingleTickerProviderStateMixin {
  static const _sampleWindow = Duration(milliseconds: 500);

  late final Ticker _ticker;
  Duration _lastSample = Duration.zero;
  int _frames = 0;
  double _fps = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _frames += 1;
    final sampleDuration = elapsed - _lastSample;
    if (sampleDuration < _sampleWindow) return;

    final seconds =
        sampleDuration.inMicroseconds / Duration.microsecondsPerSecond;
    setState(() {
      _fps = seconds <= 0 ? 0 : _frames / seconds;
    });
    _frames = 0;
    _lastSample = elapsed;
  }

  @override
  Widget build(BuildContext context) {
    final showZoom = widget.showMapZoom && widget.mapZoom != null;
    final labels = <String>[
      if (widget.showFps) '${_fps.round().clamp(0, 999)} FPS',
      if (showZoom) '${widget.mapZoom!.toStringAsFixed(2)}Z',
    ];
    if (labels.isEmpty) return const SizedBox.shrink();

    final maxWidth = switch (labels.length) {
      1 when widget.showFps => 72.0,
      1 => 82.0,
      _ => 138.0,
    };

    return RepaintBoundary(
      child: DecoratedBox(
        key: const Key('performance.fpsCounter'),
        decoration: BoxDecoration(
          color: GameUiTheme.bg.withAlpha(218),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: GameUiTheme.gold.withAlpha(130)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 72, maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              labels.join(' · '),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.goldLight,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
