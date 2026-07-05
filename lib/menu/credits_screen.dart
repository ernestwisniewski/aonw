import 'dart:async';

import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/l10n/l10n.dart';
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
import 'package:url_launcher/url_launcher.dart';

final Uri _devlogUrl = Uri.parse('https://ernest.dev');

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key, this.gamepadInputListenable});

  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final releaseInfo = ref.watch(appReleaseInfoProvider);
    final versionLabel = releaseInfo.maybeWhen(
      data: (info) => info.displayLabel,
      orElse: () => AppReleaseChannel.alpha.label,
    );
    void close() => context.go('/');
    return MenuGamepadInputBinding(
      input: gamepadInputListenable,
      onCancel: ref.withMenuBack(close),
      child: Scaffold(
        backgroundColor: GameUiTheme.bg,
        appBar: GameUiAppBar(
          title: GameText.screenTitle(l10n.creditsTitle),
          onClose: ref.withMenuBack(close),
        ),
        body: MenuRouteBackdrop(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              GameUiScreenHeader(
                icon: Icons.star_border,
                title: l10n.appTitle,
                subtitle: versionLabel,
                meta: [
                  const GameUiMetaPill(
                    icon: Icons.code_outlined,
                    label: 'Flutter & Flame',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MenuRouteSection(
                  icon: Icons.history_edu_outlined,
                  title: l10n.creditsTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.creditsCreatedBy('Ernest'),
                        style: GameUiTheme.body.copyWith(
                          color: GameUiTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        key: const Key('credits.devlogLink'),
                        onPressed: ref.withMenuClick(
                          () => unawaited(_openDevlogUrl()),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: GameUiTheme.goldLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 17),
                        label: Text(
                          'Devlog: ernest.dev',
                          style: GameUiTheme.bodyStrong.copyWith(
                            color: GameUiTheme.goldLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openDevlogUrl() async {
  await launchUrl(_devlogUrl, mode: LaunchMode.externalApplication);
}
