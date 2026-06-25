import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class TechnologyDetailsHeader extends StatelessWidget {
  const TechnologyDetailsHeader({
    required this.technologyId,
    required this.title,
    required this.subtitle,
    required this.l10n,
    required this.onClose,
    super.key,
  });

  final TechnologyId technologyId;
  final String title;
  final String subtitle;
  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      decoration: SurfaceElevation.raised.bandDecoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 225,
        border: BorderEmphasis.regular,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: SurfaceElevation.flat.decoration(
              accent: GameUiTheme.scienceAccent,
              background: GameUiTheme.scienceAccent,
              backgroundAlpha: 38,
              border: BorderEmphasis.regular,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: Center(
              child: TechnologySpriteIcon(
                id: technologyId,
                size: 50,
                fallback: const GameIcon(
                  GameIcons.science,
                  size: GameIconSize.large,
                  color: GameUiTheme.scienceAccent,
                ),
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
                  label: title,
                  alignment: Alignment.centerLeft,
                  accent: GameUiTheme.scienceAccent,
                  compact: false,
                  textKey: const Key('technologyDetailsHeader.title'),
                ),
                const SizedBox(height: 2),
                Text(
                  GameText.uppercase(subtitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
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
