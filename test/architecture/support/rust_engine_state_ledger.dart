part of '../rust_engine_migration_inventory_test.dart';

final class _StateFieldLedger {
  const _StateFieldLedger({
    required this.expectedFixtureCount,
    required this.fixtureRoot,
    required this.dartDomainStateSource,
    required this.dartDomainCodecSource,
    required this.rustStateDtoSource,
    required this.envelopes,
    required this.envelopeFields,
    required this.domainFields,
    required this.stateJsonKeys,
    required this.lifecycleJsonKeys,
  });

  factory _StateFieldLedger.read(String path) {
    final builder = _StateFieldLedgerBuilder();
    for (final rawLine in File(path).readAsLinesSync()) {
      builder.addLine(rawLine);
    }
    return builder.build();
  }

  final int expectedFixtureCount;
  final String fixtureRoot;
  final String dartDomainStateSource;
  final String dartDomainCodecSource;
  final String rustStateDtoSource;
  final List<_EnvelopeEntry> envelopes;
  final Map<String, List<_EnvelopeFieldEntry>> envelopeFields;
  final List<_DomainFieldEntry> domainFields;
  final List<_JsonKeyEntry> stateJsonKeys;
  final List<_JsonKeyEntry> lifecycleJsonKeys;
}

final class _StateFieldLedgerBuilder {
  final directives = <String, String>{};
  final envelopes = <_EnvelopeEntry>[];
  final envelopeFields = <String, List<_EnvelopeFieldEntry>>{};
  final domainFields = <_DomainFieldEntry>[];
  final stateJsonKeys = <_JsonKeyEntry>[];
  final lifecycleJsonKeys = <_JsonKeyEntry>[];

  void addLine(String rawLine) {
    final line = rawLine.split('#').first.trim();
    if (line.isEmpty) return;
    final fields = line.split(RegExp(r'\s+'));
    switch (fields.first) {
      case 'envelope':
        _addEnvelope(fields, line);
        break;
      case 'envelope-field':
        _addEnvelopeField(fields, line);
        break;
      case 'domain-field':
        _addDomainField(fields, line);
        break;
      case 'state-json-key':
        _addJsonKey(fields, line, stateJsonKeys);
        break;
      case 'lifecycle-json-key':
        _addJsonKey(fields, line, lifecycleJsonKeys);
        break;
      default:
        _addDirective(fields, line);
    }
  }

  void _addEnvelope(List<String> fields, String line) {
    if (fields.length != 6) {
      throw FormatException('Malformed envelope line: $line');
    }
    envelopes.add(
      _EnvelopeEntry(
        id: fields[1],
        boundary: fields[2],
        type: fields[3],
        source: fields[4],
        status: fields[5],
      ),
    );
  }

  void _addEnvelopeField(List<String> fields, String line) {
    if (fields.length != 4) {
      throw FormatException('Malformed envelope field line: $line');
    }
    envelopeFields
        .putIfAbsent(fields[1], () => [])
        .add(_EnvelopeFieldEntry(name: fields[2], ownership: fields[3]));
  }

  void _addDomainField(List<String> fields, String line) {
    if (fields.length != 5) {
      throw FormatException('Malformed domain field line: $line');
    }
    domainFields.add(
      _DomainFieldEntry(
        dartField: fields[1],
        section: fields[2],
        status: fields[3],
        rustField: fields[4] == '-' ? null : fields[4],
      ),
    );
  }

  void _addJsonKey(
    List<String> fields,
    String line,
    List<_JsonKeyEntry> target,
  ) {
    if (fields.length != 5) {
      throw FormatException('Malformed JSON key line: $line');
    }
    target.add(
      _JsonKeyEntry(
        key: fields[1],
        section: fields[2],
        presence: fields[3],
        domainOwner: fields[4],
      ),
    );
  }

  void _addDirective(List<String> fields, String line) {
    if (fields.length != 2) {
      throw FormatException('Malformed ledger directive: $line');
    }
    if (!_stateLedgerDirectives.contains(fields.first)) {
      throw FormatException('Unknown ledger directive: ${fields.first}');
    }
    if (directives.containsKey(fields.first)) {
      throw FormatException('Duplicate ledger directive: ${fields.first}');
    }
    directives[fields.first] = fields[1];
  }

