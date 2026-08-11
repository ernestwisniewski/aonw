import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _directory = 'packages/aonw_core/lib/game/domain/diplomacy';

void main() {
  test('DiplomacyState delegates operations without runtime owner casts', () {
    final root = File('$_directory/diplomacy_state.dart').readAsStringSync();
    final model = File(
      '$_directory/diplomacy_state_model.dart',
    ).readAsStringSync();
    final queries = File(
      '$_directory/diplomacy_state_queries.dart',
    ).readAsStringSync();
    final mutations = File(
      '$_directory/diplomacy_state_mutations.dart',
    ).readAsStringSync();
    final operations = '$queries\n$mutations';

    expect(model, isNot(contains('with _DiplomacyState')));
    expect(operations, isNot(contains('mixin _DiplomacyState')));
    expect(operations, isNot(contains('_stateOf')));
    expect(operations, isNot(contains(' as DiplomacyState')));
    expect(
      queries,
      contains('abstract final class _DiplomacyStateQueryOperations'),
    );
    expect(
      mutations,
      contains('abstract final class _DiplomacyStateMutationOperations'),
    );
    expect(
      RegExp(r'\bDiplomacyState state\b').allMatches(queries),
      hasLength(13),
    );
    expect(
      RegExp(r'\bDiplomacyState state\b').allMatches(mutations),
      hasLength(15),
    );
    expect(model, contains('_DiplomacyStateQueryOperations.'));
    expect(model, contains('_DiplomacyStateMutationOperations.'));

    const publicValueObjectFiles = [
      'diplomacy_primitives.dart',
      'diplomatic_gold_gift_rules.dart',
      'diplomatic_message.dart',
      'diplomatic_proposal.dart',
      'diplomatic_relation.dart',
      'diplomatic_score_entry.dart',
    ];
    for (final name in publicValueObjectFiles) {
      expect(root, contains("export '$name';"), reason: name);
      expect(
        File('$_directory/$name').readAsStringSync(),
        isNot(contains("part of 'diplomacy_state.dart'")),
        reason: name,
      );
    }
    expect(
      File('$_directory/diplomacy_pair.dart').readAsStringSync(),
      isNot(contains("part of 'diplomacy_state.dart'")),
    );
    expect(
      File('$_directory/diplomacy_state.freezed.dart').existsSync(),
      false,
    );
  });
}
