import 'package:flutter_test/flutter_test.dart';

import '../../tool/run_save_ai_benchmark/runtime_smoke_offset_sequence.dart';

void main() {
  test('runtime smoke advances absolute event offsets one at a time', () {
    final offsets = RuntimeSmokeOffsetSequence(initialOffset: 41);

    expect([offsets.next(), offsets.next(), offsets.next()], [42, 43, 44]);
  });
}
