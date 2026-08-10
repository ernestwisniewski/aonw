import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/options_value_slider.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw/shared/providers/audio_settings_provider.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionsAudioSection extends ConsumerWidget {
  const OptionsAudioSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(gameAudioSettingsProvider);
    final controller = ref.read(gameAudioSettingsProvider.notifier);
    return SettingsSection(
      icon: Icons.volume_up_outlined,
      title: l10n.audioSectionTitle,
      child: Column(
        children: [
          SettingsToggleRow(
            icon: Icons.graphic_eq_rounded,
            label: l10n.gameSoundsLabel,
            value: settings.soundsEnabled,
            onChanged: ref.withMenuClickValue(controller.setSoundsEnabled),
          ),
          if (settings.soundsEnabled)
            OptionsValueSlider(
              key: const Key('options.soundVolume'),
              label: l10n.soundVolumeLabel,
              value: settings.soundVolume,
              onChanged: controller.setSoundVolume,
            ),
          const SizedBox(height: 8),
          SettingsToggleRow(
            icon: Icons.music_note_outlined,
            label: l10n.gameMusicLabel,
            value: settings.musicEnabled,
            onChanged: ref.withMenuClickValue(controller.setMusicEnabled),
          ),
          if (settings.musicEnabled)
            OptionsValueSlider(
              key: const Key('options.musicVolume'),
              label: l10n.musicVolumeLabel,
              value: settings.musicVolume,
              onChanged: controller.setMusicVolume,
            ),
          const SizedBox(height: 8),
          SettingsToggleRow(
            icon: Icons.forest_outlined,
            label: l10n.natureSoundsLabel,
            value: settings.natureEnabled,
            onChanged: ref.withMenuClickValue(controller.setNatureEnabled),
          ),
          if (settings.natureEnabled)
            OptionsValueSlider(
              key: const Key('options.natureVolume'),
              label: l10n.natureVolumeLabel,
              value: settings.natureVolume,
              onChanged: controller.setNatureVolume,
            ),
        ],
      ),
    );
  }
}

class OptionsAiSection extends ConsumerWidget {
  const OptionsAiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(aiSettingsProvider);
    final controller = ref.read(aiSettingsProvider.notifier);
    return SettingsSection(
      icon: Icons.memory_outlined,
      title: l10n.aiSectionTitle,
      child: SettingsToggleRow(
        key: const Key('options.aiBatterySaver'),
        icon: Icons.battery_saver_outlined,
        label: l10n.aiBatterySaverLabel,
        value: settings.batterySaver,
        onChanged: ref.withMenuClickValue(controller.setBatterySaver),
      ),
    );
  }
}

class OptionsGameplaySection extends ConsumerWidget {
  const OptionsGameplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(gameplaySettingsProvider);
    final controller = ref.read(gameplaySettingsProvider.notifier);
    return SettingsSection(
      icon: Icons.videocam_outlined,
      title: l10n.gameplaySectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsToggleRow(
            key: const Key('options.followUnitMovementCamera'),
            icon: Icons.center_focus_strong_outlined,
            label: l10n.followUnitMovementCameraLabel,
            value: settings.followUnitMovementCamera,
            onChanged: ref.withMenuClickValue(
              controller.setFollowUnitMovementCamera,
            ),
          ),
          const SizedBox(height: 8),
          SettingsToggleRow(
            key: const Key('options.followEnemyUnitCamera'),
            icon: Icons.crisis_alert_outlined,
            label: l10n.followEnemyUnitCameraLabel,
            value: settings.followEnemyUnitCamera,
            onChanged: ref.withMenuClickValue(
              controller.setFollowEnemyUnitCamera,
            ),
          ),
          const SizedBox(height: 8),
          SettingsToggleRow(
            key: const Key('options.cinematicCamera'),
            icon: Icons.movie_filter_outlined,
            label: l10n.cinematicCameraLabel,
            value: settings.cinematicCameraEnabled,
            onChanged: ref.withMenuClickValue(
              controller.setCinematicCameraEnabled,
            ),
          ),
        ],
      ),
    );
  }
}
