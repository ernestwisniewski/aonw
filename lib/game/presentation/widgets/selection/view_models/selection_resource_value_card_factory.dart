import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/hex_assessment.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_resource_value_card_builder.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class SelectionResourceValueCardFactory {
  static List<SelectionResourceValueCard> fromTile({
    required MapTileView tile,
    required HexAssessment assessment,
    required GameClientState? gameState,
    required AppLocalizations l10n,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required String Function(FieldImprovementType type) improvementName,
    required String Function(TechnologyId id) technologyName,
    required String Function(ResourceType type) resourceName,
    required String Function(GameCity city) cityName,
  }) {
    final builder = SelectionResourceValueCardBuilder(
      gameState: gameState,
      l10n: l10n,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      improvementName: improvementName,
      technologyName: technologyName,
      resourceName: resourceName,
      cityName: cityName,
    );
    return [
      for (final resource in tile.resources)
        builder.build(
          resource: resource,
          tile: tile,
          tileYield: assessment.yield,
        ),
    ];
  }
}
