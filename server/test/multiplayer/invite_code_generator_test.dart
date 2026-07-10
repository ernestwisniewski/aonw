import 'dart:math';

import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:test/test.dart';

void main() {
  test('generates 65-bit Base32 codes with an unambiguous alphabet', () {
    final generator = SecureInviteCodeGenerator(random: _CyclingRandom());

    final code = generator.generate();
    final calculatedEntropy =
        SecureInviteCodeGenerator.codeLength *
        (log(SecureInviteCodeGenerator.alphabet.length) / log(2));

    expect(code, 'ABCDEFGHJKLMN');
    expect(SecureInviteCodeGenerator.alphabet, hasLength(32));
    expect(calculatedEntropy, greaterThanOrEqualTo(64));
    expect(SecureInviteCodeGenerator.entropyBits, 65);
    expect(SecureInviteCodeGenerator.isValid(code), isTrue);
    expect(SecureInviteCodeGenerator.isValid('MATCHABC'), isFalse);
  });
}

final class _CyclingRandom implements Random {
  var _value = 0;

  @override
  bool nextBool() => throw UnsupportedError('Not used by the generator.');

  @override
  double nextDouble() => throw UnsupportedError('Not used by the generator.');

  @override
  int nextInt(int max) {
    final value = _value;
    _value = (_value + 1) % max;
    return value;
  }
}
