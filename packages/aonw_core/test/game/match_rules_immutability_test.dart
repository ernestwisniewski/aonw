import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:test/test.dart';

void main() {
  group('MatchRules balance ownership', () {
    test(
      'owns source collections recursively and exposes no mutable aliases',
      () {
        final nestedMap = <String, dynamic>{'enabled': true};
        final nestedList = <dynamic>[1, nestedMap];
        final source = <String, dynamic>{'weights': nestedList};

        final rules = MatchRules(
          gameLength: GameLengthConfig.unlimited,
          victory: VictoryRules.standard,
          balance: source,
        );

        source['late'] = true;
        nestedList[0] = 99;
        nestedMap['enabled'] = false;

        expect(rules.balance, {
          'weights': [
            1,
            {'enabled': true},
          ],
        });
        expect(() => rules.balance['late'] = true, throwsUnsupportedError);
        expect(
          () => (rules.balance['weights'] as List<dynamic>)[0] = 99,
          throwsUnsupportedError,
        );
        expect(
          () =>
              ((rules.balance['weights'] as List<dynamic>)[1]
                      as Map<String, dynamic>)['enabled'] =
                  false,
          throwsUnsupportedError,
        );
      },
    );

    test('accepts only recursive JSON values with finite numbers', () {
      final rules = MatchRules(
        gameLength: GameLengthConfig.unlimited,
        victory: VictoryRules.standard,
        balance: const {
          'null': null,
          'bool': true,
          'string': 'value',
          'int': 1,
          'double': 1.5,
          'list': [
            null,
            false,
            {'nested': 'value'},
          ],
        },
      );

      expect(rules.balance['double'], 1.5);
      for (final invalid in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(() => _rules({'invalid': invalid}), throwsArgumentError);
      }
      expect(
        () => _rules({
          'invalid': {1: 'non-string key'},
        }),
        throwsArgumentError,
      );
      expect(
        () => _rules({'invalid': DateTime.utc(2026)}),
        throwsArgumentError,
      );

      final cyclic = <dynamic>[];
      cyclic.add(cyclic);
      expect(() => _rules({'invalid': cyclic}), throwsArgumentError);
    });

    test('fromJson applies the same validation as the public constructor', () {
      final base = MatchRules.standard.toJson();
      final nested = <dynamic>[1, 2];
      final balance = <String, dynamic>{'weights': nested};

      final restored = MatchRules.fromJson({...base, 'balance': balance});
      balance['late'] = true;
      nested[0] = 99;

      expect(restored.balance, {
        'weights': [1, 2],
      });

      expect(
        () => MatchRules.fromJson({
          ...base,
          'balance': {
            'invalid': {1: 'non-string key'},
          },
        }),
        throwsFormatException,
      );
      expect(
        () => MatchRules.fromJson({
          ...base,
          'balance': {'invalid': double.infinity},
        }),
        throwsFormatException,
      );
      expect(
        () => MatchRules.fromJson({...base, 'balance': <dynamic>[]}),
        throwsFormatException,
      );
    });

    test('toJson returns fresh recursively mutable collections', () {
      final rules = _rules({
        'weights': <dynamic>[
          1,
          <String, dynamic>{'enabled': true},
        ],
      });

      final json = rules.toJson();
      final balance = json['balance'] as Map<String, dynamic>;
      final weights = balance['weights'] as List<dynamic>;
      final nested = weights[1] as Map<String, dynamic>;
      balance['new'] = true;
      weights.add(2);
      nested['enabled'] = false;

      expect(rules.balance, {
        'weights': [
          1,
          {'enabled': true},
        ],
      });
      expect(rules.toJson()['balance'], {
        'weights': [
          1,
          {'enabled': true},
        ],
      });
      expect(identical(json['balance'], rules.toJson()['balance']), isFalse);
    });

    test('deep equality and hash are independent of map insertion order', () {
      final left = _rules({
        'outer': <String, dynamic>{
          'flag': true,
          'values': <dynamic>[1, null, 'three'],
        },
        'last': 4,
      });
      final right = _rules({
        'last': 4,
        'outer': <String, dynamic>{
          'values': <dynamic>[1, null, 'three'],
          'flag': true,
        },
      });

      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect({left, right}, hasLength(1));
    });

    test('maps with different keys mapped to null are not equal', () {
      final left = _rules({'left': null});
      final right = _rules({'right': null});

      expect(left, isNot(right));
      expect({left, right}, hasLength(2));
    });

    test('copyWith shares unchanged balance and owns a replacement', () {
      final rules = _rules({
        'weights': <dynamic>[1, 2],
      });

      final unchanged = rules.copyWith(victory: rules.victory.copyWith());
      expect(identical(unchanged.balance, rules.balance), isTrue);

      final replacementList = <dynamic>[3, 4];
      final replacement = <String, dynamic>{'weights': replacementList};
      final changed = rules.copyWith(balance: replacement);
      replacement['late'] = true;
      replacementList[0] = 99;

      expect(changed.balance, {
        'weights': [3, 4],
      });
      expect(identical(changed.balance, rules.balance), isFalse);
      expect(() => changed.balance['late'] = true, throwsUnsupportedError);
    });

    test(
      'standard remains a compile-time constant with owned empty balance',
      () {
        const rules = MatchRules.standard;

        expect(identical(rules, MatchRules.standard), isTrue);
        expect(rules.balance, isEmpty);
        expect(() => rules.balance['late'] = true, throwsUnsupportedError);
      },
    );
  });
}

MatchRules _rules(Map<String, dynamic> balance) {
  return MatchRules(
    gameLength: GameLengthConfig.unlimited,
    victory: VictoryRules.standard,
    balance: balance,
  );
}
