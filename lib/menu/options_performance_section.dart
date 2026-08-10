import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionsPerformanceSection extends ConsumerWidget {
  const OptionsPerformanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(performanceSettingsProvider);
    final controller = ref.read(performanceSettingsProvider.notifier);
    return SettingsSection(
      icon: Icons.speed_outlined,
      title: l10n.performanceSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsToggleRow(
            key: const Key('options.showFps'),
            icon: Icons.monitor_heart_outlined,
            label: l10n.showFpsLabel,
            value: settings.showFps,
            onChanged: ref.withMenuClickValue(controller.setShowFps),
          ),
          const SizedBox(height: 8),
          SettingsToggleRow(
            key: const Key('options.showMapZoom'),
            icon: Icons.zoom_in_map_outlined,
            label: l10n.showMapZoomLabel,
            value: settings.showMapZoom,
            onChanged: ref.withMenuClickValue(controller.setShowMapZoom),
          ),
        ],
      ),
    );
  }
}
