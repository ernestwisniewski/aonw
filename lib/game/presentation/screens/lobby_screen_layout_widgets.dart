part of 'lobby_screen.dart';

class _LobbyContentInset extends StatelessWidget {
  final Widget child;

  const _LobbyContentInset({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}

class _LobbyStepRail extends StatelessWidget {
  const _LobbyStepRail({
    required this.flow,
    required this.multiplayerMode,
    required this.activeMatch,
  });

  final NewGameFlow flow;
  final _MultiplayerLobbyMode multiplayerMode;
  final WireMatch? activeMatch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final network = flow == NewGameFlow.multiplayer;
    final onlineActive =
        network &&
        (multiplayerMode != _MultiplayerLobbyMode.home || activeMatch != null);
    final playersActive = !network || activeMatch != null;
    final steps = [
      (
        number: 1,
        icon: Icons.flag_circle_outlined,
        label: l10n.lobbyStepCivilization,
        selected: !network || (network && !onlineActive),
      ),
      (
        number: 2,
        icon: network ? Icons.hub_outlined : Icons.tune_outlined,
        label: network ? l10n.lobbyStepOnline : l10n.lobbyStepSetup,
        selected: network && onlineActive && !playersActive,
      ),
      (
        number: 3,
        icon: Icons.groups_2_outlined,
        label: l10n.lobbyStepPlayers,
        selected: network && playersActive,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: _LobbyStepChip(
                    key: Key('lobby.step.${steps[index].number}'),
                    number: steps[index].number,
                    icon: steps[index].icon,
                    label: steps[index].label,
                    selected: steps[index].selected,
                    compact: compact,
                  ),
                ),
                if (index < steps.length - 1) const SizedBox(width: 6),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final step in steps)
              _LobbyStepChip(
                key: Key('lobby.step.${step.number}'),
                number: step.number,
                icon: step.icon,
                label: step.label,
                selected: step.selected,
                compact: compact,
              ),
          ],
        );
      },
    );
  }
}

class _LobbyStepChip extends StatelessWidget {
  const _LobbyStepChip({
    super.key,
    required this.number,
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
  });

  final int number;
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: GameMotion.snap,
      width: compact ? double.infinity : 196,
      constraints: const BoxConstraints(minHeight: 44),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 12,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: selected
            ? GameUiTheme.gold.withAlpha(34)
            : GameUiTheme.bg.withAlpha(148),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(
          color: selected ? GameUiTheme.gold : GameUiTheme.gold.withAlpha(78),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            '$number',
            style: GameUiTheme.toolbarLabel.copyWith(
              color: selected
                  ? GameUiTheme.goldLight
                  : GameUiTheme.textTertiary,
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          Icon(
            icon,
            size: compact ? 14 : 16,
            color: selected ? GameUiTheme.goldLight : GameUiTheme.gold,
          ),
          SizedBox(width: compact ? 5 : 8),
          Flexible(
            child: Text(
              GameText.actionLabel(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.actionLabel.copyWith(
                color: selected
                    ? GameUiTheme.goldLight
                    : GameUiTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyCivilizationSection extends StatelessWidget {
  const _LobbyCivilizationSection({
    required this.countryControl,
    required this.leader,
  });

  final Widget countryControl;
  final String leader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MenuRouteSection(
      icon: Icons.flag_circle_outlined,
      title: l10n.lobbyCivilizationTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.lobbyCivilizationSubtitle, style: GameUiTheme.bodySmall),
          const SizedBox(height: 14),
          countryControl,
          const SizedBox(height: 10),
          _LobbyLeaderPreview(leader: leader),
        ],
      ),
    );
  }
}

class _LobbyLeaderPreview extends StatelessWidget {
  const _LobbyLeaderPreview({required this.leader});

  final String leader;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(130),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(color: GameUiTheme.gold.withAlpha(62)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 18,
              color: GameUiTheme.gold,
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 82,
              child: Text(
                GameText.sectionLabel(l10n.newGameLeaderLabel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                leader,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbySelectedMapNote extends StatelessWidget {
  const _LobbySelectedMapNote({required this.mapName});

  final String mapName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(118),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(color: GameUiTheme.gold.withAlpha(58)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, size: 17, color: GameUiTheme.gold),
            const SizedBox(width: 9),
            Text(
              GameText.sectionLabel(l10n.newGameSelectedMapLabel),
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mapName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
