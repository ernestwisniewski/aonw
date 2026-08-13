import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/menu/options_accessibility_sections.dart';
import 'package:aonw/menu/options_audio_gameplay_sections.dart';
import 'package:aonw/menu/options_gamepad_section.dart';
import 'package:aonw/menu/options_multiplayer_profile_section.dart';
import 'package:aonw/menu/options_performance_section.dart';
import 'package:aonw/menu/widgets/graphics_settings_section.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key, this.gamepadInputListenable});

  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void close() => context.go('/');
    return MenuGamepadInputBinding(
      input: gamepadInputListenable,
      onCancel: ref.withMenuBack(close),
      child: Scaffold(
        backgroundColor: GameUiTheme.bg,
        appBar: GameUiAppBar(
          title: GameText.screenTitle(l10n.mainMenuSettings),
          onClose: ref.withMenuBack(close),
        ),
        body: MenuRouteBackdrop(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              GameUiScreenHeader(
                icon: Icons.settings_outlined,
                title: l10n.optionsTitle,
                subtitle: l10n.optionsSubtitle,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OptionsMultiplayerProfileSection(),
                    SizedBox(height: 12),
                    OptionsTextScaleSection(),
                    SizedBox(height: 12),
                    OptionsLanguageSection(),
                    SizedBox(height: 12),
                    GraphicsSettingsSection(),
                    OptionsMapDisplaySection(),
                    SizedBox(height: 12),
                    OptionsCameraSection(),
                    SizedBox(height: 12),
                    OptionsAnimationSection(),
                    SizedBox(height: 12),
                    OptionsAutomationSection(),
                    SizedBox(height: 12),
                    OptionsAudioSection(),
                    SizedBox(height: 12),
                    OptionsAiSection(),
                    SizedBox(height: 12),
                    OptionsPerformanceSection(),
                    SizedBox(height: 12),
                    OptionsGamepadSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
