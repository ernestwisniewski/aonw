import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final releaseInfo = ref.watch(appReleaseInfoProvider);
    final versionLabel = releaseInfo.maybeWhen(
      data: (info) => info.displayLabel,
      orElse: () => AppReleaseChannel.alpha.label,
    );
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: GameText.screenTitle(l10n.creditsTitle),
        onClose: ref.withMenuBack(() => context.go('/')),
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
                child: Text(
                  l10n.creditsCreatedBy('Ernest'),
                  style: GameUiTheme.body.copyWith(
                    color: GameUiTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
