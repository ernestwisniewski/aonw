import 'invite_code_generator.dart';
import 'multiplayer_errors.dart';

/// Bounds opaque multiplayer identifiers before they reach persistence or
/// realtime coordination code.
final class MultiplayerInputValidator {
  const MultiplayerInputValidator();

  static const maxMatchIdLength = 64;
  static const maxEventOffset = 0x7fffffff;

  static final RegExp _matchIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$');

  String matchId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.length > maxMatchIdLength ||
        !_matchIdPattern.hasMatch(normalized)) {
      throw multiplayerException('invalid_match_id', 'Match ID is invalid.');
    }
    return normalized;
  }

  String inviteCode(String value) {
    final normalized = value.trim().toUpperCase();
    if (!SecureInviteCodeGenerator.isValid(normalized)) {
      throw multiplayerException(
        'private_match_not_found',
        'Private match not found.',
      );
    }
    return normalized;
  }

  int afterOffset(int value) {
    if (value < 0 || value > maxEventOffset) {
      throw multiplayerException(
        'invalid_event_offset',
        'Event offset is invalid.',
      );
    }
    return value;
  }
}
