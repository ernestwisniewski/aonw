import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/menu/manual_models.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class ManualSectionLead extends StatelessWidget {
  const ManualSectionLead({
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

class ManualLoopGrid extends StatelessWidget {
  const ManualLoopGrid({required this.items, super.key});

  final List<ManualLoopItem> items;

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
            for (var i = 0; i < items.length; i++)
              _LoopCard(index: i + 1, item: items[i]),
          ],
        );
      },
    );
  }
}

class ManualControlGrid extends StatelessWidget {
  const ManualControlGrid({required this.groups, super.key});

  final List<ManualControlGroup> groups;

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
  final ManualLoopItem item;

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

  final ManualControlGroup group;

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
          for (var i = 0; i < group.items.length; i++) ...[
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

  final ManualControlItem item;
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
