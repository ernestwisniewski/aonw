import 'package:aonw/game/presentation/widgets/city/city_yield_breakdown_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter/material.dart';

class CityYieldBreakdownRows extends StatelessWidget {
  const CityYieldBreakdownRows({
    required this.rows,
    required this.compact,
    super.key,
  });

  final List<CityYieldBreakdownRow> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = compact ? 6.0 : 8.0;
        final itemWidth = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final row in rows)
              SizedBox(
                width: itemWidth,
                child: _BreakdownRow(row: row, compact: compact),
              ),
          ],
        );
      },
    );
  }
}

class CityYieldChips extends StatelessWidget {
  const CityYieldChips({
    required this.yield,
    required this.compact,
    this.dense = false,
    super.key,
  });

  final TileYield yield;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: dense ? 3 : 5,
      runSpacing: dense ? 3 : 5,
      children: [
        _chip(
          GameIcons.food,
          l10n.yieldFoodShort,
          yield.food,
          const Color(0xFF87c96a),
        ),
        _chip(
          GameIcons.production,
          l10n.yieldProductionShort,
          yield.production,
          const Color(0xFFc9a95f),
        ),
        _chip(
          GameIcons.gold,
          l10n.yieldGoldShort,
          yield.gold,
          const Color(0xFFe0c35c),
        ),
        _chip(
          GameIcons.defense,
          l10n.yieldDefenseShort,
          yield.defense,
          const Color(0xFF8da8e8),
        ),
      ],
    );
  }

  Widget _chip(GameIconData icon, String label, int value, Color color) {
    return _YieldChip(
      icon: icon,
      label: label,
      value: value,
      color: color,
      compact: compact,
      dense: dense,
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.row, required this.compact});

  final CityYieldBreakdownRow row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tooltip = '${row.label}: ${row.detail}';
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 42 : 46),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 7 : 8,
          ),
          decoration: SurfaceElevation.flat.decoration(
            background: GameUiTheme.bg,
            backgroundAlpha: 118,
            border: BorderEmphasis.subtle,
            borderRadius: BorderRadius.circular(5),
            includeShadow: false,
          ),
          child: Row(
            children: [
              Expanded(child: _description()),
              const SizedBox(width: 8),
              CityYieldChips(yield: row.yield, compact: true, dense: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _description() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          row.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodyStrong.copyWith(
            color: GameUiTheme.textPrimary,
            fontSize: compact ? 11 : 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          row.detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameHudTheme.textSecondary,
            fontSize: compact ? 10 : 11,
          ),
        ),
      ],
    );
  }
}

class _YieldChip extends StatelessWidget {
  const _YieldChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.compact,
    required this.dense,
  });

  final GameIconData icon;
  final String label;
  final int value;
  final Color color;
  final bool compact;
  final bool dense;

  String get _valueText => value > 0 ? '+$value' : '$value';

  double get _height => dense ? 22 : 26;

  double get _horizontalPadding => dense ? 5 : 7;

  int get _backgroundAlpha => value == 0 ? 12 : 28;

  int get _borderAlpha => value == 0 ? 44 : 105;

  double get _iconSize => dense ? GameIconSize.tiny : GameIconSize.small;

  double get _fontSize {
    if (dense) return 11;
    return compact ? 12 : 13;
  }

  Color get _textColor {
    return value == 0 ? GameUiTheme.textSecondary : GameUiTheme.textBright;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label $_valueText',
      child: Container(
        height: _height,
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
        decoration: SurfaceElevation.flat.decoration(
          accent: color,
          background: color,
          backgroundAlpha: _backgroundAlpha,
          borderAlpha: _borderAlpha,
          borderRadius: BorderRadius.circular(4),
          includeShadow: false,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(icon, size: _iconSize, color: color),
            SizedBox(width: dense ? 3 : 4),
            Text(
              _valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameHudTheme.yieldValue.copyWith(
                fontSize: _fontSize,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
