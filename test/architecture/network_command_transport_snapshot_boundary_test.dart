import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

part 'support/network_command_transport_snapshot_ast.dart';
part 'support/network_command_transport_snapshot_contract_guard.dart';
part 'support/network_command_transport_snapshot_flow_guard.dart';

const _commandTransportPath =
    'lib/game/application/ports/command_transport.dart';
const _networkTransportPath =
    'lib/api/transport/network_command_transport.dart';
const _acknowledgedPresentationPath =
    'lib/api/transport/acknowledged_command_presentation.dart';

void main() {
  group('network command snapshot boundary', () {
    test('result exposes one required nullable snapshot', () {
      expect(
        _commandTransportResultViolations(_unitAt(_commandTransportPath)),
        isEmpty,
      );
    });

    test('transport never synthesizes a client-side save snapshot', () {
      expect(
        _networkSnapshotOwnershipViolations(_unitAt(_networkTransportPath)),
        isEmpty,
      );
    });

    test('result paths distinguish transient and stored snapshots', () {
      expect(
        _networkResultFlowViolations(
          _unitAt(_networkTransportPath),
          _unitAt(_acknowledgedPresentationPath),
        ),
        isEmpty,
      );
    });

    test('obsolete network snapshot store is absent from production', () {
      expect(
        _obsoleteNetworkSnapshotStoreViolations(productionDartSources()),
        isEmpty,
      );
    });

    test('production scan ignores comments and string contents', () {
      const fixture = '''
// NetworkSnapshotStore and network_snapshot_store.dart are historical names.
const note = 'NetworkSnapshotStore: network_snapshot_store.dart';
''';

      expect(
        _obsoleteNetworkSnapshotStoreViolations({
          'lib/history_note.dart': fixture,
        }),
        isEmpty,
      );
    });
  });
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}
