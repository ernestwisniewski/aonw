import 'package:flutter_test/flutter_test.dart';

import '../../tool/mutation/discoverer.dart';
import '../../tool/mutation/mutant.dart';

void main() {
  group('AST mutation discovery', () {
    test(
      'discovers every supported operator without overlapping categories',
      () {
        final mutants = discoverMutants(path: _path, content: _source);

        expect(mutants.map((mutant) => mutant.operator).toSet(), {
          MutationOperators.booleanLiteral,
          MutationOperators.conditionalBoundary,
          MutationOperators.equality,
          MutationOperators.logical,
          MutationOperators.negation,
          MutationOperators.typeCheck,
          MutationOperators.wireString,
        });
        expect(
          _edits(mutants, MutationOperators.equality),
          containsAll(const [('==', '!='), ('!=', '==')]),
        );
        expect(
          _edits(mutants, MutationOperators.logical),
          containsAll(const [('&&', '||'), ('||', '&&')]),
        );
        expect(
          _edits(mutants, MutationOperators.conditionalBoundary),
          containsAll(const [
            ('<', '<='),
            ('<=', '<'),
            ('>', '>='),
            ('>=', '>'),
          ]),
        );
        expect(
          _edits(mutants, MutationOperators.typeCheck),
          containsAll(const [('is', 'is!'), ('is!', 'is')]),
        );
        expect(
          _edits(mutants, MutationOperators.negation),
          containsAll(const [('!', ''), ('enabled', '!(enabled)')]),
        );
        expect(
          _edits(mutants, MutationOperators.booleanLiteral),
          containsAll(const [('true', 'false'), ('false', 'true')]),
        );

        expect(mutants, orderedEquals(mutants.toList()..sort()));
        expect(
          mutants.map((mutant) => mutant.id).toSet(),
          hasLength(mutants.length),
        );
        expect(
          mutants.map((mutant) => mutant.declaration),
          everyElement(startsWith('class:WireCodec/')),
        );
      },
    );

    test('limits wire strings to structural protocol positions', () {
      final mutants = discoverMutants(path: _path, content: _source)
          .where((mutant) => mutant.operator == MutationOperators.wireString)
          .toList();
      final edits = {
        for (final mutant in mutants) (mutant.original, mutant.replacement),
      };

      expect(edits, contains((r"r'rawKey'", r"r'rawKey__mutant'")));
      expect(edits, contains(("'type'", "'type__mutant'")));
      expect(edits, contains(("'''command'''", "'''command__mutant'''")));
      expect(edits, contains(("'switchTag'", "'switchTag__mutant'")));
      expect(edits, contains(("'encodedString'", "'encodedString__mutant'")));
      expect(edits, contains(("'encodedOther'", "'encodedOther__mutant'")));
      expect(edits, contains(('"fieldName"', '"fieldName__mutant"')));
      expect(edits, contains(('"nestedField"', '"nestedField__mutant"')));
      expect(
        edits,
        contains(("'already__mutant'", "'already__mutant__mutant'")),
      );

      final originals = mutants.map((mutant) => mutant.original).toSet();
      expect(originals, isNot(contains("'ordinaryValue'")));
      expect(originals, isNot(contains("'diagnostic context'")));
      expect(originals, isNot(contains("'diagnostic path'")));
      expect(originals, isNot(contains("'diagnostic message'")));
      expect(originals, isNot(contains("'log context'")));
    });

    test('stable ids ignore line shifts and distinguish structural sites', () {
      final original = discoverMutants(path: _path, content: _source);
      const prefix = '\n\n// A line-only edit before every declaration.\n';
      final shifted = discoverMutants(path: _path, content: '$prefix$_source');

      expect(
        shifted.map((mutant) => mutant.id),
        original.map((mutant) => mutant.id),
      );
      for (var index = 0; index < original.length; index += 1) {
        expect(shifted[index].offset, original[index].offset + prefix.length);
      }

      final repeated = original
          .where(
            (mutant) =>
                mutant.operator == MutationOperators.booleanLiteral &&
                mutant.original == 'true' &&
                mutant.declaration.endsWith('variable:flags'),
          )
          .toList();
      expect(repeated, hasLength(2));
      expect(repeated[0].id, endsWith('site-1'));
      expect(repeated[1].id, endsWith('site-1'));
      expect(repeated[0].id, isNot(repeated[1].id));
    });

    test('ids preserve existing contexts when a new statement is inserted', () {
      const before = '''bool accepts(int first, int second) {
  if (first == 0) return false;
  return second == 0;
}
''';
      const after = '''bool accepts(int first, int second) {
  if (second == 0) return false;
  if (first == 0) return false;
  return second == 0;
}
''';
      final original = discoverMutants(
        path: _path,
        content: before,
      ).where((mutant) => mutant.operator == MutationOperators.equality);
      final inserted = discoverMutants(
        path: _path,
        content: after,
      ).where((mutant) => mutant.operator == MutationOperators.equality);

      final originalIds = original.map((mutant) => mutant.id).toSet();
      final insertedIds = inserted.map((mutant) => mutant.id).toSet();
      expect(originalIds, hasLength(2));
      expect(insertedIds, hasLength(3));
      expect(insertedIds, containsAll(originalIds));
      expect(insertedIds.difference(originalIds), hasLength(1));
    });

    test(
      'ids stay attached to default parameters and constructor initializers',
      () {
        const before = '''class Defaults {
  final bool defaultFirst;
  final bool defaultSecond;

  const Defaults({
    this.defaultFirst = true,
    this.defaultSecond = true,
  });
}

class Initialized {
  final bool initializedFirst;
  final bool initializedSecond;

  const Initialized()
      : initializedFirst = true,
        initializedSecond = true;
}
''';
        const after = '''class Defaults {
  final bool insertedDefault;
  final bool defaultFirst;
  final bool defaultSecond;

  const Defaults({
    this.insertedDefault = true,
    this.defaultFirst = true,
    this.defaultSecond = true,
  });
}

class Initialized {
  final bool insertedInitializer;
  final bool initializedFirst;
  final bool initializedSecond;

  const Initialized()
      : insertedInitializer = true,
        initializedFirst = true,
        initializedSecond = true;
}
''';
        final original = discoverMutants(path: _path, content: before);
        final inserted = discoverMutants(path: _path, content: after);
        const existingSites = [
          'this.defaultFirst = true',
          'this.defaultSecond = true',
          'initializedFirst = true',
          'initializedSecond = true',
        ];

        for (final site in existingSites) {
          final originalMutant = _booleanMutantAt(original, before, site);
          final insertedMutant = _booleanMutantAt(inserted, after, site);
          expect(insertedMutant.id, originalMutant.id, reason: site);
          expect(originalMutant.id, endsWith('site-1'), reason: site);
        }
      },
    );

    test('declaration fallback avoids ordinal-only identities', () {
      const source = '''class Marker {
  const Marker(bool first, bool second);
}

@Marker(true, true)
class Annotated {}

enum Values {
  item(true, true);

  const Values(bool first, bool second);
}
''';

      final mutants = discoverMutants(path: _path, content: source)
          .where(
            (mutant) => mutant.operator == MutationOperators.booleanLiteral,
          )
          .toList();

      expect(mutants, hasLength(4));
      expect(
        mutants.map((mutant) => mutant.id),
        everyElement(endsWith('site-1')),
      );
      expect(mutants.map((mutant) => mutant.id).toSet(), hasLength(4));
      expect(mutants.map((mutant) => mutant.declaration).toSet(), {
        'class:Annotated',
        'enum:Values/enum_constant:item',
      });
    });

    test('omits mutations that would invalidate flow promotion', () {
      const source = '''int promoted(Object? value, Object other) {
  if (value == null) return 0;
  if (other is! String) return value.hashCode;
  return other.length + value.hashCode;
}
''';

      final mutants = discoverMutants(path: _path, content: source);

      expect(
        mutants.where(
          (mutant) =>
              mutant.operator == MutationOperators.equality ||
              mutant.operator == MutationOperators.typeCheck,
        ),
        isEmpty,
      );
    });

    test('apply and restore validate the exact source span', () {
      final mutants = discoverMutants(path: _path, content: _source);

      for (final mutant in mutants) {
        final mutated = mutant.apply(_source);
        mutant.validateApplied(mutated);
        expect(mutant.restore(mutated), _source, reason: mutant.id);
      }

      final mutant = mutants.first;
      final corruptOriginal = _source.replaceRange(
        mutant.offset,
        mutant.offset + mutant.length,
        List.filled(mutant.length, 'x').join(),
      );
      expect(() => mutant.apply(corruptOriginal), throwsStateError);
      expect(
        () => mutant.restore(_source),
        anyOf(throwsStateError, throwsRangeError),
      );
    });

    test(
      'rejects parser diagnostics instead of discovering partial source',
      () {
        expect(
          () => discoverMutants(path: _path, content: 'bool broken( => true;'),
          throwsFormatException,
        );
      },
    );
  });
}

