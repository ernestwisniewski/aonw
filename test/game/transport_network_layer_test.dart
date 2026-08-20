import 'dart:ui';

import 'package:aonw/game/presentation/engine/rendering_layers/transport/transport_network_layer.dart';
import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransportNetworkLayer', () {
    test('connects an adjacent operational road to a city center', () {
      final layer = TransportNetworkLayer();
      final parent = Component();

      layer.sync(
        parent: parent,
        segments: const [
          TransportSegment(
            hex: HexCoord(col: 1, row: 0),
            builtByPlayerId: 'player_1',
          ),
        ],
        cityCenters: const [CityHex(col: 0, row: 0)],
      );

      expect(layer.segmentCountForTesting, 1);
      expect(layer.cityConnectionCountForTesting, 1);
      expect(layer.geometryBuildCountForTesting, 1);
      expect(parent.children.whereType<TransportNetworkLayer>(), hasLength(1));

      layer.sync(
        parent: parent,
        segments: const [
          TransportSegment(
            hex: HexCoord(col: 1, row: 0),
            builtByPlayerId: 'player_1',
          ),
        ],
        cityCenters: const [CityHex(col: 0, row: 0)],
      );
      expect(layer.geometryBuildCountForTesting, 1);

      final recorder = PictureRecorder();
      layer.render(Canvas(recorder));
      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
      expect(picture.approximateBytesUsed, greaterThan(0));
    });

    test('does not connect a road to a non-adjacent city', () {
      final layer = TransportNetworkLayer()
        ..sync(
          parent: Component(),
          segments: const [
            TransportSegment(
              hex: HexCoord(col: 1, row: 0),
              builtByPlayerId: 'player_1',
            ),
          ],
          cityCenters: const [CityHex(col: 4, row: 4)],
        );

      expect(layer.cityConnectionCountForTesting, 0);
    });

    test('does not connect a pillaged road to a city', () {
      final layer = TransportNetworkLayer()
        ..sync(
          parent: Component(),
          segments: const [
            TransportSegment(
              hex: HexCoord(col: 1, row: 0),
              condition: TransportSegmentCondition.pillaged,
              builtByPlayerId: 'player_1',
            ),
          ],
          cityCenters: const [CityHex(col: 0, row: 0)],
        );

      expect(layer.cityConnectionCountForTesting, 0);
    });

    testGolden(
      'renders a deterministic three-hex road scene',
      (game, _) async {
        final layer = TransportNetworkLayer();
        await game.ensureAdd(layer);
        layer.sync(
          parent: game,
          segments: const [
            TransportSegment(
              hex: HexCoord(col: 0, row: 0),
              builtByPlayerId: 'player_1',
            ),
            TransportSegment(
              hex: HexCoord(col: 1, row: 0),
              builtByPlayerId: 'player_1',
            ),
            TransportSegment(
              hex: HexCoord(col: 2, row: 0),
              builtByPlayerId: 'player_1',
            ),
          ],
          cityCenters: const [],
        );
      },
      goldenFile: 'goldens/transport_network_layer.png',
      size: Vector2(300, 170),
      backgroundColor: const Color(0xFF111820),
    );
  });
}
