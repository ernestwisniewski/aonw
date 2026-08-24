part of '../rust_engine_migration_inventory_test.dart';

final class _MigrationInventory {
  const _MigrationInventory({
    required this.dartDomainRoot,
    required this.dartSystemSource,
    required this.dartEventRoot,
    required this.rustDomainSource,
    required this.rustSystemSource,
    required this.rustQuerySource,
    required this.rustEventSource,
    required this.rustEvidenceSource,
    required this.rustPersistenceSource,
    required this.rustClientCommandSource,
    required this.rustClientResponseSource,
    required this.rustProjectionSource,
    required this.partialParityMode,
    required this.domainEntries,
    required this.systemEntries,
    required this.queryEntries,
    required this.eventEntries,
    required this.evidenceEntries,
    required this.projectionTypes,
    required this.projectionVariants,
  });

  factory _MigrationInventory.read(String path) {
    final builder = _MigrationInventoryBuilder();
    for (final rawLine in File(path).readAsLinesSync()) {
      builder.addLine(rawLine);
    }
    return builder.build();
  }

  final String dartDomainRoot;
  final String dartSystemSource;
  final String dartEventRoot;
  final String rustDomainSource;
  final String? rustSystemSource;
  final String rustQuerySource;
  final String rustEventSource;
  final String rustEvidenceSource;
  final String rustPersistenceSource;
  final String rustClientCommandSource;
  final String rustClientResponseSource;
  final String rustProjectionSource;
  final String partialParityMode;
  final List<_InventoryEntry> domainEntries;
  final List<_InventoryEntry> systemEntries;
  final List<_QueryEntry> queryEntries;
  final List<_InventoryEntry> eventEntries;
  final List<_InventoryEntry> evidenceEntries;
  final List<_ProjectionTypeEntry> projectionTypes;
  final List<_ProjectionVariantEntry> projectionVariants;

  List<_InventoryEntry> get entries => [
    ...domainEntries,
    ...systemEntries,
    ...eventEntries,
    ...evidenceEntries,
  ];
}

final class _MigrationInventoryBuilder {
  final directives = <String, String>{};
  final domainEntries = <_InventoryEntry>[];
  final systemEntries = <_InventoryEntry>[];
  final queryEntries = <_QueryEntry>[];
  final eventEntries = <_InventoryEntry>[];
  final evidenceEntries = <_InventoryEntry>[];
  final projectionTypes = <_ProjectionTypeEntry>[];
  final projectionVariants = <_ProjectionVariantEntry>[];

  void addLine(String rawLine) {
    final line = rawLine.split('#').first.trim();
    if (line.isEmpty) return;
    final fields = line.split(RegExp(r'\s+'));
    switch (fields.first) {
      case 'domain':
      case 'system':
      case 'event':
      case 'evidence':
        _addDartEntry(fields, line);
        break;
      case 'query':
        _addQuery(fields, line);
        break;
      case 'projection-type':
        _addProjectionType(fields, line);
        break;
      case 'projection-variant':
        _addProjectionVariant(fields, line);
        break;
      default:
        _addDirective(fields, line);
    }
  }

  void _addDartEntry(List<String> fields, String line) {
    if (fields.length != 6) {
      throw FormatException('Malformed inventory line: $line');
    }
    final entry = _InventoryEntry(
      dartType: fields[1],
      family: fields[2],
      status: fields[3],
      rustVariant: fields[4] == '-' ? null : fields[4],
      dartSource: fields[5],
    );
    switch (fields.first) {
      case 'domain':
        domainEntries.add(entry);
        break;
      case 'system':
        systemEntries.add(entry);
        break;
      case 'event':
        eventEntries.add(entry);
        break;
      case 'evidence':
        evidenceEntries.add(entry);
        break;
    }
  }

  void _addQuery(List<String> fields, String line) {
    if (fields.length != 6) {
      throw FormatException('Malformed query inventory line: $line');
    }
    queryEntries.add(
      _QueryEntry(
        queryVariant: fields[1],
        resultVariant: fields[2],
        clientResultVariant: fields[3],
        family: fields[4],
        status: fields[5],
      ),
    );
  }

  void _addProjectionType(List<String> fields, String line) {
    if (fields.length != 6) {
      throw FormatException('Malformed projection type line: $line');
    }
    projectionTypes.add(
      _ProjectionTypeEntry(
        rustType: fields[1],
        kind: fields[2],
        status: fields[3],
        dtoType: fields[4],
        rustSource: fields[5],
      ),
    );
  }

  void _addProjectionVariant(List<String> fields, String line) {
    if (fields.length != 5) {
      throw FormatException('Malformed projection variant line: $line');
    }
    projectionVariants.add(
      _ProjectionVariantEntry(
        rustVariant: fields[1],
        kind: fields[2],
        status: fields[3],
        dtoVariant: fields[4],
      ),
    );
  }

