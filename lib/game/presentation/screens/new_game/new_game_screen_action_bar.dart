import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_single_player_setup.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NewGameStep { plan, map, review }

typedef NewGamePlanContinuation =
    void Function(List<MapSelection> maps, bool multiplayerAccessAllowed);
typedef NewGameMapStarter =
    Future<void> Function(
      MapSelection map, {
      required bool multiplayerAccessAllowed,
    });

class NewGameActionBar extends ConsumerWidget {
  const NewGameActionBar({
    required this.step,
    required this.flow,
    required this.maps,
    required this.singlePlayerPlayerCount,
    required this.multiplayerAccessAllowed,
    required this.selectedMap,
    required this.startingSinglePlayer,
    required this.onStepSelected,
    required this.onContinue,
    required this.onStart,
    super.key,
  });

  final NewGameStep step;
  final NewGameFlow flow;
  final List<MapSelection> maps;
  final int singlePlayerPlayerCount;
  final bool multiplayerAccessAllowed;
  final MapSelection? selectedMap;
  final bool startingSinglePlayer;
  final ValueChanged<NewGameStep> onStepSelected;
  final NewGamePlanContinuation onContinue;
  final NewGameMapStarter onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (step) {
      NewGameStep.plan => _buildPlanActionBar(ref, l10n),
      NewGameStep.map => _buildMapActionBar(ref, l10n),
      NewGameStep.review => _buildReviewActionBar(ref, l10n),
    };
  }

  MenuActionBar _buildPlanActionBar(WidgetRef ref, AppLocalizations l10n) {
    return MenuActionBar(
      primaryKey: flow == NewGameFlow.multiplayer
          ? const Key('newGame.multiplayerLobbyAction')
          : null,
      summary: _NewGameActionSummary(
        icon: flow.icon,
        title: flow.menuLabel(l10n),
        subtitle: flow.description(l10n),
      ),
      primaryLabel: GameText.actionLabel(
        flow == NewGameFlow.multiplayer
            ? l10n.newGameStartSetupAction
            : l10n.continueAction,
      ),
      primaryIcon: Icons.arrow_forward_rounded,
      onPrimary: _canContinueFromPlan
          ? ref.withMenuClick(() => onContinue(maps, multiplayerAccessAllowed))
          : null,
    );
  }

  MenuActionBar _buildMapActionBar(WidgetRef ref, AppLocalizations l10n) {
    return MenuActionBar(
      summary: _NewGameActionSummary(
        icon: Icons.map_outlined,
        title: l10n.newGameMapTitle,
        subtitle: l10n.newGameMapSubtitle,
      ),
      secondaryLabel: GameText.actionLabel(l10n.backAction),
      secondaryIcon: Icons.arrow_back_rounded,
      onSecondary: ref.withMenuClick(
        () => onStepSelected(
          selectedMap == null ? NewGameStep.plan : NewGameStep.review,
        ),
      ),
    );
  }

  MenuActionBar _buildReviewActionBar(WidgetRef ref, AppLocalizations l10n) {
    final aiOpponentCount =
        NewGameSinglePlayerSetup.aiOpponentCountForPlayerCount(
          singlePlayerPlayerCount,
        );
    return MenuActionBar(
      summary: _NewGameActionSummary(
        icon: flow.icon,
        title: selectedMap?.displayName ?? l10n.noMapsTitle,
        subtitle: flow == NewGameFlow.singlePlayer
            ? l10n.newGameReviewSinglePlayerSubtitle(aiOpponentCount)
            : l10n.newGameReviewSubtitle,
      ),
      secondaryLabel: GameText.actionLabel(l10n.newGameChangeMapAction),
      secondaryIcon: Icons.map_outlined,
      onSecondary: ref.withMenuClick(() => onStepSelected(NewGameStep.map)),
      primaryLabel: GameText.actionLabel(
        flow == NewGameFlow.singlePlayer
            ? l10n.startGameAction
            : l10n.newGameStartSetupAction,
      ),
      primaryIcon: flow == NewGameFlow.singlePlayer
          ? Icons.play_arrow_rounded
          : Icons.arrow_forward_rounded,
      primaryBusy: startingSinglePlayer,
      onPrimary: _canStartSelectedMap
          ? ref.withMenuClickAsync(
              () => onStart(
                selectedMap!,
                multiplayerAccessAllowed: multiplayerAccessAllowed,
              ),
            )
          : null,
    );
  }

  bool get _canContinueFromPlan {
    return flow.enabled &&
        (flow != NewGameFlow.multiplayer || multiplayerAccessAllowed);
  }

  bool get _canStartSelectedMap {
    if (selectedMap == null || startingSinglePlayer || !flow.enabled) {
      return false;
    }
    return flow != NewGameFlow.multiplayer || multiplayerAccessAllowed;
  }
}

class _NewGameActionSummary extends StatelessWidget {
  const _NewGameActionSummary({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: GameUiTheme.gold),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                GameText.actionLabel(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.cardMeta,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
