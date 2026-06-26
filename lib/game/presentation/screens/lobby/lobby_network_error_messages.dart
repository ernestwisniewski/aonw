part of 'lobby_screen.dart';

final class _LobbyNetworkErrorMessages {
  final AppLocalizations l10n;
  final String apiHost;

  const _LobbyNetworkErrorMessages({required this.l10n, required this.apiHost});

  String textFor(Object error) {
    if (error is NetworkSignInRequiredException) {
      return l10n.multiplayerSignInRequired;
    }
    if (error is sp.MultiplayerException) {
      return _multiplayerExceptionText(error);
    }
    if (error is sp.AccountAuthException) {
      return _authExceptionText(error);
    }
    if (_isConnectionError(error)) {
      return l10n.multiplayerConnectionError(apiHost);
    }
    if (error is StateError) return error.message;
    return l10n.multiplayerQueueGenericError;
  }

  String _multiplayerExceptionText(sp.MultiplayerException error) {
    final mapped = _mappedMultiplayerExceptionText(error);
    if (mapped != null) return mapped;
    return _nonEmptyMessageOrFallback(error.message);
  }

  String _authExceptionText(sp.AccountAuthException error) {
    return _nonEmptyMessageOrFallback(error.message);
  }

  String _nonEmptyMessageOrFallback(String? message) {
    if (message != null && message.isNotEmpty) return message;
    return l10n.multiplayerQueueGenericError;
  }

  String? _mappedMultiplayerExceptionText(sp.MultiplayerException error) {
    return switch (error.code) {
      'auth_required' => l10n.multiplayerSignInRequired,
      'match_not_found' ||
      'private_match_not_found' ||
      'match_not_open' ||
      'match_finished' ||
      'match_abandoned' => l10n.multiplayerMatchUnavailable,
      'not_match_player' ||
      'wrong_actor' ||
      'not_match_owner' => l10n.multiplayerMatchAccessDenied,
      'match_full' => l10n.multiplayerMatchFull,
      'country_unavailable' => l10n.multiplayerCountryUnavailable,
      'not_enough_players' => l10n.multiplayerMatchNotReady,
      _ => null,
    };
  }

  bool _isConnectionError(Object error) {
    return error is TimeoutException ||
        error is sp.MethodStreamException ||
        error is sp.ServerpodClientException;
  }
}
