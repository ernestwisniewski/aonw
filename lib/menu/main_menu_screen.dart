import 'dart:async';

import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/menu/app_exit.dart';
import 'package:aonw/menu/menu_animated_background.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

final _feedbackUrl = Uri.parse('https://www.reddit.com/r/aonw/');

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key, this.onExit});

  final Future<void> Function()? onExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MenuBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                final panelWidth = compact
                    ? constraints.maxWidth
                    : constraints.maxWidth.clamp(340.0, 390.0).toDouble();
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: panelWidth,
                    child: _MenuPanel(showBottomLinks: compact, onExit: onExit),
                  ),
                );
              },
            ),
          ),
          const Positioned(
            top: 12,
            right: 16,
            child: SafeArea(child: _VersionTag()),
          ),
          const Positioned(
            right: 18,
            bottom: 18,
            child: SafeArea(child: _RightInfoColumn()),
          ),
        ],
      ),
    );
  }
}

class _MenuBackground extends StatelessWidget {
  const _MenuBackground();

  @override
  Widget build(BuildContext context) {
    return MenuAnimatedBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  GameUiTheme.bg,
                  Color(0xA80A0E14),
                  Color(0x1F0A0E14),
                  Color(0x000A0E14),
                ],
                stops: [0, 0.28, 0.48, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(color: GameUiTheme.bg.withAlpha(34)),
          ),
        ],
      ),
    );
  }
}

class _MenuPanel extends ConsumerStatefulWidget {
  final bool showBottomLinks;
  final Future<void> Function()? onExit;

  const _MenuPanel({required this.showBottomLinks, this.onExit});

  @override
  ConsumerState<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends ConsumerState<_MenuPanel> {
  bool _developerOpen = false;
  bool _resumeLoading = false;
  String? _resumeMatchId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadResumeMatch());
  }

  Future<void> _loadResumeMatch() async {
    final stored = await ref.read(networkSessionStoreProvider).load();
    if (!mounted) return;
    setState(() => _resumeMatchId = stored?.matchId);
  }

  Future<void> _resumeMultiplayerMatch() async {
    final store = ref.read(networkSessionStoreProvider);
    final stored = await store.load();
    final matchId = stored?.matchId;
    if (stored == null || matchId == null || matchId.isEmpty) return;
    setState(() => _resumeLoading = true);
    try {
      final client = ref.read(networkSessionClientProvider);
      final token = await client.refresh(refreshToken: stored.refreshToken);
      final match = await client.loadMatch(token: token, matchId: matchId);
      final playerId = _playerIdForUser(match, stored.userId);
      if (match.state != 'running' || playerId == null) {
        throw StateError('No active multiplayer match to resume.');
      }
      final session = NetworkSession(
        userId: stored.userId,
        token: token,
        refreshToken: stored.refreshToken,
        matchId: match.id,
        playerId: playerId,
        connectionState: NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
          changedAt: ref.read(gameClockProvider).nowUtc(),
        ),
      );
      ref.read(networkSessionStateProvider.notifier).set(session);
      if (!mounted) return;
      context.go(
        '/game?saveId=${match.id}'
        '&name=${Uri.encodeComponent(match.mapName)}'
        '&source=${MapSource.asset.name}',
      );
    } catch (_) {
      await store.saveMatchId(null);
      if (!mounted) return;
      setState(() => _resumeMatchId = null);
      GameToast.show(
        context,
        message: context.l10n.multiplayerResumeFailed,
        tone: GameToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _resumeLoading = false);
    }
  }

  String? _playerIdForUser(WireMatch match, String userId) {
    for (final player in match.players) {
      if (player.userId == userId) return player.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const defaultNewGameFlow = NewGameFlow.singlePlayer;
    final items = [
      if (_resumeMatchId != null)
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
              : ref.withMenuClickAsync(_resumeMultiplayerMatch),
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
      // Developer tools (map editor, asset editor) call into dart:io heavy
      // services and are not usable on the web build. Hide the entry rather
      // than ship a crashy button.
      if (!kIsWeb)
        _MenuItem(
          icon: Icons.developer_mode_outlined,
          label: GameText.menuLabel(l10n.mainMenuDeveloper),
          semanticLabel: l10n.mainMenuDeveloper,
          active: _developerOpen,
          sublabel: GameText.menuLabel(l10n.mainMenuToolsSublabel),
          panelKind: _MenuPanelKind.developer,
          onPressed: ref.withMenuClick(
            () => setState(() => _developerOpen = !_developerOpen),
          ),
        ),
      _MenuItem(
        icon: Icons.logout,
        label: GameText.menuLabel(l10n.mainMenuExit),
        semanticLabel: l10n.mainMenuExit,
        onPressed: ref.withMenuClickAsync(widget.onExit ?? exitApplication),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            GameUiTheme.bg.withAlpha(236),
            GameUiTheme.bg.withAlpha(172),
            GameUiTheme.bg.withAlpha(54),
            GameUiTheme.bg.withAlpha(0),
          ],
          stops: const [0, 0.58, 0.82, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 28, 12),
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 192,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 6),
            const GoldDivider(width: 146),
            const SizedBox(height: 10),
            _MenuSynopsis(compact: widget.showBottomLinks),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final item in items) ...[
                      _MenuButton(item: item),
                      if (item.panelKind == _MenuPanelKind.developer)
                        _AnimatedMenuExpansion(
                          open: _developerOpen,
                          child: const _DeveloperToolsPanel(),
                        ),
                      const SizedBox(height: 9),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.showBottomLinks) ...[
              const SizedBox(height: 8),
              const _BottomLinks(),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuSynopsis extends StatelessWidget {
  const _MenuSynopsis({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).height < 760) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(118),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(82)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BUILD · RESEARCH · COMMAND',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.goldLight,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.mainMenuWhatsNewBody,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.active = false,
    this.panelKind,
    this.semanticLabel,
    this.sublabel,
  });

  final IconData icon;
  final String label;
  final String? semanticLabel;
  final String? sublabel;
  final bool primary;
  final bool active;
  final _MenuPanelKind? panelKind;
  final VoidCallback onPressed;
}