Set<(String, String)> _edits(List<Mutant> mutants, String operator) => {
  for (final mutant in mutants)
    if (mutant.operator == operator) (mutant.original, mutant.replacement),
};

Mutant _booleanMutantAt(List<Mutant> mutants, String source, String marker) {
  final markerOffset = source.indexOf(marker);
  if (markerOffset < 0) throw StateError('Missing test marker: $marker');
  final literalOffset = source.indexOf('true', markerOffset);
  return mutants.singleWhere(
    (mutant) =>
        mutant.operator == MutationOperators.booleanLiteral &&
        mutant.offset == literalOffset,
  );
}

const _path = 'lib/wire_codec.dart';

const _source = r"""class WireCodec {
  Object evaluate(Object input, bool enabled, int count) {
    final flags = <bool>[true, true];
    final disabled = false;
    final payload = <String, Object?>{
      r'rawKey': 'ordinaryValue',
      'type': '''command''',
    };
    final encoded = <String, Object?>{
      'type': switch (input) {
        String() => 'encodedString',
        _ => 'encodedOther',
      },
    };
    final isString = input is String;
    final isNotInt = input is! int;
    log('log context');
    if (enabled) return flags;
    if (enabled == false && input != payload || !disabled) {
      return count < 1 || count <= 2 || count > 3 || count >= 4;
    }
    if (isString || isNotInt) return flags.first && flags.last;
    return encoded.isEmpty ? disabled : switch (input) {
      'switchTag' => enabled,
      _ => disabled,
    };
  }

  Object decode(Map<String, Object?> json) {
    final field = requiredStringField(
      json,
      'diagnostic context',
      "fieldName",
    );
    final nested = requiredMapValue(json["nestedField"], 'diagnostic path');
    final already = {'already__mutant': field};
    if (field == nested) throw FormatException('diagnostic message');
    return already.isEmpty ? field : nested;
  }
}
""";