  void _addDirective(List<String> fields, String line) {
    if (fields.length != 2) {
      throw FormatException('Malformed directive: $line');
    }
    if (!_migrationInventoryDirectives.contains(fields.first)) {
      throw FormatException('Unknown inventory directive: ${fields.first}');
    }
    if (directives.containsKey(fields.first)) {
      throw FormatException('Duplicate directive: ${fields.first}');
    }
    directives[fields.first] = fields[1];
  }

  _MigrationInventory build() {
    _requireUnique(domainEntries, 'domain command');
    _requireUnique(systemEntries, 'system command');
    _requireCount('expected-domain-count', domainEntries.length);
    _requireCount('expected-system-count', systemEntries.length);
    _requireCount('expected-query-count', queryEntries.length);
    _requireCount('expected-event-count', eventEntries.length);
    _requireCount('expected-evidence-count', evidenceEntries.length);
    _requireCount('expected-projection-type-count', projectionTypes.length);
    _requireCount(
      'expected-projection-variant-count',
      projectionVariants.length,
    );
    return _MigrationInventory(
      dartDomainRoot: directives['dart-domain-root']!,
      dartSystemSource: directives['dart-system-source']!,
      dartEventRoot: directives['dart-event-root']!,
      rustDomainSource: directives['rust-domain-source']!,
      rustSystemSource: directives['rust-system-source'] == '-'
          ? null
          : directives['rust-system-source'],
      rustQuerySource: directives['rust-query-source']!,
      rustEventSource: directives['rust-event-source']!,
      rustEvidenceSource: directives['rust-evidence-source']!,
      rustPersistenceSource: directives['rust-persistence-source']!,
      rustClientCommandSource: directives['rust-client-command-source']!,
      rustClientResponseSource: directives['rust-client-response-source']!,
      rustProjectionSource: directives['rust-projection-source']!,
      partialParityMode: directives['partial-parity-mode']!,
      domainEntries: List.unmodifiable(domainEntries),
      systemEntries: List.unmodifiable(systemEntries),
      queryEntries: List.unmodifiable(queryEntries),
      eventEntries: List.unmodifiable(eventEntries),
      evidenceEntries: List.unmodifiable(evidenceEntries),
      projectionTypes: List.unmodifiable(projectionTypes),
      projectionVariants: List.unmodifiable(projectionVariants),
    );
  }

  void _requireUnique(List<_InventoryEntry> entries, String label) {
    if (entries.map((entry) => entry.dartType).toSet().length !=
        entries.length) {
      throw FormatException('Duplicate $label entry.');
    }
  }

  void _requireCount(String directive, int actual) {
    if (int.parse(directives[directive]!) != actual) {
      throw FormatException('$directive does not match the inventory.');
    }
  }
}

const _migrationInventoryDirectives = {
  'oracle-tree',
  'expected-domain-count',
  'expected-system-count',
  'expected-query-count',
  'expected-event-count',
  'expected-evidence-count',
  'expected-projection-type-count',
  'expected-projection-variant-count',
  'dart-domain-root',
  'dart-system-source',
  'dart-event-root',
  'dart-evidence-source',
  'rust-domain-source',
  'rust-system-source',
  'rust-query-source',
  'rust-event-source',
  'rust-evidence-source',
  'rust-persistence-source',
  'rust-client-command-source',
  'rust-client-response-source',
  'rust-projection-source',
  'partial-parity-mode',
};

final class _InventoryEntry {
  const _InventoryEntry({
    required this.dartType,
    required this.family,
    required this.status,
    required this.rustVariant,
    required this.dartSource,
  });

  final String dartType;
  final String family;
  final String status;
  final String? rustVariant;
  final String dartSource;
}

final class _QueryEntry {
  const _QueryEntry({
    required this.queryVariant,
    required this.resultVariant,
    required this.clientResultVariant,
    required this.family,
    required this.status,
  });

  final String queryVariant;
  final String resultVariant;
  final String clientResultVariant;
  final String family;
  final String status;
}

final class _ProjectionTypeEntry {
  const _ProjectionTypeEntry({
    required this.rustType,
    required this.kind,
    required this.status,
    required this.dtoType,
    required this.rustSource,
  });

  final String rustType;
  final String kind;
  final String status;
  final String dtoType;
  final String rustSource;
}

final class _ProjectionVariantEntry {
  const _ProjectionVariantEntry({
    required this.rustVariant,
    required this.kind,
    required this.status,
    required this.dtoVariant,
  });

  final String rustVariant;
  final String kind;
  final String status;
  final String dtoVariant;
}
