import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_compatibility_provider.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Fail-closed route boundary for multiplayer saves.
///
/// An active match is identified from local session state before any snapshot
/// read. Local campaigns are never inferred as online from their turn model.
final class GameMultiplayerCompatibilityBoundary extends ConsumerWidget {
  const GameMultiplayerCompatibilityBoundary({
    required this.saveId,
    required this.child,
    super.key,
  });

  final String saveId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = multiplayerSaveRouteAccessOrFailClosed(
      ref.watch(multiplayerSaveAccessDecisionProvider(saveId)),
    );
    return _guardedChild(access);
  }

  Widget _guardedChild(MultiplayerAccessState access) {
    return access == MultiplayerAccessState.allowed
        ? child
        : _MultiplayerCompatibilityGateView(access: access, saveId: saveId);
  }
}

final class _MultiplayerCompatibilityGateView extends ConsumerWidget {
  const _MultiplayerCompatibilityGateView({
    required this.access,
    required this.saveId,
  });

  final MultiplayerAccessState access;
  final String saveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (access == MultiplayerAccessState.pending) {
      return Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: GameUiEmptyState(
          iconWidget: const CircularProgressIndicator(
            color: GameUiTheme.goldLight,
          ),
          title: l10n.multiplayerResumeLoading,
        ),
      );
    }
    if (access == MultiplayerAccessState.unavailable) {
      return Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: GameUiEmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.multiplayerResumeFailed,
          action: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: ref.read(
                  multiplayerSaveCompatibilityRetryProvider(saveId),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(GameText.actionLabel(l10n.retryAction)),
                style: GameUiTheme.outlinedButtonStyle(
                  foreground: GameUiTheme.goldLight,
                ),
              ),
              _backToMenuAction(context),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: GameUiEmptyState(
        icon: Icons.system_update_alt_rounded,
        title: l10n.mainMenuUpdateSoonTitle,
        message: l10n.mainMenuUpdateSoonBody,
        action: _backToMenuAction(context),
      ),
    );
  }

  Widget _backToMenuAction(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton.icon(
      onPressed: () => context.go('/'),
      icon: const Icon(Icons.arrow_back_rounded, size: 16),
      label: Text(GameText.actionLabel(l10n.backAction)),
      style: GameUiTheme.outlinedButtonStyle(foreground: GameUiTheme.goldLight),
    );
  }
}
