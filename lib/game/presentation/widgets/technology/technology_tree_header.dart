import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class TechnologyTreeHeader extends StatelessWidget {
  const TechnologyTreeHeader({
    required this.sciencePerTurn,
    required this.l10n,
    this.compact = false,
    required this.onClose,
    super.key,
  });

  final int sciencePerTurn;
  final AppLocalizations l10n;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 32.0 : 38.0;

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 8, 6, 8)
          : const EdgeInsets.fromLTRB(16, 14, 10, 12),
      decoration: SurfaceElevation.raised.bandDecoration(
        gradient: LinearGradient(
          colors: [
            SurfaceElevation.raised.fill(
              background: GameUiTheme.chipSurface,
              alpha: 230,
            ),
            SurfaceElevation.raised.fill(
              background: GameUiTheme.surfaceDeep,
              alpha: 235,
            ),
          ],
        ),
        border: BorderEmphasis.regular,
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: SurfaceElevation.flat.decoration(
              accent: GameUiTheme.scienceAccent,
              background: GameUiTheme.scienceAccent,
              backgroundAlpha: 38,
              border: BorderEmphasis.regular,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: const Center(
              child: GameIcon(
                GameIcons.science,
                size: GameIconSize.regular,
                color: GameUiTheme.scienceAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GameUiEpicHeader(
                  label: l10n.technologyTreeTitle,
                  alignment: Alignment.centerLeft,
                  accent: GameUiTheme.scienceAccent,
                  compact: compact,
                  textKey: const Key('technologyTreeHeader.title'),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.sciencePerTurn(sciencePerTurn),
                  style: GameUiTheme.bodySmall.copyWith(
                    color: GameUiTheme.textMuted,
                    fontSize: compact ? 10 : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: compact
                ? VisualDensity.compact
                : VisualDensity.standard,
            constraints: compact
                ? const BoxConstraints.tightFor(width: 40, height: 40)
                : null,
            tooltip: l10n.closeAction,
            onPressed: onClose,
            icon: const GameIcon(
              GameIcons.close,
              size: GameIconSize.regular,
              color: GameUiTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnologyActiveResearchBanner extends StatelessWidget {
  const TechnologyActiveResearchBanner({
    required this.card,
    required this.l10n,
    this.compact = false,
    super.key,
  });

  final TechnologyCardViewModel card;
  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 9, 12, 9)
          : const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TechnologySpriteIcon(
                id: card.id,
                size: compact ? 24 : 28,
                fallback: const GameIcon(
                  GameIcons.science,
                  size: GameIconSize.regular,
                  color: GameUiTheme.scienceAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.activeResearchLabel,
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.scienceAccent,
                  fontSize: compact ? 9 : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  GameDisplayNames.technology(l10n, card.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.body.copyWith(
                    color: GameUiTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 12 : null,
                  ),
                ),
              ),
              Text(
                card.turnsRemaining == null
                    ? l10n.technologyResearchPointsShort(
                        card.totalCost - card.progress,
                      )
                    : card.eta.compactLabel(l10n),
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 10 : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: card.progressRatio,
              minHeight: compact ? 4 : 5,
              backgroundColor: SurfaceElevation.flat.fill(
                background: GameUiTheme.scienceAccent,
                alpha: 34,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(
                GameUiTheme.scienceAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
