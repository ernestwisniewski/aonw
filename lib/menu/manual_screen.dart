import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/manual_content.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManualScreen extends ConsumerWidget {
  const ManualScreen({super.key, this.gamepadInputListenable});

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
          title: GameText.screenTitle(l10n.mainMenuManual),
          onClose: ref.withMenuBack(close),
        ),
        body: MenuRouteBackdrop(
          maxContentWidth: 1180,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              GameUiScreenHeader(
                icon: Icons.menu_book_outlined,
                title: l10n.manualTitle,
                subtitle: l10n.manualSubtitle,
                meta: [
                  GameUiMetaPill(
                    icon: Icons.mouse_outlined,
                    label: l10n.manualMetaDesktop,
                  ),
                  GameUiMetaPill(
                    icon: Icons.touch_app_outlined,
                    label: l10n.manualMetaMobile,
                  ),
                  GameUiMetaPill(
                    icon: Icons.sports_esports_outlined,
                    label: l10n.manualMetaGamepad,
                  ),
                  GameUiMetaPill(
                    icon: Icons.flag_outlined,
                    label: l10n.manualMetaAlpha,
                    color: GameUiTheme.info,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ManualContent(
                  l10n: l10n,
                  mobileFirst: MediaQuery.sizeOf(context).width < 700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