enum _MenuPanelKind { developer }

class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.item});

  final _MenuItem item;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final expandable = item.panelKind != null;
    final highlighted = _hovered || item.primary || item.active;
    final borderColor = highlighted
        ? GameUiTheme.gold
        : GameUiTheme.gold.withAlpha(110);
    final iconColor = highlighted ? GameUiTheme.gold : GameUiTheme.goldDark;
    final textColor = item.primary || item.active
        ? GameUiTheme.goldLight
        : GameUiTheme.textPrimary;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.3);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        enabled: true,
        label: item.semanticLabel ?? item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: item.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 50 + ((textScale - 1) * 18),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  highlighted
                      ? GameUiTheme.chipSurfaceDim
                      : GameUiTheme.chipSurface,
                  GameUiTheme.surface.withAlpha(226),
                ],
              ),
              borderRadius: GameUiTheme.borderRadius,
              border: Border.all(
                color: borderColor,
                width: highlighted ? 1.3 : 1,
              ),
              boxShadow: [
                if (highlighted)
                  BoxShadow(
                    color: GameUiTheme.gold.withAlpha(_hovered ? 70 : 42),
                    blurRadius: _hovered ? 16 : 9,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: GameUiTheme.bg.withAlpha(highlighted ? 132 : 88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: GameUiTheme.gold.withAlpha(highlighted ? 138 : 74),
                    ),
                  ),
                  child: Icon(item.icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.menuButton.copyWith(
                          color: textColor,
                        ),
                      ),
                      if (item.sublabel != null)
                        Text(
                          item.sublabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameUiTheme.chipLabel.copyWith(
                            color: GameUiTheme.textTertiary,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
                if (expandable)
                  AnimatedRotation(
                    turns: item.active ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: GameUiTheme.gold.withAlpha(
                        highlighted ? 220 : 110,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: GameUiTheme.gold.withAlpha(highlighted ? 220 : 110),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMenuExpansion extends StatelessWidget {
  const _AnimatedMenuExpansion({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 170),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SizeTransition(
          sizeFactor: curved,
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      child: open
          ? Padding(
              key: const ValueKey('menuExpansion.open'),
              padding: const EdgeInsets.only(top: 8),
              child: child,
            )
          : const SizedBox.shrink(key: ValueKey('menuExpansion.closed')),
    );
  }
}

class _DeveloperToolsPanel extends ConsumerWidget {
  const _DeveloperToolsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(232),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(86)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 17,
                  color: GameUiTheme.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  GameText.sectionLabel(l10n.mainMenuToolsTitle),
                  style: GameUiTheme.sectionHeader.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DeveloperToolButton(
              icon: Icons.map_outlined,
              label: GameText.actionLabel(l10n.mainMenuMapEditor),
              semanticLabel: l10n.mainMenuMapEditor,
              onPressed: ref.withMenuClick(() => context.go('/editor')),
            ),
            const SizedBox(height: 8),
            _DeveloperToolButton(
              icon: Icons.photo_library_outlined,
              label: GameText.actionLabel(l10n.mainMenuAssetsEditor),
              semanticLabel: l10n.mainMenuAssetsEditor,
              onPressed: ref.withMenuClick(
                () => context.go('/developer/assets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperToolButton extends StatefulWidget {
  const _DeveloperToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;

  @override
  State<_DeveloperToolButton> createState() => _DeveloperToolButtonState();
}

class _DeveloperToolButtonState extends State<_DeveloperToolButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = _hovered
        ? GameUiTheme.goldLight
        : GameUiTheme.textPrimary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: widget.semanticLabel ?? widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: _hovered
                  ? GameUiTheme.gold.withAlpha(28)
                  : GameUiTheme.surface.withAlpha(190),
              borderRadius: GameUiTheme.borderRadius,
              border: Border.all(
                color: _hovered
                    ? GameUiTheme.gold
                    : GameUiTheme.gold.withAlpha(70),
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: GameUiTheme.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.actionLabel.copyWith(color: foreground),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: GameUiTheme.gold.withAlpha(_hovered ? 220 : 130),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomLinks extends ConsumerWidget {
  const _BottomLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final links = [
      _BottomLink(
        Icons.menu_book_outlined,
        GameText.actionLabel(l10n.mainMenuManual),
        () => context.go('/manual'),
      ),
      _BottomLink(
        Icons.star_border,
        GameText.actionLabel(l10n.mainMenuCredits),
        () => context.go('/credits'),
      ),
      _BottomLink(
        Icons.chat_bubble_outline,
        GameText.actionLabel(l10n.mainMenuFeedback),
        () => unawaited(_openFeedbackUrl()),
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(224),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final link in links)
              Expanded(
                child: TextButton(
                  onPressed: ref.withMenuClick(link.onPressed),
                  style: TextButton.styleFrom(
                    foregroundColor: GameUiTheme.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 42),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: GameUiTheme.borderRadius,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(link.icon, size: 18),
                      const SizedBox(height: 3),
                      Text(
                        link.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameUiTheme.toolbarLabel.copyWith(
                          color: GameUiTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomLink {
  const _BottomLink(this.icon, this.label, this.onPressed);

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

Future<void> _openFeedbackUrl() async {
  await launchUrl(_feedbackUrl, mode: LaunchMode.externalApplication);
}

class _VersionTag extends ConsumerWidget {
  const _VersionTag();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseInfo = ref.watch(appReleaseInfoProvider);
    final label = releaseInfo.maybeWhen(
      data: (info) => info.displayLabel,
      orElse: () => AppReleaseChannel.alpha.label,
    );
    return Text(
      label,
      style: GameUiTheme.bodySmall.copyWith(
        color: GameUiTheme.goldLight.withAlpha(120),
        fontSize: 11,
      ),
    );
  }
}

class _RightInfoColumn extends StatelessWidget {
  const _RightInfoColumn();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 700) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [_WhatsNewPanel(), SizedBox(height: 10), _BottomLinks()],
      ),
    );
  }
}

class _WhatsNewPanel extends StatelessWidget {
  const _WhatsNewPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(176),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 4,
                    height: 4,
                    color: GameUiTheme.gold,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  GameText.sectionLabel(l10n.mainMenuWhatsNew),
                  style: GameUiTheme.sectionHeader,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const GoldDivider(),
            const SizedBox(height: 8),
            Text(
              l10n.mainMenuWhatsNewBody,
              style: GameUiTheme.body.copyWith(
                color: GameUiTheme.goldLight,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
