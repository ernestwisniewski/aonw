import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_wonder_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_content_scroll_view.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_layout.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

part 'wonder_details_content.dart';
part 'wonder_details_widgets.dart';

class WonderDetailsDialog extends StatelessWidget {
  const WonderDetailsDialog({
    required this.wonderType,
    required this.definition,
    required this.unlockingTechnology,
    required this.l10n,
    required this.title,
    required this.statusLabel,
    required this.costLabel,
    this.progressLabel,
    this.paceLabel,
    required this.onClose,
    super.key,
  });

  final WonderType wonderType;
  final WonderDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final AppLocalizations l10n;
  final String title;
  final String statusLabel;
  final String costLabel;
  final String? progressLabel;
  final String? paceLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WonderDetailsPanel(
      wonderType: wonderType,
      definition: definition,
      unlockingTechnology: unlockingTechnology,
      l10n: l10n,
      title: title,
      statusLabel: statusLabel,
      costLabel: costLabel,
      progressLabel: progressLabel,
      paceLabel: paceLabel,
      maxHeight: GameModalLayout.detailsMaxHeight(size.height * 0.78),
      onClose: onClose,
    );
  }
}

class WonderDetailsPanel extends StatelessWidget {
  const WonderDetailsPanel({
    required this.wonderType,
    required this.definition,
    required this.unlockingTechnology,
    required this.l10n,
    required this.title,
    required this.statusLabel,
    required this.costLabel,
    this.progressLabel,
    this.paceLabel,
    this.maxWidth = 560,
    this.maxHeight,
    required this.onClose,
    super.key,
  });

  final WonderType wonderType;
  final WonderDefinition definition;
  final TechnologyDefinition? unlockingTechnology;
  final AppLocalizations l10n;
  final String title;
  final String statusLabel;
  final String costLabel;
  final String? progressLabel;
  final String? paceLabel;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxHeight = GameModalLayout.detailsMaxHeight(maxHeight);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: effectiveMaxHeight,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('wonderDetailsPanel.surface'),
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WonderDetailsHeader(title: title, l10n: l10n, onClose: onClose),
            Flexible(
              child: GameModalContentScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Text(
                    WonderDisplayNames.description(l10n, wonderType),
                    style: GameUiTheme.body.copyWith(
                      color: GameUiTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _WonderDetailChip(
                        label: l10n.technologyDetailsStatus,
                        value: statusLabel,
                      ),
                      _WonderDetailChip(
                        label: l10n.technologyDetailsCost,
                        value: costLabel,
                      ),
                      if (progressLabel != null)
                        _WonderDetailChip(
                          label: l10n.technologyDetailsProgress,
                          value: progressLabel!,
                        ),
                      if (paceLabel != null)
                        _WonderDetailChip(
                          label: l10n.unitDetailsPace,
                          value: paceLabel!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WonderDetailsSection(
                    title: l10n.technologyDetailsPrerequisites,
                    lines: _wonderRequirementLines(
                      l10n,
                      definition,
                      unlockingTechnology,
                    ),
                  ),
                  _WonderDetailsSection(
                    title: l10n.wonderDetailsStandingEffects,
                    lines: _wonderStandingEffectLines(l10n, definition),
                  ),
                  _WonderDetailsSection(
                    title: l10n.wonderDetailsCompletionEffects,
                    lines: _wonderCompletionEffectLines(l10n, definition),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
