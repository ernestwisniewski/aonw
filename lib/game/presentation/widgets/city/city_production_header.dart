import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class CityProductionHeader extends StatelessWidget {
  const CityProductionHeader({
    required this.cityName,
    required this.title,
    required this.productionPerTurnLabel,
    required this.playerGold,
    required this.closeTooltip,
    required this.onClose,
    this.compact = false,
    super.key,
  });

  final String cityName;
  final String title;
  final String productionPerTurnLabel;
  final int playerGold;
  final String closeTooltip;
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iconSize = compact ? 32.0 : 38.0;

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 10, 8, 9)
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
              background: GameUiTheme.gold,
              backgroundAlpha: 28,
              border: BorderEmphasis.regular,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: const Center(
              child: GameIcon(
                GameIcons.production,
                size: GameIconSize.regular,
                color: GameUiTheme.goldLight,
              ),
            ),
          ),
          SizedBox(width: compact ? 9 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GameUiEpicHeader(
                  label: cityName,
                  alignment: Alignment.centerLeft,
                  compact: compact,
                  textKey: const Key('cityProductionHeader.cityName'),
                ),
                SizedBox(height: compact ? 1 : 2),
                Text(
                  l10n.cityProductionHeaderSubtitle(
                    title,
                    productionPerTurnLabel,
                    playerGold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.bodySmall.copyWith(
                    color: GameUiTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: compact ? VisualDensity.compact : null,
            tooltip: closeTooltip,
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

class CityProductionSectionTitle extends StatelessWidget {
  const CityProductionSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        GameText.uppercase(label),
        style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
      ),
    );
  }
}
