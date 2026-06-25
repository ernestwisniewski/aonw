import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

class SelectionImprovementList extends StatelessWidget {
  const SelectionImprovementList({
    required this.items,
    required this.density,
    super.key,
  });

  final List<SelectionImprovementItem> items;
  final SelectionDensity density;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final compact = density == SelectionDensity.compact;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectionImprovementListTitle,
          style: const TextStyle(
            color: GameHudTheme.textBright,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        if (compact)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 236),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _ImprovementCard(item: items[i], fullWidth: true),
                  ],
                ],
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _ImprovementCard(item: items[i], fullWidth: false),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({required this.item, required this.fullWidth});

  final SelectionImprovementItem item;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(item.state);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: fullWidth ? double.infinity : 210,
      padding: const EdgeInsets.all(10),
      decoration: SurfaceElevation.flat.decoration(
        background: HudPalette.surfaceDeep,
        backgroundAlpha: 255,
        borderColor: accent,
        borderAlpha: 170,
        radius: GameHudTheme.panelRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GameHudTheme.textBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RequirementChip(
                label: _stateLabel(l10n, item.state),
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final part in _yieldParts(l10n, item.yield))
                _RequirementChip(label: part, accent: accent),
              _RequirementChip(
                label: l10n.turnCountLabel(item.buildTurns),
                accent: GameHudTheme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final requirement in [
            item.technologyRequirement,
            item.buildingRequirement,
            item.cityRequirement,
          ])
            if (requirement.isNotEmpty) _RequirementLine(text: requirement),
        ],
      ),
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: GameHudTheme.textMuted,
          fontSize: 11,
          height: 1.15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(background: accent, alpha: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameHudTheme.panelRadius),
          side: BorderSide(
            color: SurfaceElevation.flat.strokeColor(color: accent, alpha: 82),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Color _accentFor(SelectionImprovementState state) {
  return switch (state) {
    SelectionImprovementState.built => GameHudTheme.success,
    SelectionImprovementState.available => GameHudTheme.success,
    SelectionImprovementState.needsTechnology => GameHudTheme.colorWarning,
    SelectionImprovementState.needsCity => GameHudTheme.info,
    SelectionImprovementState.blocked => GameHudTheme.textMuted,
  };
}

String _stateLabel(AppLocalizations l10n, SelectionImprovementState state) {
  return switch (state) {
    SelectionImprovementState.built => l10n.selectionImprovementStateBuilt,
    SelectionImprovementState.available =>
      l10n.selectionImprovementStateAvailable,
    SelectionImprovementState.needsTechnology =>
      l10n.selectionImprovementStateNeedsTechnology,
    SelectionImprovementState.needsCity =>
      l10n.selectionImprovementStateNeedsCity,
    SelectionImprovementState.blocked => l10n.selectionImprovementStateBlocked,
  };
}

List<String> _yieldParts(AppLocalizations l10n, TileYield yield) {
  final parts = <String>[];
  if (yield.food > 0) parts.add('${yield.food}F');
  if (yield.production > 0) parts.add('${yield.production}P');
  if (yield.gold > 0) parts.add('${yield.gold}G');
  if (yield.defense > 0) parts.add('${yield.defense}D');
  return parts.isEmpty ? [l10n.selectionImprovementNoBonus] : parts;
}
