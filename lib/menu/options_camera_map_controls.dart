import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/widgets/map_view_mode_toggle.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionsMapDisplayControls extends ConsumerWidget {
  const OptionsMapDisplayControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hexDisplayDefaultsBootstrapProvider);
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreferredMapViewControl(),
        SizedBox(height: 8),
        _MapContentControls(),
        SizedBox(height: 8),
        _MapPlanningControls(),
        SizedBox(height: 8),
        _MapGeometryControls(),
      ],
    );
  }
}

class _PreferredMapViewControl extends ConsumerWidget {
  const _PreferredMapViewControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameplay = ref.watch(gameplaySettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.defaultMapViewModeLabel,
          style: GameUiTheme.bodyStrong.copyWith(
            color: GameUiTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        MapViewModeToggle(
          value: gameplay.preferredMapViewMode,
          allowGraphicMode: true,
          onChanged: ref
              .read(gameplaySettingsProvider.notifier)
              .setPreferredMapViewMode,
        ),
      ],
    );
  }
}

class _MapContentControls extends ConsumerWidget {
  const _MapContentControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(hexDisplayProvider);
    final controller = ref.read(hexDisplayProvider.notifier);
    return Column(
      children: [
        SettingsToggleRow(
          key: const Key('options.showTerrain'),
          icon: Icons.landscape_outlined,
          label: context.l10n.gameOptionTerrain,
          value: display.showTerrain,
          onChanged: ref.withMenuClickValue((_) => controller.toggleTerrain()),
        ),
        const SizedBox(height: 8),
        SettingsToggleRow(
          key: const Key('options.showResources'),
          icon: Icons.diamond_outlined,
          label: context.l10n.gameOptionResources,
          value: display.showResources,
          onChanged: ref.withMenuClickValue(
            (_) => controller.toggleResources(),
          ),
        ),
        const SizedBox(height: 8),
        SettingsToggleRow(
          key: const Key('options.showHeightBadge'),
          icon: Icons.height_outlined,
          label: context.l10n.gameOptionHeight,
          value: display.showHeightBadge,
          onChanged: ref.withMenuClickValue(
            (_) => controller.toggleHeightBadge(),
          ),
        ),
      ],
    );
  }
}

class _MapPlanningControls extends ConsumerWidget {
  const _MapPlanningControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(hexDisplayProvider);
    final controller = ref.read(hexDisplayProvider.notifier);
    return Column(
      children: [
        SettingsToggleRow(
          key: const Key('options.showCitySites'),
          icon: Icons.add_location_alt_outlined,
          label: context.l10n.gameOptionCitySites,
          value: display.showCitySites,
          onChanged: ref.withMenuClickValue(
            (_) => controller.toggleCitySites(),
          ),
        ),
        const SizedBox(height: 8),
        SettingsToggleRow(
          key: const Key('options.showCityGrowth'),
          icon: Icons.domain_add_outlined,
          label: context.l10n.gameOptionCityGrowth,
          value: display.showCityGrowth,
          onChanged: ref.withMenuClickValue(
            (_) => controller.toggleCityGrowth(),
          ),
        ),
      ],
    );
  }
}

class _MapGeometryControls extends ConsumerWidget {
  const _MapGeometryControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(hexDisplayProvider);
    final controller = ref.read(hexDisplayProvider.notifier);
    return Column(
      children: [
        SettingsToggleRow(
          key: const Key('options.showHexes'),
          icon: Icons.grid_on_outlined,
          label: context.l10n.gameOptionShowHexes,
          value: display.hexBordersVisible,
          onChanged: ref.withMenuClickValue(controller.setHexBordersVisible),
        ),
        const SizedBox(height: 8),
        SettingsToggleRow(
          key: const Key('options.showHeightWalls'),
          icon: Icons.layers_outlined,
          label: context.l10n.gameOptionShowHeight,
          value: display.heightWallsVisible,
          onChanged: ref.withMenuClickValue(controller.setHeightWallsVisible),
        ),
      ],
    );
  }
}

class OptionsCameraControls extends StatelessWidget {
  const OptionsCameraControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OwnUnitCameraControls(),
        SizedBox(height: 8),
        _EnemyUnitCameraControls(),
        SizedBox(height: 8),
        _CinematicCameraControl(),
      ],
    );
  }
}

class _OwnUnitCameraControls extends ConsumerWidget {
  const _OwnUnitCameraControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameplaySettingsProvider);
    final controller = ref.read(gameplaySettingsProvider.notifier);
    return Column(
      children: [
        SettingsToggleRow(
          key: const Key('options.focusOwnUnitMovementCamera'),
          icon: Icons.center_focus_strong_outlined,
          label: context.l10n.focusOwnUnitMovementCameraLabel,
          value: settings.focusOwnUnitMovementCamera,
          onChanged: ref.withMenuClickValue(
            controller.setFocusOwnUnitMovementCamera,
          ),
        ),
        const SizedBox(height: 8),
        SettingsToggleRow(
          key: const Key('options.followOwnUnitMovementCamera'),
          icon: Icons.my_location_outlined,
          label: context.l10n.followOwnUnitMovementCameraLabel,
          value: settings.followOwnUnitMovementCamera,
          onChanged: ref.withMenuClickValue(
            controller.setFollowOwnUnitMovementCamera,
          ),
        ),
      ],
    );
  }
}

class _EnemyUnitCameraControls extends ConsumerWidget {
  const _EnemyUnitCameraControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameplaySettingsProvider);
    final controller = ref.read(gameplaySettingsProvider.notifier);
    return Column(
      children: [
        SettingsToggleRow(
          key: const Key('options.focusEnemyUnitMovementCamera'),
          icon: Icons.crisis_alert_outlined,
          label: context.l10n.focusEnemyUnitMovementCameraLabel,
          value: settings.focusEnemyUnitMovementCamera,
          onChanged: ref.withMenuClickValue(
            controller.setFocusEnemyUnitMovementCamera,
          ),
        ),
        const SizedBox(height: 8),
        SettingsToggleRow(
          key: const Key('options.followEnemyUnitMovementCamera'),
          icon: Icons.track_changes_outlined,
          label: context.l10n.followEnemyUnitMovementCameraLabel,
          value: settings.followEnemyUnitMovementCamera,
          onChanged: ref.withMenuClickValue(
            controller.setFollowEnemyUnitMovementCamera,
          ),
        ),
      ],
    );
  }
}

class _CinematicCameraControl extends ConsumerWidget {
  const _CinematicCameraControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameplaySettingsProvider);
    return SettingsToggleRow(
      key: const Key('options.cinematicCamera'),
      icon: Icons.movie_filter_outlined,
      label: context.l10n.cinematicCameraLabel,
      value: settings.cinematicCameraEnabled,
      onChanged: ref.withMenuClickValue(
        ref.read(gameplaySettingsProvider.notifier).setCinematicCameraEnabled,
      ),
    );
  }
}
