import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TransportNetworkState guards and immutable updates', () {
    const first = TransportSegment(
      hex: HexCoord(col: 1, row: 2),
      builtByPlayerId: 'player_1',
      builtByCityId: 'city_1',
    );

    test('validates builders and unique hexes', () {
      expect(
        () => TransportNetworkState(
          segments: const [
            TransportSegment(
              hex: HexCoord(col: 0, row: 0),
              builtByPlayerId: '',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => TransportNetworkState(segments: const [first, first]),
        throwsArgumentError,
      );
    });

    test('updates, removes, and decodes map implementations immutably', () {
      final state = TransportNetworkState(segments: const [first]);
      expect(state.isEmpty, isFalse);
      expect(state.isNotEmpty, isTrue);
      expect(state.put(first), same(state));
      expect(state.removeAt(9, 9), same(state));

      final pillaged = first.copyWith(
        condition: TransportSegmentCondition.pillaged,
        builtByPlayerId: 'player_2',
        builtByCityId: null,
      );
      final replaced = state.put(pillaged);
      expect(replaced.at(1, 2), pillaged);
      expect(replaced.removeAt(1, 2), TransportNetworkState.empty);

      final decoded = TransportNetworkState.fromJson([
        <Object, Object?>{
          'col': 1,
          'row': 2,
          'kind': 'road',
          'condition': 'operational',
          'builtByPlayerId': 'player_1',
          'builtByCityId': 'city_1',
        },
      ]);
      expect(decoded, state);
      expect(first.copyWith(), first);
      expect(first.hashCode, first.hashCode);
    });

    test('rejects malformed coordinates and segment kinds', () {
      Map<String, dynamic> json({Object? col = 1, Object? kind = 'road'}) => {
        'col': col,
        'row': 2,
        'kind': kind,
        'condition': 'operational',
        'builtByPlayerId': 'player_1',
      };

      expect(
        () => TransportSegment.fromJson(json(col: 1.5)),
        throwsFormatException,
      );
      expect(
        () => TransportSegment.fromJson(json(kind: 'rail')),
        throwsFormatException,
      );
    });
  });
}
