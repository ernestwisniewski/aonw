import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_artifact_step_pill.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_inspection_components.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:flutter/material.dart';

class HudArtifactInspectionPopover extends StatelessWidget {
  const HudArtifactInspectionPopover({
    required this.artifact,
    required this.onClose,
    required this.arrowOnLeft,
    required this.arrowTop,
    required this.maxHeight,
    super.key,
  });

  final WorldArtifact artifact;
  final VoidCallback onClose;
  final bool arrowOnLeft;
  final double arrowTop;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return HudMapInspectionPopoverFrame(
      arrowOnLeft: arrowOnLeft,
      arrowTop: arrowTop,
      maxHeight: maxHeight,
      borderAlpha: 168,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArtifactHeader(artifact: artifact, onClose: onClose),
            const SizedBox(height: 10),
            HudMapInspectionSection(
              icon: GameIcons.info,
              title: l10n.commonDescription,
              child: _ArtifactDescription(artifact: artifact),
            ),
            const SizedBox(height: 8),
            HudMapInspectionSection(
              icon: GameIcons.artifact,
              title: l10n.worldArtifactBonusTitle,
              child: HudMapInspectionValueLine(
                value: GameDisplayNames.worldArtifactShortBonus(
                  l10n,
                  artifact.type,
                ),
                color: GameUiTheme.goldLight,
              ),
            ),
            const SizedBox(height: 8),
            HudMapInspectionSection(
              icon: GameIcons.victory,
              title: l10n.worldArtifactHeritageTitle,
              child: Text(
                l10n.worldArtifactHeritageBody,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtifactHeader extends StatelessWidget {
  const _ArtifactHeader({required this.artifact, required this.onClose});

  final WorldArtifact artifact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: GameUiTheme.gold.withAlpha(42),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameUiTheme.gold.withAlpha(170)),
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.artifact,
              size: 20,
              color: GameUiTheme.goldLight,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameDisplayNames.worldArtifact(l10n, artifact.type),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                GameDisplayNames.worldArtifactLocation(l10n, artifact.location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionSubtitle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          key: const Key('hudMapInspectionMenu.artifact.close'),
          tooltip: l10n.closeAction,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          onPressed: onClose,
          icon: const GameIcon(
            GameIcons.close,
            size: 15,
            color: GameUiTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ArtifactDescription extends StatelessWidget {
  const _ArtifactDescription({required this.artifact});

  final WorldArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GameDisplayNames.worldArtifactDescription(l10n, artifact.type),
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            height: 1.22,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            HudArtifactStepPill(
              icon: GameIcons.shovel,
              label: l10n.worldArtifactStepExcavate,
            ),
            HudArtifactStepPill(
              icon: GameIcons.move,
              label: l10n.worldArtifactStepMove,
            ),
            HudArtifactStepPill(
              icon: GameIcons.storeArtifact,
              label: l10n.worldArtifactStepStore,
            ),
          ],
        ),
      ],
    );
  }
}
