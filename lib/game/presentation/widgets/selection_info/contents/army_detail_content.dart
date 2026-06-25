import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class ArmyDetailContent extends StatelessWidget {
  final SelectionArmyDetail model;
  final ValueChanged<TroopType>? onDetachTroop;

  const ArmyDetailContent({
    required this.model,
    required this.onDetachTroop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (model.troops.isEmpty) {
      return SelectionEmptyMessage(label: l10n.selectionArmyEmpty);
    }

    final troops = [
      for (final troop in model.troops)
        ArmyTroopViewModel.fromTroop(troop, l10n),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final troop in troops)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SelectionTroopRow(
              troop: troop,
              density: SelectionDensity.comfortable,
              onDetach: onDetachTroop,
            ),
          ),
      ],
    );
  }
}
