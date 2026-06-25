import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/technology_tree_labels.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_unlocks_section.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class TechnologyRecommendationsView extends StatelessWidget {
  const TechnologyRecommendationsView({
    required this.viewModel,
    required this.l10n,
    required this.compact,
    required this.onResearch,
    required this.onTechnologyDetails,
    super.key,
  });

  final TechnologyPanelViewModel viewModel;
  final AppLocalizations l10n;
  final bool compact;
  final ValueChanged<TechnologyId> onResearch;
  final ValueChanged<TechnologyCardViewModel> onTechnologyDetails;

  @override
  Widget build(BuildContext context) {
    final recommendations = viewModel.recommendedTechnologies;
    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 12, 12, 14)
          : const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recommendations.isEmpty)
            _NoRecommendationsMessage(l10n: l10n)
          else
            _RecommendationCardsLayout(
              cards: recommendations,
              compact: compact,
              l10n: l10n,
              onResearch: onResearch,
              onTechnologyDetails: onTechnologyDetails,
            ),
        ],
      ),
    );
  }
}

class _RecommendationCardsLayout extends StatelessWidget {
  const _RecommendationCardsLayout({
    required this.cards,
    required this.compact,
    required this.l10n,
    required this.onResearch,
    required this.onTechnologyDetails,
  });

  final List<TechnologyCardViewModel> cards;
  final bool compact;
  final AppLocalizations l10n;
  final ValueChanged<TechnologyId> onResearch;
  final ValueChanged<TechnologyCardViewModel> onTechnologyDetails;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 760 && !compact;
        if (!horizontal) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _RecommendationCard(
                  rank: i + 1,
                  card: cards[i],
                  compact: compact,
                  l10n: l10n,
                  onResearch: onResearch,
                  onTechnologyDetails: onTechnologyDetails,
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _RecommendationCard(
                  rank: i + 1,
                  card: cards[i],
                  compact: compact,
                  l10n: l10n,
                  onResearch: onResearch,
                  onTechnologyDetails: onTechnologyDetails,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.rank,
    required this.card,
    required this.compact,
    required this.l10n,
    required this.onResearch,
    required this.onTechnologyDetails,
  });

  final int rank;
  final TechnologyCardViewModel card;
  final bool compact;
  final AppLocalizations l10n;
  final ValueChanged<TechnologyId> onResearch;
  final ValueChanged<TechnologyCardViewModel> onTechnologyDetails;

  @override
  Widget build(BuildContext context) {
    final name = GameDisplayNames.technology(l10n, card.id);
    final unlocks = TechnologyTreeLabels.unlocksLabel(l10n, card);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          background: const Color(0xFF1D2630),
          backgroundAlpha: 245,
          borderColor: rank == 1
              ? GameUiTheme.scienceAccent
              : const Color(0xFF788EA7),
          borderAlpha: rank == 1 ? 210 : 150,
          border: BorderEmphasis.active,
          borderRadius: BorderRadius.circular(7),
          includeShadow: false,
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TechnologySpriteIcon(
                    id: card.id,
                    size: compact ? 38 : 44,
                    fallback: const GameIcon(
                      GameIcons.science,
                      size: GameIconSize.regular,
                      color: GameUiTheme.scienceAccent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GameUiTheme.bodyStrong.copyWith(
                            color: GameUiTheme.textBright,
                            fontSize: compact ? 12 : 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          GameText.uppercase(
                            GameDisplayNames.technologyEra(l10n, card.era),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameUiTheme.toolbarLabel.copyWith(
                            color: GameUiTheme.textMuted,
                            fontSize: compact ? 8.5 : 9,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  UnlockHelpButton(
                    tooltip: l10n.technologyDetailsTooltip,
                    onPressed: () => onTechnologyDetails(card),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoPill(
                    icon: GameIcons.hourglass,
                    label: card.eta.compactLabel(l10n),
                    color: GameUiTheme.scienceAccent,
                  ),
                  _InfoPill(
                    icon: GameIcons.stats,
                    label: '${card.progress}/${card.totalCost}',
                    color: GameUiTheme.info,
                  ),
                  if (card.boostActive)
                    _InfoPill(
                      icon: GameIcons.lightning,
                      label: l10n.technologyBoostActiveBadge,
                      color: GameUiTheme.gold,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _RecommendationSection(
                title: l10n.technologyRecommendationReasonSection,
                body: _reasonFor(card),
              ),
              const SizedBox(height: 8),
              _RecommendationSection(
                title: l10n.technologyRecommendationUnlocks,
                body: unlocks,
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                height: compact ? 34 : 38,
                child: ElevatedButton.icon(
                  onPressed: () => onResearch(card.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameUiTheme.info,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const GameIcon(
                    GameIcons.science,
                    size: GameIconSize.small,
                    color: Colors.white,
                  ),
                  label: Text(
                    l10n.technologyButtonResearch,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.actionLabel.copyWith(
                      color: Colors.white,
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reasonFor(TechnologyCardViewModel card) {
    if (card.boostActive) return l10n.technologyRecommendationReasonBoost;
    if (card.unlocks.whereType<UnlockFieldImprovement>().isNotEmpty) {
      return l10n.technologyRecommendationReasonImprovements;
    }
    if (card.unlocks.whereType<UnlockCityBuilding>().isNotEmpty) {
      return l10n.technologyRecommendationReasonBuilding;
    }
    if (card.unlocks.whereType<UnlockUnitType>().isNotEmpty) {
      return l10n.technologyRecommendationReasonUnit;
    }
    if (card.effects.isNotEmpty) {
      return l10n.technologyRecommendationReasonEffect;
    }
    if (card.turnsRemaining != null && card.turnsRemaining! <= 3) {
      return l10n.technologyRecommendationReasonFast;
    }
    return l10n.technologyRecommendationReasonDefault;
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          GameText.uppercase(title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.scienceAccent,
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final GameIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: color,
        backgroundAlpha: 24,
        borderColor: color,
        borderAlpha: 130,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(icon, size: GameIconSize.tiny, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRecommendationsMessage extends StatelessWidget {
  const _NoRecommendationsMessage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 120,
        border: BorderEmphasis.subtle,
        borderRadius: BorderRadius.circular(7),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          l10n.technologyNoRecommendations,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
