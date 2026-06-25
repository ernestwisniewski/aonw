import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:flutter/material.dart';

class EpicCardSurface extends StatelessWidget {
  const EpicCardSurface({
    super.key,
    this.header,
    required this.content,
    this.showCornerDiamonds = true,
    this.onClose,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.surfaceKey,
  });

  final Widget? header;
  final Widget content;
  final bool showCornerDiamonds;
  final VoidCallback? onClose;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final Key? surfaceKey;

  static const double _diamondMinWidth = 360;
  static const double _headerHeight = 52;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = width ?? constraints.maxWidth;
        final allowDiamonds =
            showCornerDiamonds && effectiveWidth >= _diamondMinWidth;
        final contentSlot = Padding(padding: padding, child: content);

        return SizedBox(
          width: width,
          height: height,
          child: _OuterFrame(
            surfaceKey: surfaceKey,
            child: _InnerFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (header != null)
                    _Header(
                      header: header!,
                      onClose: onClose,
                      showDiamonds: allowDiamonds,
                    ),
                  if (constraints.hasBoundedHeight)
                    Flexible(child: contentSlot)
                  else
                    contentSlot,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OuterFrame extends StatelessWidget {
  const _OuterFrame({required this.child, this.surfaceKey});

  final Widget child;
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: surfaceKey,
      decoration: SurfaceElevation.raised.decoration(
        gradient: GameUiTheme.panelSurfaceGradient(),
        borderColor: GameUiTheme.gold,
        borderAlpha: 170,
        radius: GameUiTheme.radiusCard,
        boxShadow: [
          const BoxShadow(
            color: Color(0xB4000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: SurfaceElevation.flat.fill(
              background: GameUiTheme.copper,
              alpha: 30,
            ),
            blurRadius: 40,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InnerFrame extends StatelessWidget {
  const _InnerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameUiTheme.radiusCard - 2),
            side: BorderSide(
              color: SurfaceElevation.flat.strokeColor(
                color: GameUiTheme.copperDeep,
                alpha: 110,
              ),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GameUiTheme.radiusCard - 2),
          child: child,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.header,
    required this.showDiamonds,
    this.onClose,
  });

  final Widget header;
  final bool showDiamonds;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: EpicCardSurface._headerHeight,
          decoration: const ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GameUiTheme.surfaceDeep, GameUiTheme.surface],
            ),
            shape: RoundedRectangleBorder(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (showDiamonds) _diamond('epic-card-corner-diamond-left'),
              if (showDiamonds) const SizedBox(width: 10),
              Expanded(child: header),
              if (onClose != null)
                IconButton(
                  key: const ValueKey('epic-card-close'),
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  color: GameUiTheme.goldLight,
                  hoverColor: SurfaceElevation.flat.fill(
                    background: GameUiTheme.copper,
                    alpha: 60,
                  ),
                ),
              if (showDiamonds) const SizedBox(width: 6),
              if (showDiamonds) _diamond('epic-card-corner-diamond-right'),
            ],
          ),
        ),
        const GoldDivider(),
      ],
    );
  }

  Widget _diamond(String key) {
    return Transform.rotate(
      key: ValueKey(key),
      angle: 0.785398,
      child: Container(width: 4, height: 4, color: GameUiTheme.gold),
    );
  }
}
