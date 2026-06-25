part of 'lobby_screen.dart';

final class _LobbyLocalSetupPanel extends StatelessWidget {
  const _LobbyLocalSetupPanel({
    required this.l10n,
    required this.primaryCountryControl,
    required this.primaryLeaderName,
    required this.selectedMapName,
    required this.nameController,
    required this.onNameChanged,
    required this.gameLengthPreset,
    required this.onGameLengthPresetChanged,
    required this.mapValidation,
    required this.mapValidationLoading,
    required this.mapValidationError,
    required this.playerCount,
    required this.maximumPlayers,
    required this.canAddPlayers,
    required this.playerRowBuilder,
    required this.onAddPlayer,
  });

  final AppLocalizations l10n;
  final Widget primaryCountryControl;
  final String primaryLeaderName;
  final String selectedMapName;
  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final _GameLengthPreset gameLengthPreset;
  final ValueChanged<_GameLengthPreset> onGameLengthPresetChanged;
  final MapValidationResult? mapValidation;
  final bool mapValidationLoading;
  final Object? mapValidationError;
  final int playerCount;
  final int maximumPlayers;
  final bool canAddPlayers;
  final Widget Function(int index) playerRowBuilder;
  final VoidCallback onAddPlayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LobbyCivilizationSection(
          countryControl: primaryCountryControl,
          leader: primaryLeaderName,
        ),
        const SizedBox(height: 14),
        _buildGameSetupSection(),
        const SizedBox(height: 14),
        _buildPlayerSetupSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGameSetupSection() {
    return MenuRouteSection(
      icon: Icons.tune_outlined,
      title: l10n.lobbySetupTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.lobbySetupSubtitle, style: GameUiTheme.bodySmall),
          const SizedBox(height: 14),
          _LobbySelectedMapNote(mapName: selectedMapName),
          const SizedBox(height: 14),
          _LobbyLabel(l10n.gameNameLabel),
          const SizedBox(height: 6),
          _LobbyTextField(controller: nameController, onChanged: onNameChanged),
          const SizedBox(height: 18),
          _LobbyLabel(GameText.sectionLabel(l10n.gameLengthLabel)),
          const SizedBox(height: 10),
          _GameLengthSelector(
            value: gameLengthPreset,
            onPresetChanged: onGameLengthPresetChanged,
          ),
          _MapValidationNotice(
            result: mapValidation,
            loading: mapValidationLoading,
            loadError: mapValidationError,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSetupSection() {
    return MenuRouteSection(
      icon: Icons.groups_2_outlined,
      title: l10n.lobbyPlayersSetupTitle,
      trailing: MenuMetricPill(
        icon: Icons.person_outline,
        label: '$playerCount/$maximumPlayers',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.lobbyPlayersSetupSubtitle, style: GameUiTheme.bodySmall),
          const SizedBox(height: 14),
          for (var index = 0; index < playerCount; index++)
            playerRowBuilder(index),
          if (_showAddPlayerAction)
            _AddLobbyPlayerButton(onPressed: onAddPlayer),
        ],
      ),
    );
  }

  bool get _showAddPlayerAction {
    return canAddPlayers && playerCount < maximumPlayers;
  }
}

final class _AddLobbyPlayerButton extends StatelessWidget {
  const _AddLobbyPlayerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 16),
        label: Text(l10n.addPlayerAction, style: GameUiTheme.actionLabel),
        style: TextButton.styleFrom(
          foregroundColor: GameUiTheme.accent,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
