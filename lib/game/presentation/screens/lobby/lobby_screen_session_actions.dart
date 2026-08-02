part of 'lobby_screen.dart';

extension _LobbyScreenSessionActions on _LobbyScreenState {
  Future<void> _signOutNetworkSession() {
    final client = ref.read(networkSessionClientProvider);
    return ref
        .read(networkSessionRefreshCoordinatorProvider)
        .revokeAndTerminate(client.signOutCurrentSession);
  }

  Future<NetworkAuthResult?> _authenticateNetworkSession({
    required String initialDisplayName,
  }) async {
    if (!mounted) return null;
    final client = ref.read(networkSessionClientProvider);
    return showMultiplayerAccountDialog(
      context: context,
      login: client.login,
      createAccount: client.createAccount,
      socialAuthClientFactory: () =>
          createMultiplayerSocialAuthClient(client.serverpodHost),
      completeSocialAuth: client.completeSocialAuth,
      externalAuth: client.loginWithExternalProvider,
      steamAuth: client.loginWithSteam,
      initialDisplayName: initialDisplayName,
    );
  }
}
