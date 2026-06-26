import 'package:aonw/game/presentation/widgets/hud/layout/hud_layout_metrics.dart';
import 'package:aonw/game/presentation/widgets/hud/mode_banner/hud_mode_banner.dart';
import 'package:flutter/material.dart';

class HudModeBannerSlot extends StatelessWidget {
  const HudModeBannerSlot({
    required this.layoutMetrics,
    required this.spec,
    required this.popupId,
    required this.onMinimize,
    super.key,
  });

  final HudLayoutMetrics layoutMetrics;
  final HudModeBannerSpec? spec;
  final String? popupId;
  final void Function(String popupId, HudModeBannerSpec spec) onMinimize;

  @override
  Widget build(BuildContext context) {
    final bannerSpec = spec;
    if (bannerSpec == null) return const SizedBox.shrink();

    return Positioned(
      top: layoutMetrics.panelTopPadding + 8,
      left: layoutMetrics.contextualHintLeftPadding,
      right: layoutMetrics.portraitPhone ? 12 : null,
      child: Align(
        alignment: layoutMetrics.portraitPhone
            ? Alignment.topCenter
            : Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: layoutMetrics.portraitPhone ? 460 : 380,
          ),
          child: HudModeBanner(
            spec: bannerSpec,
            compact: layoutMetrics.portraitPhone,
            onMinimize: popupId == null
                ? null
                : () => onMinimize(popupId!, bannerSpec),
          ),
        ),
      ),
    );
  }
}
