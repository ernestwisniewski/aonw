import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw_core/game/domain/objective.dart';

GameIconData gameIconForMapObjectiveType(MapObjectiveType type) =>
    switch (type) {
      MapObjectiveType.ruins => GameIcons.layers,
      MapObjectiveType.strategicPass => GameIcons.route,
      MapObjectiveType.holySite => GameIcons.victory,
      MapObjectiveType.legendaryResource => GameIcons.resources,
    };
