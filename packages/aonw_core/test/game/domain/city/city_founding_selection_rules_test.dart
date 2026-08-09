import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('CityFoundingRules interactive selection', () {
    test('only exposes candidates adjacent to the current draft territory', () {
      final map = _map5x5();
      final emptyDraft = _draft();

      expect(
        CityFoundingRules.selectableControlledHexes(
          draft: emptyDraft,
          mapTiles: map,
        ),
        unorderedEquals(const [
          CityHex(col: 3, row: 1),
          CityHex(col: 3, row: 2),
          CityHex(col: 2, row: 3),
          CityHex(col: 1, row: 2),
          CityHex(col: 1, row: 1),
          CityHex(col: 2, row: 1),
        ]),
      );

      final extendedCandidates = CityFoundingRules.selectableControlledHexes(
        draft: emptyDraft.copyWith(
          controlledHexes: const [CityHex(col: 3, row: 2)],
        ),
        mapTiles: map,
      );

      expect(extendedCandidates, contains(const CityHex(col: 4, row: 2)));
      expect(
        extendedCandidates,
        isNot(contains(const CityHex(col: 4, row: 1))),
      );
    });

    test('exposes no candidates after the draft reaches its required size', () {
      final draft = _draft(
        controlledHexes: const [
          CityHex(col: 3, row: 2),
          CityHex(col: 4, row: 2),
        ],
      );

      expect(
        CityFoundingRules.selectableControlledHexes(
          draft: draft,
          mapTiles: _map5x5(),
        ),
        isEmpty,
      );
    });

    test('completes a draft through a legal second-ring chain', () {
      final map = _sparseRowMap(cols: 3, tileCount: 3);
      final draft = CityFoundingDraft(
        unitId: 'settler_1',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 0, row: 0),
      );

      expect(
        CityFoundingRules.canCompleteDraft(draft: draft, mapTiles: map),
        isTrue,
      );
      expect(
        CityFoundingRules.canCompleteDraft(
          draft: draft,
          mapTiles: _sparseRowMap(cols: 2, tileCount: 2),
        ),
        isFalse,
      );
    });

    test(
      'toggle rejects disconnected additions and cascades bridge removal',
      () {
        final map = _map5x5();
        final emptyDraft = _draft();
        final disconnected = CityFoundingRules.toggleControlledHexSelection(
          draft: emptyDraft,
          target: const CityHex(col: 4, row: 2),
          mapTiles: map,
        );

        expect(disconnected, same(emptyDraft));

        final connectedDraft = _draft(
          controlledHexes: const [
            CityHex(col: 3, row: 2),
            CityHex(col: 4, row: 2),
          ],
        );
        final withoutBridge = CityFoundingRules.toggleControlledHexSelection(
          draft: connectedDraft,
          target: const CityHex(col: 3, row: 2),
          mapTiles: map,
        );

        expect(withoutBridge.controlledHexes, isEmpty);
      },
    );
  });
}

CityFoundingDraft _draft({List<CityHex> controlledHexes = const []}) {
  return CityFoundingDraft(
    unitId: 'commander_player_1',
    ownerPlayerId: 'player_1',
    center: const CityHex(col: 2, row: 2),
    controlledHexes: controlledHexes,
  );
}

WorldMap _map5x5() => WorldMap(
  cols: 5,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++) _tile(col, row),
  ],
);

WorldMap _sparseRowMap({required int cols, required int tileCount}) => WorldMap(
  cols: cols,
  rows: 1,
  tiles: [for (var col = 0; col < tileCount; col++) _tile(col, 0)],
);

WorldTile _tile(int col, int row) => WorldTile(
  col: col,
  row: row,
  terrains: const [TerrainType.plains],
  resources: const [],
  height: 0,
);
