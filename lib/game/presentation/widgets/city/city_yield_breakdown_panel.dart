import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_row_widgets.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/city/city_yield_source_charts.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:flutter/material.dart';

class CityYieldBreakdownPanel extends StatelessWidget {
  const CityYieldBreakdownPanel({required this.model, super.key});

  final CityYieldBreakdownViewModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: SurfaceElevation.flat.bandDecoration(
        background: GameUiTheme.surface,
        backgroundAlpha: 150,
        border: BorderEmphasis.subtle,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BreakdownHeader(model: model, compact: compact),
              const SizedBox(height: 10),
              CityYieldSourceCharts(model: model, compact: compact),
              const SizedBox(height: 10),
              CityYieldBreakdownRows(rows: model.rows, compact: compact),
            ],
          );
        },
      ),
    );
  }
}

class _BreakdownHeader extends StatelessWidget {
  const _BreakdownHeader({required this.model, required this.compact});

  final CityYieldBreakdownViewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 280 : 340),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GameUiEpicHeader(
                label: l10n.cityYieldBreakdownTitle,
                alignment: Alignment.centerLeft,
                compact: true,
                textKey: const Key('cityYieldBreakdown.title'),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.cityYieldBreakdownSubtitle(
                  model.growthLabel,
                  model.growthEta.compactLabel(l10n),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        CityYieldChips(yield: model.totalYield, compact: compact),
      ],
    );
  }
}
