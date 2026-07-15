import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_gate/acknowledged_export_only_barrel.dart';

void main() {
  const path = 'lib/domain.dart';
  const acknowledged = <String>{path};

  test('accepts an acknowledged export-only barrel', () {
    expect(
      isAcknowledgedExportOnlyBarrel(
        path: path,
        acknowledgedMissingFiles: acknowledged,
        source: "library domain;\nexport 'domain/logic.dart' show answer;\n",
      ),
      isTrue,
    );
  });

  test('requires the exact baseline acknowledgement', () {
    expect(
      isAcknowledgedExportOnlyBarrel(
        path: path,
        acknowledgedMissingFiles: const {},
        source: "export 'domain/logic.dart';\n",
      ),
      isFalse,
    );
  });

  for (final source in <String>[
    "import 'domain/logic.dart';\nexport 'domain/logic.dart';\n",
    "library domain;\npart 'domain/logic.dart';\n",
    "export 'domain/logic.dart';\nint answer() => 42;\n",
    'library domain;\n',
  ]) {
    test('rejects non-export-only source: ${source.split('\n').first}', () {
      expect(
        isAcknowledgedExportOnlyBarrel(
          path: path,
          acknowledgedMissingFiles: acknowledged,
          source: source,
        ),
        isFalse,
      );
    });
  }
}