  _StateFieldLedger build() {
    _validateCounts();
    _validateEnvelopeClosure();
    _validateDuplicates();
    return _StateFieldLedger(
      expectedFixtureCount: int.parse(directives['expected-fixture-count']!),
      fixtureRoot: directives['fixture-root']!,
      dartDomainStateSource: directives['dart-domain-state-source']!,
      dartDomainCodecSource: directives['dart-domain-codec-source']!,
      rustStateDtoSource: directives['rust-state-dto-source']!,
      envelopes: List.unmodifiable(envelopes),
      envelopeFields: {
        for (final entry in envelopeFields.entries)
          entry.key: List.unmodifiable(entry.value),
      },
      domainFields: List.unmodifiable(domainFields),
      stateJsonKeys: List.unmodifiable(stateJsonKeys),
      lifecycleJsonKeys: List.unmodifiable(lifecycleJsonKeys),
    );
  }

  void _validateCounts() {
    _requireCount('expected-envelope-count', envelopes.length);
    _requireCount(
      'expected-envelope-field-count',
      envelopeFields.values.fold(0, (sum, fields) => sum + fields.length),
    );
    _requireCount('expected-domain-field-count', domainFields.length);
    _requireCount('expected-state-json-key-count', stateJsonKeys.length);
    _requireCount(
      'expected-lifecycle-json-key-count',
      lifecycleJsonKeys.length,
    );
  }

  void _requireCount(String directive, int actual) {
    if (int.parse(directives[directive]!) != actual) {
      throw FormatException('$directive does not match the ledger.');
    }
  }

  void _validateEnvelopeClosure() {
    final envelopeIds = envelopes.map((entry) => entry.id).toSet();
    if (envelopeIds.length != envelopes.length ||
        !envelopeIds.containsAll(envelopeFields.keys) ||
        !envelopeFields.keys.toSet().containsAll(envelopeIds)) {
      throw const FormatException('Envelope ids or fields are not closed.');
    }
  }

  void _validateDuplicates() {
    for (final fields in envelopeFields.values) {
      _requireUnique(fields.map((field) => field.name), 'envelope field');
    }
    _requireUnique(
      domainFields.map((entry) => entry.dartField),
      'domain field',
    );
    _requireUnique(stateJsonKeys.map((entry) => entry.key), 'state JSON key');
    _requireUnique(
      lifecycleJsonKeys.map((entry) => entry.key),
      'lifecycle JSON key',
    );
  }

  void _requireUnique(Iterable<String> values, String label) {
    if (values.toSet().length != values.length) {
      throw FormatException('Duplicate $label.');
    }
  }
}

const _stateLedgerDirectives = {
  'expected-fixture-count',
  'expected-envelope-count',
  'expected-envelope-field-count',
  'expected-domain-field-count',
  'expected-state-json-key-count',
  'expected-lifecycle-json-key-count',
  'fixture-root',
  'dart-domain-state-source',
  'dart-domain-codec-source',
  'dart-snapshot-source',
  'dart-metadata-source',
  'rust-state-dto-source',
  'rust-save-source',
  'rust-client-response-source',
};

final class _EnvelopeEntry {
  const _EnvelopeEntry({
    required this.id,
    required this.boundary,
    required this.type,
    required this.source,
    required this.status,
  });

  final String id;
  final String boundary;
  final String type;
  final String source;
  final String status;
}

final class _EnvelopeFieldEntry {
  const _EnvelopeFieldEntry({required this.name, required this.ownership});

  final String name;
  final String ownership;
}

final class _DomainFieldEntry {
  const _DomainFieldEntry({
    required this.dartField,
    required this.section,
    required this.status,
    required this.rustField,
  });

  final String dartField;
  final String section;
  final String status;
  final String? rustField;
}

final class _JsonKeyEntry {
  const _JsonKeyEntry({
    required this.key,
    required this.section,
    required this.presence,
    required this.domainOwner,
  });

  final String key;
  final String section;
  final String presence;
  final String domainOwner;
}
