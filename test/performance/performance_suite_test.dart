import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/performance/suite.dart';

const _enabled = bool.fromEnvironment('AONW_RUN_PERFORMANCE');
const _reportPath = String.fromEnvironment('AONW_PERFORMANCE_REPORT');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'writes the canonical portable performance report',
    () async {
      if (_reportPath.isEmpty) {
        fail('AONW_PERFORMANCE_REPORT must name the output file.');
      }
      final report = await runPerformanceSuite();
      final file = File(_reportPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report.canonicalJson, flush: true);
      expect(report.stable.keys, hasLength(13));
      expect(await file.readAsString(), report.canonicalJson);
    },
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
