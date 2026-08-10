import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/visual/game_insight_widgets.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

part 'resource_detail_primitives.dart';
part 'resource_value_card_tile.dart';

class ResourcesDetailContent extends StatelessWidget {
  const ResourcesDetailContent({
    required this.model,
    required this.compact,
    super.key,
  });

  final SelectionResourcesDetail model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (model.valueCards.isNotEmpty) {
      return _ResourceValueCardList(
        cards: model.valueCards,
        compact: compact,
        l10n: l10n,
      );
    }
    if (model.resourceLabels.isEmpty) {
      return Text(
        l10n.resourceDetailNoResourcesOnTile,
        style: const TextStyle(
          color: GameHudTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in model.resourceLabels) _ResourceTile(label: label),
      ],
    );
  }
}

class _ResourceValueCardList extends StatelessWidget {
  const _ResourceValueCardList({
    required this.cards,
    required this.compact,
    required this.l10n,
  });

  final List<SelectionResourceValueCard> cards;
  final bool compact;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          _ResourceValueCardTile(
            card: cards[index],
            compact: compact,
            l10n: l10n,
          ),
          if (index < cards.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 190,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(GameHudTheme.panelRadius),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameIcon(
              GameIcons.resources,
              size: GameIconSize.small,
              color: GameUiTheme.gold,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: GameHudTheme.textBright,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
