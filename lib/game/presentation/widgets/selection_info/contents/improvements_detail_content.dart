import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ImprovementsDetailContent extends StatelessWidget {
  final SelectionImprovementsDetail model;
  final bool compact;

  const ImprovementsDetailContent({
    required this.model,
    required this.compact,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (model.improvements.isEmpty) {
      return Text(
        AppLocalizations.of(context).mapInspectionNoPossibleImprovements,
        style: const TextStyle(
          color: GameHudTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return SelectionImprovementList(
      items: model.improvements,
      density: compact
          ? SelectionDensity.compact
          : SelectionDensity.comfortable,
    );
  }
}
