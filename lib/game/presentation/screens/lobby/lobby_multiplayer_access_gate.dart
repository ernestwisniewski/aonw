import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Prevents stale release builds and unresolved compatibility checks from
/// entering multiplayer through a direct or deep-linked lobby route.
final class LobbyMultiplayerAccessGate extends ConsumerWidget {
  const LobbyMultiplayerAccessGate(this.flow, this.lobbyBuilder, {super.key});

  final NewGameFlow flow;
  final WidgetBuilder lobbyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (flow == NewGameFlow.multiplayer &&
        !ref.watch(mainMenuMultiplayerAccessAllowedProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return lobbyBuilder(context);
  }
}
