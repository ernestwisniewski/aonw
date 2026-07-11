import 'dart:math';

/// Generates bounded, protocol-safe command identifiers for one transport.
///
/// A session nonce keeps identifiers unique when a game is left and resumed,
/// while the sequence keeps commands within one transport ordered. Callers
/// must retain an identifier when retrying the same command.
final class WireCommandMessageIdGenerator {
  static final Random _secureRandom = Random.secure();
  static int _nextProcessNonce = 0;

  final String _sessionNonce = _newSessionNonce();
  int _nextSequence = 0;

  String next() {
    _nextSequence += 1;
    return 'cmd-$_sessionNonce-${_nextSequence.toRadixString(36)}';
  }

  static String _newSessionNonce() {
    final timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toRadixString(36);
    final processNonce = (++_nextProcessNonce).toRadixString(36);
    final randomHigh = _secureRandom.nextInt(1 << 32).toRadixString(36);
    final randomLow = _secureRandom.nextInt(1 << 32).toRadixString(36);
    return '$timestamp-$processNonce-$randomHigh$randomLow';
  }
}
