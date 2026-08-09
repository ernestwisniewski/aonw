import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

/// Maps multiplayer protocol failures to stable, localized lobby copy.
String lobbyMultiplayerFailureText(
  MultiplayerFailure error,
  AppLocalizations l10n,
) {
  final mapped = <String, String>{
    'unsupported_multiplayer_version': l10n.mainMenuUpdateSoonBody,
    'unsupported_match_protocol': l10n.mainMenuUpdateSoonBody,
    'auth_required': l10n.multiplayerSignInRequired,
    'match_not_found': l10n.multiplayerMatchUnavailable,
    'private_match_not_found': l10n.multiplayerMatchUnavailable,
    'match_not_open': l10n.multiplayerMatchUnavailable,
    'match_finished': l10n.multiplayerMatchUnavailable,
    'match_abandoned': l10n.multiplayerMatchUnavailable,
    'not_match_player': l10n.multiplayerMatchAccessDenied,
    'wrong_actor': l10n.multiplayerMatchAccessDenied,
    'not_match_owner': l10n.multiplayerMatchAccessDenied,
    'match_full': l10n.multiplayerMatchFull,
    'country_unavailable': l10n.multiplayerCountryUnavailable,
    'not_enough_players': l10n.multiplayerMatchNotReady,
  }[error.code];
  if (mapped != null) return mapped;
  final message = error.message;
  return message != null && message.isNotEmpty
      ? message
      : l10n.multiplayerQueueGenericError;
}
