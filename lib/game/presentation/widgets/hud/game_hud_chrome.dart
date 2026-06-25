part of 'game_hud.dart';

String? _outcomePerspectivePlayerId({
  required GameSave gameSave,
  required String? gameStateActivePlayerId,
  required PlayerControlState? playerControl,
}) {
  final activeSavePlayers = [
    for (final entry in gameSave.playerStates.entries)
      if (entry.value == PlayerTurnState.active) entry.key,
  ];
  if (activeSavePlayers.length == 1) return activeSavePlayers.single;
  if (gameStateActivePlayerId != null && gameStateActivePlayerId.isNotEmpty) {
    return gameStateActivePlayerId;
  }
  return playerControl?.activePlayerId;
}

class _HudTopFade extends StatelessWidget {
  const _HudTopFade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 96,
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SurfaceElevation.flat.fill(
                  background: GameUiTheme.bg,
                  alpha: 232,
                ),
                SurfaceElevation.flat.fill(
                  background: GameUiTheme.bg,
                  alpha: 126,
                ),
                SurfaceElevation.flat.fill(
                  background: GameUiTheme.bg,
                  alpha: 0,
                ),
              ],
            ),
            shape: const RoundedRectangleBorder(),
          ),
        ),
      ),
    );
  }
}

class _HudMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HudMenuButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Tooltip(
            message: l10n.returnToMenuAction,
            child: Material(
              color: SurfaceElevation.flat.fill(
                background: GameUiTheme.bg,
                alpha: 205,
              ),
              borderRadius: GameUiTheme.borderRadius,
              child: InkWell(
                onTap: onPressed,
                borderRadius: GameUiTheme.borderRadius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: SurfaceElevation.flat.decoration(
                    borderRadius: GameUiTheme.borderRadius,
                    border: BorderEmphasis.regular,
                    includeShadow: false,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '✕',
                        style: GameUiTheme.actionLabel.copyWith(
                          color: GameUiTheme.gold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MENU',
                        style: GameUiTheme.actionLabel.copyWith(
                          color: GameUiTheme.goldLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
