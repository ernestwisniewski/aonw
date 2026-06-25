import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class ProductionLeading extends StatelessWidget {
  const ProductionLeading({
    required this.item,
    required this.compact,
    super.key,
  });

  final CityProductionItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 42 : 52,
      height: compact ? 42 : 52,
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 255,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Center(child: _icon()),
    );
  }

  Widget _icon() {
    final buildingType = item.buildingType;
    if (buildingType != null) {
      return BuildingSpriteIcon(
        type: buildingType,
        size: compact ? 38 : 46,
        fallback: Text(
          item.emoji ?? '',
          style: TextStyle(fontSize: compact ? 23 : 27),
        ),
      );
    }

    final unitType = item.unitType;
    final icon = item.icon;
    if (unitType != null) {
      return UnitSpriteIcon(
        type: unitType,
        size: compact ? 37 : 44,
        fallback: icon == null
            ? const SizedBox.shrink()
            : GameIcon(
                icon,
                size: compact ? GameIconSize.regular : GameIconSize.large,
                color: GameUiTheme.goldLight,
              ),
      );
    }

    if (icon != null) {
      return GameIcon(
        icon,
        size: compact ? GameIconSize.regular : GameIconSize.large,
        color: GameUiTheme.goldLight,
      );
    }
    return Text(
      item.emoji ?? '',
      style: TextStyle(fontSize: compact ? 23 : 27),
    );
  }
}

class SpecializationLeading extends StatelessWidget {
  const SpecializationLeading({
    required this.item,
    required this.compact,
    super.key,
  });

  final CitySpecializationItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 40 : 46,
      height: compact ? 40 : 46,
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 255,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Center(
        child: GameIcon(
          item.icon,
          size: GameIconSize.regular,
          color: GameUiTheme.goldLight,
        ),
      ),
    );
  }
}

class ProductionMetaPill extends StatelessWidget {
  const ProductionMetaPill(
    this.label, {
    required this.compact,
    this.highlighted = false,
    super.key,
  });

  final String label;
  final bool compact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: SurfaceElevation.flat.decoration(
        background: highlighted ? GameUiTheme.gold : Colors.white,
        backgroundAlpha: highlighted ? 28 : 10,
        borderColor: highlighted ? GameUiTheme.gold : Colors.white,
        borderAlpha: highlighted ? 100 : 28,
        borderRadius: BorderRadius.circular(4),
        includeShadow: false,
      ),
      child: Text(
        label,
        style: GameUiTheme.bodySmall.copyWith(
          color: highlighted ? GameUiTheme.goldLight : GameUiTheme.textMuted,
          fontSize: compact ? 10 : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
