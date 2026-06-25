import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

class GameEventNotificationThumbnailView extends StatelessWidget {
  final GameEventNotificationThumbnail thumbnail;
  final double frameSize;
  final double iconSize;
  final double unitIconSize;

  const GameEventNotificationThumbnailView({
    required this.thumbnail,
    this.frameSize = 48,
    this.iconSize = 40,
    this.unitIconSize = 42,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 190,
        accent: GameUiTheme.gold,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: Center(child: _thumbnailWidget(thumbnail)),
      ),
    );
  }

  Widget _thumbnailWidget(GameEventNotificationThumbnail thumbnail) {
    return switch (thumbnail) {
      TechnologyEventNotificationThumbnail(:final technologyId) =>
        TechnologySpriteIcon(id: technologyId, size: iconSize),
      BuildingEventNotificationThumbnail(:final buildingType) =>
        BuildingSpriteIcon(type: buildingType, size: iconSize),
      UnitEventNotificationThumbnail(:final unitType) => UnitSpriteIcon(
        type: unitType,
        size: unitIconSize,
      ),
      CityEventNotificationThumbnail() => GameIcon(
        GameIcons.cityFilled,
        size: iconSize * 0.7,
        color: GameUiTheme.goldLight,
      ),
      CombatEventNotificationThumbnail() => GameIcon(
        GameIcons.attack,
        size: iconSize * 0.7,
        color: GameUiTheme.danger,
      ),
      IconEventNotificationThumbnail(:final kind) => _IconThumbnail(kind),
    };
  }
}

class _IconThumbnail extends StatelessWidget {
  final EventNotificationIconThumbnailKind kind;

  const _IconThumbnail(this.kind);

  @override
  Widget build(BuildContext context) {
    return GameIcon(_icon, size: GameIconSize.large, color: _color);
  }

  GameIconData get _icon {
    return switch (kind) {
      EventNotificationIconThumbnailKind.science => GameIcons.science,
      EventNotificationIconThumbnailKind.turn => GameIcons.skipTurn,
      EventNotificationIconThumbnailKind.success => GameIcons.checkCircle,
      EventNotificationIconThumbnailKind.warning => GameIcons.warning,
      EventNotificationIconThumbnailKind.civilization => GameIcons.flag,
    };
  }

  Color get _color {
    return switch (kind) {
      EventNotificationIconThumbnailKind.science => GameUiTheme.scienceAccent,
      EventNotificationIconThumbnailKind.turn => GameUiTheme.goldLight,
      EventNotificationIconThumbnailKind.success => GameUiTheme.success,
      EventNotificationIconThumbnailKind.warning => GameUiTheme.warning,
      EventNotificationIconThumbnailKind.civilization => GameUiTheme.gold,
    };
  }
}
