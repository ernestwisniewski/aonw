import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_info_model.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudSelectionInfoModelFactory', () {
    final l10n = AppLocalizationsEn();

    test('returns null without selection', () {
      final model = HudSelectionInfoModelFactory.from(
        selection: null,
        gameState: null,
        mapData: _mapData(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: l10n,
      );

      expect(model, isNull);
    });

    test('builds a localized city selection model', () {
      const city = GameCity(
        id: 'city_3',
        ownerPlayerId: 'player_1',
        name: 'city_3',
        center: CityHex(col: 1, row: 1),
      );
      final model = HudSelectionInfoModelFactory.from(
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0xFF4488cc,
        ),
        gameState: const GameState(cities: [city]),
        mapData: _mapData(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: l10n,
      );

      expect(model, isNotNull);
      expect(model!.title, l10n.defaultCityName(3));
      expect(model.selectionKey, 'city:city_3');
    });

    test('builds a tile selection model', () {
      final tile = _mapData().tiles.first;
      final model = HudSelectionInfoModelFactory.from(
        selection: GameSelection.tile(tile),
        gameState: const GameState(),
        mapData: _mapData(),
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: l10n,
      );

      expect(model, isNotNull);
      expect(model!.selectionKey, 'tile:0:0');
      expect(model.yieldTitle, 'Tile potential');
      expect(
        model.yieldTooltip,
        'Inspection estimate for this tile, not actual city yield.',
      );
      expect(model.description, contains(l10n.hexKindGoodCitySiteDescription));
      expect(
        model.description,
        contains(l10n.hexRecommendationFoundCityDetail),
      );
    });

    test('localizes tile assessment labels in English', () {
      final l10n = AppLocalizationsEn();
      final mapData = _mapData(terrain: TerrainType.desert);
      final tile = mapData.tiles.first;
      final model = HudSelectionInfoModelFactory.from(
        selection: GameSelection.tile(tile),
        gameState: const GameState(),
        mapData: mapData,
        cityRuleset: CityRulesets.standard,
        technologyRuleset: TechnologyRulesets.standard,
        l10n: l10n,
      );

      expect(model, isNotNull);
      expect(model!.title, l10n.hexKindBarrenLand);
      expect(
        model.description,
        '${l10n.hexKindBarrenLandDescription} '
        '${l10n.hexRecommendationAvoidDetail}',
      );
      expect(model.yieldTitle, l10n.tileSelectionYieldTitle);
      expect(model.yieldTooltip, l10n.tileSelectionYieldTooltip);
    });
  });
}

MapData _mapData({TerrainType terrain = TerrainType.grassland}) {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: [
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 2; col++)
          TileData(
            col: col,
            row: row,
            terrains: [terrain],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
