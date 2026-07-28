import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

part 'support/initial_multiplayer_snapshot_boundary_guard.dart';

const _initialFactoryPath =
    'server/lib/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
const _mapCatalogPath =
    'server/lib/src/multiplayer/multiplayer_map_catalog.dart';
const _wirePlayerMapperPath =
    'server/lib/src/multiplayer/wire_player_domain_mapper.dart';
const _lifecyclePath =
    'server/lib/src/multiplayer/match_lifecycle_service.dart';
const _outcomePath =
    'server/lib/src/multiplayer/server_command_reducer_outcome.dart';
const _initialCodecPath =
    'server/lib/src/multiplayer/running_match_snapshot_codec.dart';

void main() {
  test('initial factory constructs one canonical snapshot without legacy', () {
    expect(_initialFactoryViolations(_unitAt(_initialFactoryPath)), isEmpty);
  });

  test('wire player mapping has exactly three production call sites', () {
    final sources = productionDartSources();

    expect(_domainPlayerMapperReferenceCounts(sources), {
      _lifecyclePath: 1,
      _outcomePath: 1,
      _initialCodecPath: 1,
    });
    expect(
      _wirePlayerMapperViolations(_unitAt(_wirePlayerMapperPath)),
      isEmpty,
    );
  });

  test('lifecycle maps, builds, and encodes the initial snapshot once', () {
    expect(_initialLifecycleFlowViolations(_unitAt(_lifecyclePath)), isEmpty);
  });

  test('initial encoder owns validation and historical wire policy', () {
    final unit = _unitAt(_initialCodecPath);

    expect(_initialEncodeFlowViolations(unit), isEmpty);
    expect(_identifierCount(unit, 'toLegacy'), 1);
    expect(_identifierCount(_unitAt(_initialFactoryPath), 'toLegacy'), 0);
    expect(_identifierCount(_unitAt(_initialFactoryPath), 'toCanonical'), 0);
  });

  test('map catalog is independent from the canonical factory', () {
    final factory = _unitAt(_initialFactoryPath);
    final catalog = _unitAt(_mapCatalogPath);

    expect(_importsUri(factory, 'dart:io'), isFalse);
    expect(_exportsUri(factory, 'multiplayer_map_catalog.dart'), isFalse);
    expect(
      _classNamed(catalog, 'FileMultiplayerMapCatalog')?.finalKeyword,
      isNotNull,
    );
  });

  test('guard rejects legacy factory and direct initial conversion', () {
    final legacyFactory = parseString(
      content: _legacyInitialFactoryFixture,
      path: 'fixture_factory.dart',
    ).unit;
    final directCodec = parseString(
      content: _directInitialConversionFixture,
      path: 'fixture_codec.dart',
    ).unit;

    expect(
      _initialFactoryViolations(legacyFactory),
      containsAll([
        'InitialMultiplayerSnapshotFactory must be final',
        'create must expose the exact canonical initial contract',
        'create must construct exactly one CanonicalGameSnapshot',
        'factory must not reference GameSave',
        'factory must not reference WireSnapshot',
      ]),
    );
    expect(
      _initialEncodeFlowViolations(directCodec),
      containsAll([
        'encodeInitial must perform exact lifecycle, id, offset, and implicit '
            'turn-start guards',
        'encodeInitial must use the shared legacy conversion helper once',
        'encodeInitial must apply the initial turn-start wire policy once',
        'encodeInitial must not convert snapshots directly',
      ]),
    );
  });
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}
