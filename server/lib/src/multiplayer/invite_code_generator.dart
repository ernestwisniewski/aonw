import 'dart:math';

abstract interface class InviteCodeGenerator {
  String generate();
}

final class SecureInviteCodeGenerator implements InviteCodeGenerator {
  SecureInviteCodeGenerator({Random? random})
    : _random = random ?? Random.secure();

  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const codeLength = 13;
  static const entropyBits = 65;

  final Random _random;

  @override
  String generate() {
    return String.fromCharCodes(
      List.generate(
        codeLength,
        (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
        growable: false,
      ),
    );
  }

  static bool isValid(String code) {
    return code.length == codeLength &&
        code.codeUnits.every(
          (codeUnit) => alphabet.codeUnits.contains(codeUnit),
        );
  }
}
