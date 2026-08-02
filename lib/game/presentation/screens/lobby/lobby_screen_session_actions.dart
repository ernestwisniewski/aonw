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
      socialAuthClientFactory: ref.read(nativeSocialAuthSessionFactoryProvider),
      completeSocialAuth: client.completeNativeSocialAuth,
      externalAuth: client.loginWithExternalProvider,
      steamAuth: client.loginWithSteam,
      initialDisplayName: initialDisplayName,
    );
  }
}
