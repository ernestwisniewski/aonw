import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/screen/game_loading_painters.dart';
import 'package:aonw/game/presentation/widgets/screen/game_loading_progress.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
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
      child: LayoutBuilder(builder: _buildLayout),
    );
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    final compact = constraints.maxWidth < 380 || constraints.maxHeight < 560;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            key: const Key('gameLoading.mapBackdrop'),
            painter: GameLoadingMapBackdropPainter(compact: compact),
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
                constraints: BoxConstraints(maxWidth: compact ? 330 : 430),
                child: _GameLoadingFrame(
                  compact: compact,
                  child: _GameLoadingContent(
                    compact: compact,
                    progress: progress,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameLoadingContent extends StatelessWidget {
  const _GameLoadingContent({required this.compact, required this.progress});

  final bool compact;
  final GameLoadingProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GameLoadingEmblem(size: compact ? 88 : 116),
        SizedBox(height: compact ? 16 : 20),
        _GameLoadingTitle(title: l10n.gameLoadingTitle, compact: compact),
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
        _GameLoadingProgressIndicator(progress: progress),
      ],
    );
  }
}

class _GameLoadingTitle extends StatelessWidget {
  const _GameLoadingTitle({required this.title, required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
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
          Shadow(color: GameUiTheme.copper.withAlpha(125), blurRadius: 20),
        ],
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
                    painter: GameLoadingPanelTexturePainter(compact: compact),
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
            painter: const GameLoadingCompassPainter(),
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

class _GameLoadingProgressIndicator extends StatelessWidget {
  const _GameLoadingProgressIndicator({required this.progress});

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
