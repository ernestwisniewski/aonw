import 'dart:async';

import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/providers/display_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GraphicsSettingsSection extends ConsumerWidget {
  const GraphicsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.read(gameWindowProvider).supportsWindowModes) {
      return const SizedBox.shrink();
    }
    final settings = ref.watch(displaySettingsProvider);
    final controller = ref.read(displaySettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          icon: Icons.desktop_windows_outlined,
          title: context.l10n.graphicsSectionTitle,
          child: SettingsToggleRow(
            key: const Key('options.windowedMode'),
            icon: Icons.web_asset_outlined,
            label: context.l10n.windowedModeLabel,
            value: settings.windowed,
            onChanged: (windowed) {
              ref.playMenuClick();
              unawaited(controller.setWindowed(windowed));
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
