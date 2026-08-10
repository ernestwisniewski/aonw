import 'dart:async';

import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/app_exit.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw/menu/menu_animated_background.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

part 'main_menu_developer_tools.dart';
part 'main_menu_item_widgets.dart';
part 'main_menu_panel_items.dart';

final _feedbackUrl = Uri.parse('https://www.reddit.com/r/aonw/');

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key, this.onExit, this.gamepadInputListenable});

  final Future<void> Function()? onExit;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  @override
  Widget build(BuildContext context) {
    return MenuGamepadInputBinding(
      input: gamepadInputListenable,
      child: Scaffold(
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
                      child: _MenuPanel(
                        showBottomLinks: compact,
                        onExit: onExit,
                      ),
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

  void _toggleDeveloperTools() {
    setState(() => _developerOpen = !_developerOpen);
  }

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

  Future<void> _resumeMultiplayerMatchIfAllowed() async {
    if (!ref.read(mainMenuMultiplayerAccessAllowedProvider)) return;
    await _resumeMultiplayerMatch();
  }

  Future<void> _resumeMultiplayerMatch() async {
    final store = ref.read(networkSessionStoreProvider);
    final stored = await store.load();
    final matchId = stored?.matchId;
    if (stored == null || matchId == null || matchId.isEmpty) return;
    setState(() => _resumeLoading = true);
    try {
      final refreshedSession = await ref
          .read(networkSessionRefreshCoordinatorProvider)
          .ensureValidSession(forceRefresh: true);
      final match = await ref
          .read(networkSessionClientProvider)
          .loadMatch(token: refreshedSession.token, matchId: matchId);
      final playerId = _playerIdForUser(match, stored.userId);
      if (!LobbyMatchStatusRules.isRunning(match) || playerId == null) {
        await _handleResumeFailure(forgetPersistedMatch: true);
        return;
      }
      final latestSession = ref.read(networkSessionProvider);
      if (latestSession == null || latestSession.userId != stored.userId) {
        await _handleResumeFailure(forgetPersistedMatch: true);
        return;
      }
      await ref
          .read(networkSessionStateProvider.notifier)
          .activateMatch(
            expectedUserId: stored.userId,
            playerId: playerId,
            matchId: match.id,
            changedAt: ref.read(gameClockProvider).nowUtc(),
            persistMatchId: false,
          );

      if (!mounted) return;
      context.go(
        '/game?saveId=${match.id}'
        '&name=${Uri.encodeComponent(match.mapName)}'
        '&source=${MapSource.asset.name}',
      );
    } catch (error) {
      var sessionEnded = false;
      try {
        sessionEnded = await store.load() == null;
      } catch (_) {
        sessionEnded = ref.read(networkSessionProvider) == null;
      }
      await _handleResumeFailure(
        forgetPersistedMatch:
            sessionEnded || _isAuthoritativeMissingResumeMatch(error),
      );
    } finally {
      if (mounted) setState(() => _resumeLoading = false);
    }
  }

  Future<void> _handleResumeFailure({
    required bool forgetPersistedMatch,
  }) async {
    if (!mounted) return;
    if (forgetPersistedMatch) {
      final session = ref.read(networkSessionProvider);
      if (session != null) {
        await ref
            .read(networkSessionStateProvider.notifier)
            .clearMatch(
              expectedUserId: session.userId,
              changedAt: ref.read(gameClockProvider).nowUtc(),
            );
      }
      if (!mounted) return;
      setState(() => _resumeMatchId = null);
    }
    GameToast.show(
      context,
      message: context.l10n.multiplayerResumeFailed,
      tone: GameToastTone.error,
    );
  }

  bool _isAuthoritativeMissingResumeMatch(Object error) {
    if (error is! MultiplayerFailure || !error.isMultiplayer) return false;
    return error.code == 'match_not_found' || error.code == 'not_match_player';
  }

  String? _playerIdForUser(WireMatch match, String userId) {
    for (final player in match.players) {
      if (player.userId == userId) return player.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = _menuItems(
      context,
      multiplayerAccessAllowed: ref.watch(
        mainMenuMultiplayerAccessAllowedProvider,
      ),
    );

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
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.3);

    return MenuGamepadAction(
      onActivate: item.onPressed,
      borderRadius: GameUiTheme.borderRadius,
      builder: (context, focused) {
        final highlighted = focused || _hovered || item.primary || item.active;
        final borderColor = highlighted
            ? GameUiTheme.gold
            : GameUiTheme.gold.withAlpha(110);
        final iconColor = highlighted ? GameUiTheme.gold : GameUiTheme.goldDark;
        final textColor = item.primary || item.active || focused
            ? GameUiTheme.goldLight
            : GameUiTheme.textPrimary;
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
                        color: GameUiTheme.gold.withAlpha(
                          _hovered || focused ? 70 : 42,
                        ),
                        blurRadius: _hovered || focused ? 16 : 9,
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
                          color: GameUiTheme.gold.withAlpha(
                            highlighted ? 138 : 74,
                          ),
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
                        color: GameUiTheme.gold.withAlpha(
                          highlighted ? 220 : 110,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      orElse: () => AppReleaseChannel.stable.label,
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

class _WhatsNewPanel extends ConsumerWidget {
  const _WhatsNewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final updateNotice = _updateNoticeFor(ref);
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
            if (updateNotice != null) ...[
              _UpdateNoticeBlock(notice: updateNotice),
              const SizedBox(height: 10),
              const GoldDivider(),
              const SizedBox(height: 8),
            ],
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

class _UpdateNoticeBlock extends StatelessWidget {
  const _UpdateNoticeBlock({required this.notice});

  final MainMenuUpdateNotice notice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const color = GameUiTheme.goldLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.system_update_alt_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameText.sectionLabel(notice.title(l10n)),
                style: GameUiTheme.sectionHeader.copyWith(color: color),
              ),
              const SizedBox(height: 5),
              Text(
                notice.body(l10n),
                style: GameUiTheme.body.copyWith(
                  color: GameUiTheme.goldLight,
                  fontSize: 11.5,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

MainMenuUpdateNotice? _updateNoticeFor(WidgetRef ref) {
  final notice = ref.watch(mainMenuUpdateNoticeProvider);
  return notice is AsyncData<MainMenuUpdateNotice?> ? notice.value : null;
}
