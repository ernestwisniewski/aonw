part of 'main_menu_screen.dart';

extension _MenuPanelItems on _MenuPanelState {
  List<_MenuItem> _menuItems(
    BuildContext context, {
    required bool multiplayerAccessAllowed,
  }) {
    final l10n = context.l10n;
    const defaultNewGameFlow = NewGameFlow.singlePlayer;
    return [
      ..._compatibilityRecoveryItems(context),
      if (_resumeMatchId != null && multiplayerAccessAllowed)
        _MenuItem(
          icon: Icons.play_circle_outline,
          label: GameText.menuLabel(l10n.multiplayerResumeAction),
          semanticLabel: l10n.multiplayerResumeAction,
          primary: true,
          sublabel: _resumeLoading
              ? GameText.menuLabel(l10n.multiplayerResumeLoading)
              : GameText.menuLabel(l10n.multiplayerResumeSublabel),
          onPressed: _resumeLoading
              ? () {}
              : ref.withMenuClickAsync(_resumeMultiplayerMatchIfAllowed),
        ),
      _MenuItem(
        icon: Icons.add_circle_outline_rounded,
        label: GameText.menuLabel(l10n.newGameAction),
        semanticLabel: l10n.newGameAction,
        sublabel: GameText.menuLabel(l10n.newGameIntroTitle),
        primary: _resumeMatchId == null,
        onPressed: ref.withMenuClick(
          () => context.go('/new-game?mode=${defaultNewGameFlow.queryValue}'),
        ),
      ),
      _MenuItem(
        icon: Icons.folder_open_outlined,
        label: GameText.menuLabel(l10n.mainMenuLoadGame),
        semanticLabel: l10n.mainMenuLoadGame,
        onPressed: ref.withMenuClick(() => context.go('/load-game')),
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: GameText.menuLabel(l10n.mainMenuSettings),
        semanticLabel: l10n.mainMenuSettings,
        sublabel: GameText.menuLabel(l10n.mainMenuSettingsSublabel),
        onPressed: ref.withMenuClick(() => context.go('/options')),
      ),
      // dart:io-backed developer tools are unavailable in web builds.
      if (!kIsWeb)
        _MenuItem(
          icon: Icons.developer_mode_outlined,
          label: GameText.menuLabel(l10n.mainMenuDeveloper),
          semanticLabel: l10n.mainMenuDeveloper,
          active: _developerOpen,
          sublabel: GameText.menuLabel(l10n.mainMenuToolsSublabel),
          panelKind: _MenuPanelKind.developer,
          onPressed: ref.withMenuClick(_toggleDeveloperTools),
        ),
      _MenuItem(
        icon: Icons.logout,
        label: GameText.menuLabel(l10n.mainMenuExit),
        semanticLabel: l10n.mainMenuExit,
        onPressed: ref.withMenuClickAsync(widget.onExit ?? exitApplication),
      ),
    ];
  }

  List<_MenuItem> _compatibilityRecoveryItems(BuildContext context) {
    if (ref.watch(multiplayerAccessStateProvider) !=
        MultiplayerAccessState.unavailable) {
      return const [];
    }
    final l10n = context.l10n;
    return [
      _MenuItem(
        icon: Icons.refresh_rounded,
        label: GameText.menuLabel(l10n.retryAction),
        semanticLabel: l10n.retryAction,
        sublabel: GameText.menuLabel(l10n.multiplayerResumeFailed),
        onPressed: ref.withMenuClick(
          ref.read(multiplayerCompatibilityRetryProvider),
        ),
      ),
    ];
  }
}
