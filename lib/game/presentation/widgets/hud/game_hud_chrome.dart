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

extension _GameHudGamepadFocusTargets on _GameHudState {
  void _syncReturnMenuGamepadFocusTarget(
    String label,
    VoidCallback onActivate, {
    required bool enabled,
  }) {
    _syncMenuGamepadFocusTarget(
      label: label,
      onActivate: onActivate,
      enabled: enabled,
      activationKey: widget.session.saveId,
    );
  }

  void _syncMenuGamepadFocusTarget({
    required String label,
    required VoidCallback onActivate,
    required bool enabled,
    required Object? activationKey,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(hudGamepadFocusTargetRegistryProvider.notifier)
          .setSource(
            'hudMenu',
            enabled
                ? [
                    HudGamepadFocusTarget(
                      section: HudGamepadFocusSection.menu,
                      id: HudGamepadFocusTargetIds.menuReturn,
                      label: label,
                      onActivate: onActivate,
                      activationKey: activationKey,
                    ),
                  ]
                : const <HudGamepadFocusTarget>[],
          );
    });
  }
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
  final bool gamepadFocused;

  const _HudMenuButton({required this.onPressed, this.gamepadFocused = false});

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
            child: HudGamepadFocusRing(
              focused: gamepadFocused,
              borderRadius: GameUiTheme.borderRadius,
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
      ),
    );
  }
}

extension _GameHudNetworkActions on _GameHudState {
  bool _canResign(GameSave? save, NetworkSession? networkSession) {
    return save?.gameMode == GameMode.multiplayer &&
        networkSession != null &&
        networkSession.isConnected &&
        networkSession.matchId == widget.session.saveId;
  }

  Future<void> _onResignMatch(BuildContext context) async {
    if (_resigning) return;
    final l10n = AppLocalizations.of(context);
    final session = ref.read(networkSessionProvider);
    final matchId = session?.matchId;
    if (session == null || matchId == null) return;

    final confirmed = await showGameConfirmation(
      context: context,
      title: l10n.resignMatchTitle,
      message: l10n.resignMatchMessage,
      confirmLabel: l10n.resignAction,
      cancelLabel: l10n.selectionActionCancel,
      tone: GameConfirmationTone.danger,
    );
    if (!confirmed || !mounted || !context.mounted) return;

    _setResigning(true);
    try {
      await ref
          .read(networkSessionClientProvider)
          .resignMatch(token: session.token, matchId: matchId);
      await ref.read(networkSessionStoreProvider).saveMatchId(null);
      final latestSession = ref.read(networkSessionProvider);
      if (latestSession == null || latestSession.userId != session.userId) {
        return;
      }
      ref
          .read(networkSessionStateProvider.notifier)
          .set(
            latestSession.copyWith(
              playerId: null,
              matchId: null,
              connectionState: latestSession.connectionState.copyWith(
                changedAt: ref.read(gameClockProvider).nowUtc(),
              ),
            ),
          );
      if (!mounted) return;
      widget.onClose();
    } catch (_) {
      if (!mounted || !context.mounted) return;
      GameToast.show(
        context,
        message: l10n.resignMatchError,
        tone: GameToastTone.error,
      );
    } finally {
      _setResigning(false);
    }
  }
}
