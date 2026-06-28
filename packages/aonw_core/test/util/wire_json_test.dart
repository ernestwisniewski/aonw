import 'package:aonw_core/util/wire_json.dart';
import 'package:test/test.dart';

enum _TestMode { scout, settle }

void main() {
  group('WireJson', () {
    test('reads required primitive fields', () {
      const reader = WireJson({
        'id': 'unit_1',
        'count': 3,
        'ratio': 1.5,
        'enabled': true,
      }, 'TestPayload');

      expect(reader.requiredString('id'), 'unit_1');
      expect(reader.requiredInt('count'), 3);
      expect(reader.requiredDouble('ratio'), 1.5);
      expect(reader.requiredBool('enabled'), isTrue);
    });

    test('accepts integral numeric values for ints', () {
      expect(requiredIntValue(3.0, 'TestPayload.count'), 3);
      expect(optionalIntField({'count': 4.0}, 'TestPayload', 'count'), 4);
    });

    test('rejects fractional numeric values for ints', () {
      expect(
        () => requiredIntValue(3.5, 'TestPayload.count'),
        throwsArgumentError,
      );
      expect(
        () => optionalIntField({'count': 4.5}, 'TestPayload', 'count'),
        throwsArgumentError,
      );
    });

    test('reads non-negative ints consistently', () {
      const reader = WireJson({'count': 3.0}, 'TestPayload');

      expect(reader.requiredNonNegativeInt('count'), 3);
      expect(optionalNonNegativeIntValue(null, 'TestPayload.count'), isNull);
      expect(
        () => requiredNonNegativeIntValue(-1, 'TestPayload.count'),
        throwsArgumentError,
      );
    });

    test('reads enum names with consistent errors', () {
      expect(
        enumByName('scout', _TestMode.values, 'TestPayload.mode'),
        _TestMode.scout,
      );
      expect(
        optionalEnumByName(null, _TestMode.values, 'TestPayload.mode'),
        isNull,
      );
      expect(
        () => enumByName('missing', _TestMode.values, 'TestPayload.mode'),
        throwsArgumentError,
      );
    });

    test('reads JSON object values with string keys', () {
      expect(requiredMapValue({'id': 'city_1'}, 'TestPayload.city'), {
        'id': 'city_1',
      });
      expect(
        requiredMapValue(<Object?, Object?>{
          'id': 'city_1',
        }, 'TestPayload.city'),
        {'id': 'city_1'},
      );
    });
  });
}
