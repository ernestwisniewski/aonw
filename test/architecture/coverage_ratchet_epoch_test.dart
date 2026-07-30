import 'package:flutter_test/flutter_test.dart';

import '../../tool/coverage_gate/coverage_failure.dart';
import '../../tool/coverage_gate/ratchet_epoch.dart';

void main() {
  test('allows exactly one reviewed ratchet epoch advance', () {
    expect(validateCoverageRatchetEpoch(0, 0), isFalse);
    expect(validateCoverageRatchetEpoch(0, 1), isTrue);
  });

  test('rejects skipped and decreasing ratchet epochs', () {
    expect(
      () => validateCoverageRatchetEpoch(0, 2),
      throwsA(isA<CoverageFailure>()),
    );
    expect(
      () => validateCoverageRatchetEpoch(1, 0),
      throwsA(isA<CoverageFailure>()),
    );
  });
}
