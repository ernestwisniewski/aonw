import 'package:aonw/game/presentation/widgets/city/city_building_sorting.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class BuildingSectionHeader extends StatelessWidget {
  const BuildingSectionHeader({
    required this.label,
    required this.value,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final String label;
  final CityBuildingSortMode value;
  final bool compact;
  final ValueChanged<CityBuildingSortMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final sortChanged = onChanged;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              GameText.uppercase(label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
            ),
          ),
          if (sortChanged != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: BuildingSortSelect(
                  value: value,
                  compact: compact,
                  onChanged: sortChanged,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BuildingSortSelect extends StatelessWidget {
  const BuildingSortSelect({
    required this.value,
    required this.compact,
    required this.onChanged,
    super.key,
  });

  final CityBuildingSortMode value;
  final bool compact;
  final ValueChanged<CityBuildingSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 190 : 230),
        child: DecoratedBox(
          decoration: SurfaceElevation.flat.decoration(
            background: GameUiTheme.bg,
            backgroundAlpha: 51,
            borderColor: GameUiTheme.goldLight,
            borderAlpha: 68,
            border: BorderEmphasis.subtle,
            radius: 6,
            includeShadow: false,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: compact ? 8 : 10,
              right: compact ? 4 : 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.cityProductionSortLabel,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.textSecondary,
                    fontSize: compact ? 9.5 : 10.5,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CityBuildingSortMode>(
                      key: const Key('cityProductionList.buildingSort'),
                      value: value,
                      isDense: true,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(7),
                      dropdownColor: GameUiTheme.bg,
                      iconEnabledColor: GameUiTheme.gold,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.goldLight,
                        fontWeight: FontWeight.w800,
                      ),
                      items: [
                        for (final mode in CityBuildingSortMode.values)
                          DropdownMenuItem(
                            value: mode,
                            child: Text(
                              mode.label(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) onChanged(mode);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
