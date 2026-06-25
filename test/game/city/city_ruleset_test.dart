import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityRulesets.standard', () {
    test('defines every current city building', () {
      for (final type in CityBuildingType.values) {
        final definition = CityRulesets.standard.buildingDefinitionFor(type);

        expect(definition.type, type);
        expect(definition.effects, isNotEmpty);
      }
    });

    test('defines every city-producible unit', () {
      for (final type in GameUnitType.values.where(
        (type) => type.canBeProducedByCities,
      )) {
        final definition = CityRulesets.standard.unitDefinitionFor(type);

        expect(definition.type, type);
        expect(definition.productionCost, greaterThan(0));
      }
    });

    test(
      'defines every current terrain, resource and field improvement yield',
      () {
        for (final terrain in TerrainType.values) {
          expect(
            CityRulesets.standard.terrainYieldFor(terrain),
            isA<TileYield>(),
          );
        }
        for (final resource in ResourceType.values) {
          expect(
            CityRulesets.standard.resourceYields,
            containsPair(resource, isA<TileYield>()),
          );
        }
        for (final improvement in FieldImprovementType.values) {
          final definition = CityRulesets.standard.improvementDefinitionFor(
            improvement,
          );

          expect(definition.type, improvement);
          expect(definition.tileYield, isA<TileYield>());
        }
      },
    );
  });
}
