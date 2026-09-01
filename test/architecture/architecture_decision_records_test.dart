import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture decision records', () {
    test('keep a contiguous indexed set of decisions', () {
      final allMarkdownFiles = _allAdrMarkdownFileNames();
      expect(
        allMarkdownFiles,
        everyElement(
          anyOf(
            'README.md',
            predicate<String>(
              (fileName) => _adrFileNamePattern.hasMatch(fileName),
              'a zero-padded numbered ADR filename',
            ),
          ),
        ),
      );
      final adrFiles = _adrFileNames();
      expect(adrFiles, containsAll(_requiredAcceptedAdrs.keys));
      final numbers = adrFiles
          .map((fileName) => int.parse(fileName.substring(0, 4)))
          .toList();
      expect(numbers, List.generate(numbers.length, (index) => index + 1));

      final index = File('docs/adr/README.md').readAsStringSync();
      final indexedFiles =
          _indexedAdrPattern
              .allMatches(index)
              .map((match) => match.group(1)!)
              .toList()
            ..sort();
      expect(indexedFiles, adrFiles);

      for (final fileName in adrFiles) {
        final source = File('docs/adr/$fileName').readAsStringSync();
        final number = fileName.substring(0, 4);
        final rows = index
            .split('\n')
            .where((line) => line.startsWith('| [$number]($fileName) |'));
        expect(rows, hasLength(1), reason: fileName);
        final cells = rows.single
            .split('|')
            .map((cell) => cell.trim())
            .where((cell) => cell.isNotEmpty)
            .toList();
        expect(cells, hasLength(4), reason: rows.single);
        final title = source.split('\n').first.split(': ').skip(1).join(': ');
        expect(cells[1].toLowerCase(), title.toLowerCase(), reason: fileName);
        expect(
          cells[2],
          _metadataValue(source, 'Status', fileName),
          reason: fileName,
        );
        expect(
          cells[3],
          _metadataValue(source, 'Implementation', fileName),
          reason: fileName,
        );
      }
    });

    test('state binding decisions and incomplete migration honestly', () {
      for (final fileName in _adrFileNames()) {
        final source = File('docs/adr/$fileName').readAsStringSync();
        final number = fileName.substring(0, 4);
        expect(
          source.split('\n').first,
          startsWith('# ADR $number: '),
          reason: fileName,
        );
        final status = _metadataValue(source, 'Status', fileName);
        final implementation = _metadataValue(
          source,
          'Implementation',
          fileName,
        );
        final date = _metadataValue(source, 'Date', fileName);
        expect(_allowedStatuses, contains(status), reason: fileName);
        expect(
          _allowedImplementations,
          contains(implementation),
          reason: fileName,
        );
        expect(
          RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date),
          isTrue,
          reason: fileName,
        );
        expect(DateTime.tryParse(date), isNotNull, reason: fileName);
        if (status == 'Superseded') {
          expect(source, contains('Superseded by'), reason: fileName);
        }
        for (final heading in _requiredHeadings) {
          expect(_hasLine(source, heading), isTrue, reason: fileName);
        }
        expect(
          source
              .split('\n')
              .any(
                (line) => RegExp(
                  r'^## Rejected alternatives:?$',
                  caseSensitive: false,
                ).hasMatch(line.trim()),
              ),
          isTrue,
          reason: fileName,
        );
        expect(source, contains('```mermaid'), reason: fileName);
      }

      for (final entry in _requiredAcceptedAdrs.entries) {
        final source = File('docs/adr/${entry.key}').readAsStringSync();
        expect(
          source.split('\n').first,
          '# ADR ${entry.key.substring(0, 4)}: ${entry.value}',
        );
        expect(_metadataValue(source, 'Status', entry.key), 'Accepted');
      }
    });

    test('are discoverable from contributor documentation', () {
      final docsIndex = File('docs/README.md').readAsStringSync();
      final rootReadme = File('README.md').readAsStringSync();
      final contributing = File('CONTRIBUTING.md').readAsStringSync();
      final pullRequestTemplate = File(
        '.github/PULL_REQUEST_TEMPLATE.md',
      ).readAsStringSync();

      expect(docsIndex, contains('(adr/README.md)'));
      expect(rootReadme, contains('(docs/adr/README.md)'));
      expect(contributing, contains('(docs/adr/README.md)'));
      expect(pullRequestTemplate, contains('docs/adr/README.md'));
      for (final fileName in _requiredAcceptedAdrs.keys) {
        expect(docsIndex, contains('(adr/$fileName)'), reason: fileName);
      }
    });

    test('new decision navigation contains no broken relative links', () {
      final files = [
        File('README.md'),
        File('CONTRIBUTING.md'),
        File('docs/README.md'),
        File('docs/build-and-deploy.md'),
        File('docs/multiplayer-protocol.md'),
        File('docs/multiplayer-scale-out.md'),
        File('lib/api/protocol/README.md'),
        File('lib/api/transport/README.md'),
        File('docs/adr/README.md'),
        for (final fileName in _adrFileNames()) File('docs/adr/$fileName'),
      ];

      for (final file in files) {
        final source = file.readAsStringSync();
        for (final match in _markdownLinkPattern.allMatches(source)) {
          final rawTarget = match.group(1)!;
          if (_isExternalOrAnchor(rawTarget)) continue;
          final target = rawTarget.split('#').first;
          final linkedPath = '${file.parent.path}/$target';
          expect(
            FileSystemEntity.typeSync(linkedPath),
            isNot(FileSystemEntityType.notFound),
            reason: '${file.path} -> $rawTarget',
          );
        }
      }
    });

    test(
      'current runbooks link to target decisions without claiming completion',
      () {
        final protocol = File(
          'docs/multiplayer-protocol.md',
        ).readAsStringSync();
        final deployment = File('docs/build-and-deploy.md').readAsStringSync();

        expect(
          protocol,
          contains('(adr/0004-versioned-multiplayer-protocol.md)'),
        );
        expect(protocol, contains('active functional revision'));
        expect(deployment, contains('(adr/0005-immutable-deployment.md)'));
        expect(deployment, contains('currently implemented workflow'));
      },
    );
  });
}

