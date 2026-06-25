import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManualScreen extends ConsumerWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mobileFirst = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: GameText.screenTitle(l10n.mainMenuManual),
        onClose: ref.withMenuBack(() => context.go('/')),
      ),
      body: MenuRouteBackdrop(
        maxContentWidth: 1180,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            GameUiScreenHeader(
              icon: Icons.menu_book_outlined,
              title: l10n.manualTitle,
              subtitle: l10n.manualSubtitle,
              meta: [
                GameUiMetaPill(
                  icon: Icons.mouse_outlined,
                  label: l10n.manualMetaDesktop,
                ),
                GameUiMetaPill(
                  icon: Icons.touch_app_outlined,
                  label: l10n.manualMetaMobile,
                ),
                GameUiMetaPill(
                  icon: Icons.flag_outlined,
                  label: l10n.manualMetaAlpha,
                  color: GameUiTheme.info,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _manualSections(l10n, mobileFirst: mobileFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _manualSections(
  AppLocalizations l10n, {
  required bool mobileFirst,
}) {
  final commandLoop = [
    _SectionLead(
      key: const Key('manual.commandLoopSection'),
      icon: Icons.keyboard_double_arrow_right,
      title: l10n.manualCommandLoopTitle,
    ),
    const SizedBox(height: 10),
    _LoopGrid(items: _commandLoopItems(l10n)),
  ];
  final mobileControls = [
    _SectionLead(
      key: const Key('manual.mobileSection'),
      icon: Icons.touch_app_outlined,
      title: l10n.manualMobileTitle,
      subtitle: l10n.manualMobileSubtitle,
    ),
    const SizedBox(height: 10),
    _ControlGrid(groups: _mobileGroups(l10n)),
  ];
  final desktopControls = [
    _SectionLead(
      key: const Key('manual.desktopSection'),
      icon: Icons.mouse_outlined,
      title: l10n.manualDesktopTitle,
      subtitle: l10n.manualDesktopSubtitle,
    ),
    const SizedBox(height: 10),
    _ControlGrid(groups: _desktopGroups(l10n)),
  ];

  final sections = mobileFirst
      ? [mobileControls, commandLoop, desktopControls]
      : [commandLoop, mobileControls, desktopControls];

  return [
    for (var i = 0; i < sections.length; i += 1) ...[
      if (i > 0) const SizedBox(height: 22),
      ...sections[i],
    ],
  ];
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconFrame(icon: icon, color: GameUiTheme.goldLight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameUiEpicHeader(
                label: GameText.sectionLabel(title),
                compact: true,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LoopGrid extends StatelessWidget {
  const _LoopGrid({required this.items});

  final List<_LoopItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return _ResponsiveWrap(
          columns: columns,
          children: [
            for (var i = 0; i < items.length; i += 1)
              _LoopCard(index: i + 1, item: items[i]),
          ],
        );
      },
    );
  }
}

class _ControlGrid extends StatelessWidget {
  const _ControlGrid({required this.groups});

  final List<_ControlGroup> groups;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _ResponsiveWrap(
          columns: constraints.maxWidth >= 860 ? 2 : 1,
          children: [
            for (final group in groups) _ControlGroupCard(group: group),
          ],
        );
      },
    );
  }
}

class _ResponsiveWrap extends StatelessWidget {
  const _ResponsiveWrap({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _LoopCard extends StatelessWidget {
  const _LoopCard({required this.index, required this.item});

  final int index;
  final _LoopItem item;

  @override
  Widget build(BuildContext context) {
    return _ManualSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberBadge(index: index),
              const SizedBox(width: 10),
              Icon(item.icon, size: 20, color: GameUiTheme.goldLight),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodySmall.copyWith(height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _ControlGroupCard extends StatelessWidget {
  const _ControlGroupCard({required this.group});

  final _ControlGroup group;

  @override
  Widget build(BuildContext context) {
    return _ManualSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconFrame(icon: group.icon, color: group.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  GameText.sectionLabel(group.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.sectionHeader.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < group.items.length; i += 1) ...[
            if (i > 0)
              Divider(height: 18, color: GameUiTheme.gold.withAlpha(42)),
            _ControlRow(item: group.items[i], accent: group.color),
          ],
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.item, required this.accent});

  final _ControlItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GestureGlyph(icon: item.icon, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.action,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(height: 1.22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManualSurface extends StatelessWidget {
  const _ManualSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.raised.decoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameUiTheme.surface.withAlpha(236),
            GameUiTheme.bg.withAlpha(220),
          ],
        ),
        borderColor: GameUiTheme.gold,
        borderAlpha: 92,
        radius: 8,
        boxShadow: [
          BoxShadow(
            color: GameUiTheme.bg.withAlpha(150),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(color: GameUiTheme.gold.withAlpha(16), blurRadius: 24),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.gold.withAlpha(36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameUiTheme.gold.withAlpha(120)),
      ),
      child: SizedBox(
        width: 34,
        height: 30,
        child: Center(
          child: Text(
            index.toString().padLeft(2, '0'),
            style: GameUiTheme.toolbarLabel.copyWith(
              color: GameUiTheme.goldLight,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconFrame extends StatelessWidget {
  const _IconFrame({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _GestureGlyph extends StatelessWidget {
  const _GestureGlyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(140),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

class _LoopItem {
  const _LoopItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ControlGroup {
  const _ControlGroup({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<_ControlItem> items;
}

class _ControlItem {
  const _ControlItem({
    required this.icon,
    required this.action,
    required this.body,
  });

  final IconData icon;
  final String action;
  final String body;
}

List<_LoopItem> _commandLoopItems(AppLocalizations l10n) => [
  _LoopItem(
    icon: Icons.ads_click,
    title: l10n.manualCommandLoopSelectTitle,
    body: l10n.manualCommandLoopSelectBody,
  ),
  _LoopItem(
    icon: Icons.visibility_outlined,
    title: l10n.manualCommandLoopPreviewTitle,
    body: l10n.manualCommandLoopPreviewBody,
  ),
  _LoopItem(
    icon: Icons.check_circle_outline,
    title: l10n.manualCommandLoopConfirmTitle,
    body: l10n.manualCommandLoopConfirmBody,
  ),
  _LoopItem(
    icon: Icons.play_arrow,
    title: l10n.manualCommandLoopAdvanceTitle,
    body: l10n.manualCommandLoopAdvanceBody,
  ),
];

List<_ControlGroup> _desktopGroups(AppLocalizations l10n) => [
  _ControlGroup(
    icon: Icons.map_outlined,
    title: l10n.manualMapCameraGroup,
    color: GameUiTheme.info,
    items: [
      _ControlItem(
        icon: Icons.mouse_outlined,
        action: l10n.manualDesktopLeftClickAction,
        body: l10n.manualDesktopLeftClickBody,
      ),
      _ControlItem(
        icon: Icons.open_with,
        action: l10n.manualDesktopDragAction,
        body: l10n.manualDesktopDragBody,
      ),
      _ControlItem(
        icon: Icons.zoom_in,
        action: l10n.manualDesktopZoomAction,
        body: l10n.manualDesktopZoomBody,
      ),
      _ControlItem(
        icon: Icons.info_outline,
        action: l10n.manualDesktopHoverAction,
        body: l10n.manualDesktopHoverBody,
      ),
    ],
  ),
  _ControlGroup(
    icon: Icons.gps_fixed,
    title: l10n.manualOrdersGroup,
    color: GameUiTheme.success,
    items: [
      _ControlItem(
        icon: Icons.widgets_outlined,
        action: l10n.manualDesktopActionChipsAction,
        body: l10n.manualDesktopActionChipsBody,
      ),
      _ControlItem(
        icon: Icons.check_circle_outline,
        action: l10n.manualDesktopSecondClickAction,
        body: l10n.manualDesktopSecondClickBody,
      ),
      _ControlItem(
        icon: Icons.touch_app,
        action: l10n.manualDesktopHoldAction,
        body: l10n.manualDesktopHoldBody,
      ),
    ],
  ),
  _ControlGroup(
    icon: Icons.menu_open,
    title: l10n.manualPanelsGroup,
    color: GameUiTheme.goldLight,
    items: [
      _ControlItem(
        icon: Icons.view_sidebar_outlined,
        action: l10n.manualDesktopRailAction,
        body: l10n.manualDesktopRailBody,
      ),
      _ControlItem(
        icon: Icons.query_stats,
        action: l10n.manualDesktopTopPillsAction,
        body: l10n.manualDesktopTopPillsBody,
      ),
      _ControlItem(
        icon: Icons.close,
        action: l10n.manualDesktopCloseAction,
        body: l10n.manualDesktopCloseBody,
      ),
      _ControlItem(
        icon: Icons.help_outline,
        action: l10n.manualDesktopHelpAction,
        body: l10n.manualDesktopHelpBody,
      ),
    ],
  ),
  _ControlGroup(
    icon: Icons.flag_outlined,
    title: l10n.manualTurnFlowGroup,
    color: GameUiTheme.warning,
    items: [
      _ControlItem(
        icon: Icons.play_arrow,
        action: l10n.manualDesktopTurnAction,
        body: l10n.manualDesktopTurnBody,
      ),
    ],
  ),
];

List<_ControlGroup> _mobileGroups(AppLocalizations l10n) => [
  _ControlGroup(
    icon: Icons.map_outlined,
    title: l10n.manualMapCameraGroup,
    color: GameUiTheme.info,
    items: [
      _ControlItem(
        icon: Icons.touch_app_outlined,
        action: l10n.manualMobileTapAction,
        body: l10n.manualMobileTapBody,
      ),
      _ControlItem(
        icon: Icons.open_with,
        action: l10n.manualMobileDragAction,
        body: l10n.manualMobileDragBody,
      ),
      _ControlItem(
        icon: Icons.zoom_in,
        action: l10n.manualMobilePinchAction,
        body: l10n.manualMobilePinchBody,
      ),
      _ControlItem(
        icon: Icons.check_circle_outline,
        action: l10n.manualMobileSecondTapAction,
        body: l10n.manualMobileSecondTapBody,
      ),
    ],
  ),
  _ControlGroup(
    icon: Icons.gps_fixed,
    title: l10n.manualOrdersGroup,
    color: GameUiTheme.success,
    items: [
      _ControlItem(
        icon: Icons.widgets_outlined,
        action: l10n.manualMobileActionChipsAction,
        body: l10n.manualMobileActionChipsBody,
      ),
      _ControlItem(
        icon: Icons.touch_app,
        action: l10n.manualMobileHoldAction,
        body: l10n.manualMobileHoldBody,
      ),
      _ControlItem(
        icon: Icons.swipe,
        action: l10n.manualMobileScrollAction,
        body: l10n.manualMobileScrollBody,
      ),
    ],
  ),
  _ControlGroup(
    icon: Icons.menu_open,
    title: l10n.manualPanelsGroup,
    color: GameUiTheme.goldLight,
    items: [
      _ControlItem(
        icon: Icons.view_sidebar_outlined,
        action: l10n.manualMobileRailAction,
        body: l10n.manualMobileRailBody,
      ),
      _ControlItem(
        icon: Icons.help_outline,
        action: l10n.manualMobileHelpAction,
        body: l10n.manualMobileHelpBody,
      ),
    ],
  ),
  _ControlGroup(
    icon: Icons.flag_outlined,
    title: l10n.manualTurnFlowGroup,
    color: GameUiTheme.warning,
    items: [
      _ControlItem(
        icon: Icons.play_arrow,
        action: l10n.manualMobileTurnAction,
        body: l10n.manualMobileTurnBody,
      ),
    ],
  ),
];
