import 'package:flutter/material.dart';

typedef HudOverlayPanelBuilder =
    Widget Function(BuildContext context, double maxHeight);

class HudOverlayPanelSlot extends StatelessWidget {
  const HudOverlayPanelSlot({
    required this.padding,
    required this.builder,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final HudOverlayPanelBuilder builder;

  static const double mobileSheetWidthBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final useMobileSheet =
        alignment == Alignment.topCenter &&
        size.width < mobileSheetWidthBreakpoint &&
        size.height >= size.width;

    return SafeArea(
      child: Padding(
        padding: padding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panel = builder(context, constraints.maxHeight);
            final child = useMobileSheet && constraints.hasBoundedWidth
                ? SizedBox(
                    key: const Key('hudOverlayPanelSlot.mobileSheet'),
                    width: constraints.maxWidth,
                    child: panel,
                  )
                : panel;

            return Align(
              alignment: useMobileSheet ? Alignment.bottomCenter : alignment,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
