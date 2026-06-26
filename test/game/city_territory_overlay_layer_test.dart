import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityTerritoryOverlayLayer', () {
    test('marks only the selected city territory', () {
      final layer = CityTerritoryOverlayLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const selectedCity = GameCity(
        id: 'city_selected',
        ownerPlayerId: 'player_1',
        name: 'Selected',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      const otherCity = GameCity(
        id: 'city_other',
        ownerPlayerId: 'player_2',
        name: 'Other',
        center: CityHex(col: 4, row: 0),
        controlledHexes: [CityHex(col: 4, row: 1)],
      );

      layer.sync(
        parent: parent,
        cities: const [selectedCity, otherCity],
        selectedCityId: selectedCity.id,
      );

      final territories = layer.territoriesForTesting;
      expect(parent.children.query<CityTerritoryOverlayLayer>(), hasLength(1));
      expect(territories, hasLength(2));
      expect(territories[0].selected, isTrue);
      expect(territories[1].selected, isFalse);
      expect(territories[0].hexes, selectedCity.territoryHexes);
    });

    test('marks strategic view and keeps city centers', () {
      final layer = CityTerritoryOverlayLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 0),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );

      layer.sync(parent: parent, cities: const [city], strategicView: true);

      final territory = layer.territoriesForTesting.single;
      expect(layer.strategicViewForTesting, isTrue);
      expect(territory.center, city.center);
      expect(territory.hexes, city.territoryHexes);
    });

    test('passes zoom emphasis to the overlay component', () {
      final layer = CityTerritoryOverlayLayer(colorForPlayer: (_) => 0)
        ..zoomEmphasis = 0.75;
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 0),
      );

      layer.sync(parent: parent, cities: const [city]);

      expect(layer.zoomEmphasisForTesting, 0.75);

      layer.zoomEmphasis = 2;

      expect(layer.zoomEmphasisForTesting, 1);
    });

    test('reuses the overlay component across territory syncs', () {
      final layer = CityTerritoryOverlayLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      layer.sync(parent: parent, cities: const [city]);
      final first = layer.componentForTesting;

      layer.sync(
        parent: parent,
        cities: const [city],
        strategicView: true,
        selectedCityId: city.id,
      );

      final second = layer.componentForTesting;
      expect(second, same(first));
      expect(second, isA<CityTerritoryOverlay>());
      expect(layer.strategicViewForTesting, isTrue);
      expect(layer.territoriesForTesting.single.selected, isTrue);
    });

    test('keeps selected state when fog filters territory hexes', () {
      final layer = CityTerritoryOverlayLayer(colorForPlayer: (_) => 0);
      final parent = Component();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      layer.sync(
        parent: parent,
        cities: const [city],
        selectedCityId: city.id,
        canShowHex: (hex) => hex == city.center,
      );

      final territory = layer.territoriesForTesting.single;
      expect(territory.selected, isTrue);
      expect(territory.hexes, const [CityHex(col: 0, row: 0)]);
    });
  });
}
