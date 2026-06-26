import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityProductionParticleLayer', () {
    test('syncs emitters only for cities with active production', () {
      final layer = CityProductionParticleLayer();
      final parent = Component();
      final producingCity = _city(
        'city_1',
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final idleCity = _city('city_2');

      layer.sync(
        parent: parent,
        cities: [producingCity, idleCity],
        colorForPlayer: (_) => 0xFF4A7FC4,
      );

      expect(layer.emitterCountForTesting, 1);
      expect(layer.hasEmitterForTesting(producingCity.id), isTrue);
      expect(layer.hasEmitterForTesting(idleCity.id), isFalse);

      layer.sync(
        parent: parent,
        cities: [producingCity.copyWith(productionQueue: null), idleCity],
        colorForPlayer: (_) => 0xFF4A7FC4,
      );

      expect(layer.emitterCountForTesting, 0);
    });

    test('propagates reduce motion to active production emitters', () {
      final layer = CityProductionParticleLayer();
      final parent = Component();
      final city = _city(
        'city_1',
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );

      layer.sync(
        parent: parent,
        cities: [city],
        colorForPlayer: (_) => 0xFF4A7FC4,
      );

      expect(layer.emitterReduceMotionForTesting(city.id), isFalse);

      layer.reduceMotion = true;

      expect(layer.emitterReduceMotionForTesting(city.id), isTrue);

      layer.reduceMotion = false;

      expect(layer.emitterReduceMotionForTesting(city.id), isFalse);
    });

    test('visible=false clears and suppresses production emitters', () {
      final layer = CityProductionParticleLayer();
      final parent = Component();
      final city = _city(
        'city_1',
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );

      layer.sync(
        parent: parent,
        cities: [city],
        colorForPlayer: (_) => 0xFF4A7FC4,
      );

      expect(layer.emitterCountForTesting, 1);

      layer.visible = false;

      expect(layer.visible, isFalse);
      expect(layer.emitterCountForTesting, 0);

      layer.sync(
        parent: parent,
        cities: [city],
        colorForPlayer: (_) => 0xFF4A7FC4,
      );

      expect(layer.emitterCountForTesting, 0);
    });
  });

  group('CityProductionHintEmitter', () {
    test(
      'emits one hint every two seconds unless reduced motion is active',
      () {
        final emitter = CityProductionHintEmitter(
          position: Vector2.zero(),
          priority: 1,
          colorValue: 0xFF4A7FC4,
        );
        void advance(double seconds) => emitter.update(seconds);
        void setReduceMotion(bool value) => emitter.reduceMotion = value;

        advance(1.99);
        expect(emitter.spawnCountForTesting, 0);

        advance(0.02);
        expect(emitter.spawnCountForTesting, 1);

        setReduceMotion(true);
        advance(CityProductionHintEmitter.emissionPeriod * 2);
        expect(emitter.spawnCountForTesting, 1);

        setReduceMotion(false);
        advance(CityProductionHintEmitter.emissionPeriod);
        expect(emitter.spawnCountForTesting, 2);
      },
    );
  });
}

GameCity _city(String id, {CityProductionQueue? productionQueue}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: id,
    center: const CityHex(col: 0, row: 0),
    productionQueue: productionQueue,
  );
}
