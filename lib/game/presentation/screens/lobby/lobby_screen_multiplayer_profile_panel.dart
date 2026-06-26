part of 'lobby_screen.dart';

class _MultiplayerProfilePanel extends StatelessWidget {
  final TextEditingController nicknameController;
  final Widget countryControl;
  final ValueChanged<String> onNicknameChanged;
  final bool signedIn;
  final VoidCallback onSignOut;

  const _MultiplayerProfilePanel({
    required this.nicknameController,
    required this.countryControl,
    required this.onNicknameChanged,
    required this.signedIn,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      key: const Key('multiplayer.profilePanel'),
      decoration: BoxDecoration(
        color: GameUiTheme.surface,
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag_circle_outlined,
                  size: 18,
                  color: GameUiTheme.gold,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    GameText.sectionLabel(l10n.multiplayerCountryPickTitle),
                    style: GameUiTheme.bodyStrong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.multiplayerCountryPickSubtitle,
              style: GameUiTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: GameUiTheme.bg.withAlpha(118),
                borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
                border: Border.all(color: GameUiTheme.gold.withAlpha(92)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      GameText.sectionLabel(l10n.countryLabel),
                      style: GameUiTheme.toolbarLabel.copyWith(
                        color: GameUiTheme.goldLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    countryControl,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              GameText.sectionLabel(l10n.multiplayerProfileTitle),
              style: GameUiTheme.bodyStrong,
            ),
            const SizedBox(height: 6),
            Text(l10n.multiplayerProfileSubtitle, style: GameUiTheme.bodySmall),
            const SizedBox(height: 10),
            _LobbyTextField(
              key: const Key('multiplayer.nicknameInput'),
              controller: nicknameController,
              hintText: l10n.multiplayerNicknameLabel,
              onChanged: onNicknameChanged,
            ),
            if (signedIn) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('multiplayer.signOutAction'),
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(l10n.multiplayerAccountSignOutAction),
                  style: TextButton.styleFrom(
                    foregroundColor: GameUiTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
