import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:flutter/material.dart';

class HelpPopupsButton extends StatefulWidget {
  const HelpPopupsButton({
    required this.open,
    required this.count,
    required this.onPressed,
    required this.attentionSequence,
    this.bare = false,
    super.key,
  });

  final bool open;
  final int count;
  final VoidCallback onPressed;
  final int attentionSequence;
  final bool bare;

  @override
  State<HelpPopupsButton> createState() => _HelpPopupsButtonState();
}

class _HelpPopupsButtonState extends State<HelpPopupsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _attentionController;
  int _lastAttentionSequence = 0;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener(_handleAttentionStatus);
    _lastAttentionSequence = widget.attentionSequence;
    if (widget.attentionSequence > 0) _startAttentionGlow();
  }

  @override
  void didUpdateWidget(covariant HelpPopupsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attentionSequence <= 0 ||
        widget.attentionSequence == _lastAttentionSequence) {
      return;
    }
    _lastAttentionSequence = widget.attentionSequence;
    _startAttentionGlow();
  }

  @override
  void dispose() {
    _attentionController
      ..removeStatusListener(_handleAttentionStatus)
      ..dispose();
    super.dispose();
  }

  void _startAttentionGlow() {
    unawaited(_attentionController.forward(from: 0));
  }

  void _handleAttentionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final button = GameUiSideMenuButton(
      buttonKey: const Key('gameOptions.helpPopupsButton'),
      open: widget.open,
      tooltip: l10n.helpPopupsTitle,
      badgeLabel: widget.count > 0 ? '${widget.count}' : null,
      iconBuilder: (color) => GameIcon(GameIcons.help, size: 18, color: color),
      onPressed: widget.onPressed,
      bare: widget.bare,
    );

    return AnimatedBuilder(
      animation: _attentionController,
      child: button,
      builder: (context, child) {
        final progress = _attentionController.value;
        final envelope = (1 - progress).clamp(0.0, 1.0);
        final wave = (math.sin(progress * math.pi * 12) + 1) / 2;
        final intensity = envelope * (0.35 + 0.65 * wave);
        if (!_attentionController.isAnimating || intensity <= 0.01) {
          return child!;
        }
        return Transform.scale(
          scale: 1 + intensity * 0.05,
          child: DecoratedBox(
            key: const Key('gameOptions.helpPopupsButton.attentionGlow'),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: GameUiTheme.borderRadius,
              ),
              shadows: [
                BoxShadow(
                  color: GameUiTheme.goldLight.withAlpha(
                    (160 * intensity).round(),
                  ),
                  blurRadius: 9 + 13 * intensity,
                  spreadRadius: 1 + 4 * intensity,
                ),
                BoxShadow(
                  color: GameUiTheme.gold.withAlpha((95 * intensity).round()),
                  blurRadius: 18 + 16 * intensity,
                  spreadRadius: 2 + 5 * intensity,
                ),
              ],
            ),
            child: child!,
          ),
        );
      },
    );
  }
}

class HelpPopupsPanel extends StatelessWidget {
  const HelpPopupsPanel({
    required this.width,
    required this.entries,
    required this.onActivate,
    super.key,
  });

  final double width;
  final List<HudMinimizedPopupEntry> entries;
  final ValueChanged<HudMinimizedPopupEntry> onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      borderRadius: GameUiTheme.borderRadius,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: SurfaceElevation.flat.decoration(
          background: GameUiTheme.bg,
          backgroundAlpha: 235,
          borderRadius: GameUiTheme.borderRadius,
          border: BorderEmphasis.regular,
          includeShadow: false,
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameUiEpicHeader(
              label: GameText.sectionLabel(l10n.helpPopupsTitle),
              textKey: const Key('gameOptions.helpPanelTitle'),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < entries.length; i++) ...[
              _HelpPopupRow(entry: entries[i], onActivate: onActivate),
              if (i != entries.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpPopupRow extends StatelessWidget {
  const _HelpPopupRow({required this.entry, required this.onActivate});

  final HudMinimizedPopupEntry entry;
  final ValueChanged<HudMinimizedPopupEntry> onActivate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = _categoryFor(l10n, entry.kind);
    return Material(
      color: SurfaceElevation.flat.fill(
        background: GameUiTheme.surface,
        alpha: 150,
      ),
      borderRadius: GameUiTheme.borderRadius,
      child: InkWell(
        key: Key('gameOptions.helpPopup.${entry.id}'),
        borderRadius: GameUiTheme.borderRadius,
        onTap: () => onActivate(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Row(
            children: [
              GameIcon(
                _iconFor(entry.kind),
                size: 17,
                color: GameUiTheme.goldLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 5),
                      _HelpPopupCategoryPill(category),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _HelpPopupCategory? _categoryFor(
    AppLocalizations l10n,
    HudMinimizedPopupKind kind,
  ) {
    switch (kind) {
      case HudMinimizedPopupKind.diplomaticMessage:
      case HudMinimizedPopupKind.diplomaticProposal:
        return _HelpPopupCategory(
          label: l10n.activityLogFilterDiplomacy,
          color: GameUiTheme.info,
        );
      case HudMinimizedPopupKind.technologyDiscovery:
        return _HelpPopupCategory(
          label: l10n.activityLogFilterTechnology,
          color: GameUiTheme.scienceAccent,
        );
      case HudMinimizedPopupKind.firstTurnCoachmarks:
      case HudMinimizedPopupKind.modeBanner:
      case HudMinimizedPopupKind.autoTurnHint:
        return null;
    }
  }

  GameIconData _iconFor(HudMinimizedPopupKind kind) {
    switch (kind) {
      case HudMinimizedPopupKind.firstTurnCoachmarks:
        return GameIcons.help;
      case HudMinimizedPopupKind.modeBanner:
        return GameIcons.flag;
      case HudMinimizedPopupKind.technologyDiscovery:
        return GameIcons.science;
      case HudMinimizedPopupKind.diplomaticMessage:
      case HudMinimizedPopupKind.diplomaticProposal:
        return GameIcons.diplomacy;
      case HudMinimizedPopupKind.autoTurnHint:
        return GameIcons.skipTurn;
    }
  }
}

class _HelpPopupCategory {
  const _HelpPopupCategory({required this.label, required this.color});

  final String label;
  final Color color;
}

class _HelpPopupCategoryPill extends StatelessWidget {
  const _HelpPopupCategoryPill(this.category);

  final _HelpPopupCategory category;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          background: GameUiTheme.chipSurface,
          backgroundAlpha: 180,
          border: BorderEmphasis.subtle,
          shape: SurfaceShape.chip,
          includeShadow: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          child: Text(
            category.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.chipLabel.copyWith(
              color: category.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