bool _hasLine(String source, String expected) =>
    source.split('\n').any((line) => line.trim() == expected);

List<String> _allAdrMarkdownFileNames() => Directory('docs/adr')
    .listSync()
    .whereType<File>()
    .map((file) => file.path.split(Platform.pathSeparator).last)
    .where((fileName) => fileName.endsWith('.md'))
    .toList();

List<String> _adrFileNames() =>
    (_allAdrMarkdownFileNames()
        .where((fileName) => _adrFileNamePattern.hasMatch(fileName))
        .toList()
      ..sort());

String _metadataValue(String source, String key, String fileName) {
  final prefix = '- $key: ';
  final values = source
      .split('\n')
      .where((line) => line.startsWith(prefix))
      .map((line) => line.substring(prefix.length).trim())
      .toList();
  if (values.length != 1 || values.single.isEmpty) {
    throw StateError('$fileName must declare exactly one non-empty $key.');
  }
  return values.single;
}

bool _isExternalOrAnchor(String target) =>
    target.startsWith('#') ||
    target.startsWith('http://') ||
    target.startsWith('https://') ||
    target.startsWith('mailto:');

final _markdownLinkPattern = RegExp(r'\[[^\]]+\]\(([^)]+)\)');
final _adrFileNamePattern = RegExp(r'^\d{4}-.+\.md$');
final _indexedAdrPattern = RegExp(
  r'^\| \[\d{4}\]\((\d{4}-[^)]+\.md)\) \|',
  multiLine: true,
);

const _requiredHeadings = [
  '## Context',
  '## Decision',
  '## Consequences',
  '## Migration And Verification',
  '## Related Decisions And Documentation',
];

const _allowedStatuses = {'Proposed', 'Accepted', 'Rejected', 'Superseded'};
const _allowedImplementations = {'Planned', 'In progress', 'Implemented'};

const _requiredAcceptedAdrs = <String, String>{
  '0003-command-boundaries.md': 'Command Boundaries',
  '0004-versioned-multiplayer-protocol.md': 'Versioned Multiplayer Protocol',
  '0005-immutable-deployment.md': 'Immutable Deployment Promotion',
  '0006-transport-infrastructure.md':
      'Transport Infrastructure Ownership And Traversal',
  '0007-strategic-resource-stockpiles.md':
      'Strategic Resource Stockpiles And Production Allocation',
  '0008-rust-engine-ownership-and-strangler-migration.md':
      'Rust Engine Ownership And Strangler Migration',
};
