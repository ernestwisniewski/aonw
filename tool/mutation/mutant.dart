abstract final class MutationOperators {
  static const booleanLiteral = 'boolean_literal_flip';
  static const conditionalBoundary = 'relational_boundary';
  static const equality = 'equality_negation';
  static const logical = 'logical_connector';
  static const negation = 'logical_negation';
  static const typeCheck = 'type_test_negation';
  static const wireString = 'wire_string_replacement';
}

final class Mutant implements Comparable<Mutant> {
  const Mutant({
    required this.id,
    required this.path,
    required this.operator,
    required this.declaration,
    required this.offset,
    required this.length,
    required this.original,
    required this.replacement,
  }) : assert(id != ''),
       assert(path != ''),
       assert(operator != ''),
       assert(declaration != ''),
       assert(offset >= 0),
       assert(length >= 0),
       assert(original.length == length),
       assert(original != replacement);

  final String id;
  final String path;
  final String operator;
  final String declaration;
  final int offset;
  final int length;
  final String original;
  final String replacement;

  String apply(String content) {
    validateOriginal(content);
    return content.replaceRange(offset, offset + length, replacement);
  }

  String restore(String content) {
    validateApplied(content);
    return content.replaceRange(offset, offset + replacement.length, original);
  }

  void validateOriginal(String content) {
    _validateSpan(content, expected: original, state: 'original');
  }

  void validateApplied(String content) {
    _validateSpan(content, expected: replacement, state: 'mutated');
  }

  void _validateSpan(
    String content, {
    required String expected,
    required String state,
  }) {
    final end = offset + expected.length;
    if (offset > content.length || end > content.length) {
      throw RangeError(
        '$id cannot validate $state source for $path: '
        'span [$offset, $end) is outside ${content.length} code units.',
      );
    }
    final actual = content.substring(offset, end);
    if (actual != expected) {
      throw StateError(
        '$id cannot validate $state source for $path: '
        'expected ${_quoted(expected)}, found ${_quoted(actual)}.',
      );
    }
  }

  @override
  int compareTo(Mutant other) {
    var result = path.compareTo(other.path);
    if (result != 0) return result;
    result = offset.compareTo(other.offset);
    if (result != 0) return result;
    result = length.compareTo(other.length);
    if (result != 0) return result;
    result = operator.compareTo(other.operator);
    if (result != 0) return result;
    result = replacement.compareTo(other.replacement);
    if (result != 0) return result;
    return id.compareTo(other.id);
  }

  @override
  String toString() => '$id ($path@$offset: $original -> $replacement)';
}

String _quoted(String value) => '`${value.replaceAll('`', r'\`')}`';
