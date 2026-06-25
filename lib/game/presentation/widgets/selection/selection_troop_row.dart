import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class SelectionTroopRow extends StatelessWidget {
  const SelectionTroopRow({
    required this.troop,
    required this.density,
    this.onDetach,
    super.key,
  });

  final ArmyTroopViewModel troop;
  final SelectionDensity density;
  final ValueChanged<TroopType>? onDetach;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spec = SelectionDensitySpec.of(density);
    final detachColor = onDetach == null
        ? SurfaceElevation.flat.fill(
            background: GameUiTheme.textSecondary,
            alpha: 95,
          )
        : GameUiTheme.textSecondary;

    return Row(
      children: [
        GameIcon(
          troop.icon,
          size: spec.troopIconSize,
          color: GameUiTheme.textSecondary,
        ),
        SizedBox(width: spec.troopIconGap),
        Expanded(child: Text(troop.name, style: GameUiTheme.bodyStrong)),
        Text('${troop.count}', style: GameUiTheme.bodySmall),
        const SizedBox(width: 4),
        IconButton(
          tooltip: l10n.selectionTroopDetachTooltip(troop.name.toLowerCase()),
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tightFor(
            width: spec.troopDetachButtonWidth,
            height: spec.troopDetachButtonHeight,
          ),
          padding: EdgeInsets.zero,
          iconSize: spec.troopDetachIconSize,
          color: detachColor,
          onPressed: onDetach == null ? null : () => onDetach!(troop.type),
          icon: GameIcon(
            GameIcons.split,
            size: spec.troopDetachIconSize,
            color: detachColor,
          ),
        ),
      ],
    );
  }
}
