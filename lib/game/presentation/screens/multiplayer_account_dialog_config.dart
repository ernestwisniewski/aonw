part of 'multiplayer_account_dialog.dart';

Future<NetworkAuthResult?> showMultiplayerAccountDialog({
  required BuildContext context,
  required MultiplayerAccountAction login,
  required MultiplayerCreateAccountAction createAccount,
  MultiplayerSocialAuthClientFactory? socialAuthClientFactory,
  MultiplayerCompleteSocialAuthAction? completeSocialAuth,
  MultiplayerSteamAuthAction? steamAuth,
  String initialDisplayName = '',
}) {
  return showGameModal<NetworkAuthResult>(
    context: context,
    size: GameModalSize.regular,
    requestFocus: true,
    builder: (dialogContext) => _MultiplayerAccountDialog(
      login: login,
      createAccount: createAccount,
      socialAuthClientFactory: socialAuthClientFactory,
      completeSocialAuth: completeSocialAuth,
      steamAuth: steamAuth,
      initialDisplayName: initialDisplayName,
    ),
  );
}

typedef MultiplayerAccountAction =
    Future<NetworkAuthResult> Function({
      required String email,
      required String password,
    });
typedef MultiplayerCreateAccountAction =
    Future<NetworkAuthResult> Function({
      required String email,
      required String password,
      required String displayName,
    });
typedef MultiplayerSocialAuthClientFactory = sp.Client Function();
typedef MultiplayerCompleteSocialAuthAction =
    Future<NetworkAuthResult> Function({required sp_auth.AuthSuccess auth});
typedef MultiplayerSteamAuthAction = Future<NetworkAuthResult> Function();

const _defaultGoogleWebClientId =
    '421226196002-m0f4ncq3o59uc0vvpj0lniuq99os9bbg.apps.googleusercontent.com';
const _defaultAppleServiceIdentifier = 'aonw.net.game.signin';
const _defaultAppleRedirectUri = 'https://api.aonw.net/auth/apple/callback';

enum _AccountMode { signIn, create }

sp.Client createMultiplayerSocialAuthClient(String serverpodHost) {
  return createServerpodClient(serverpodHost)
    ..authSessionManager = FlutterAuthSessionManager(
      storage: _EphemeralAuthSuccessStorage(),
    );
}
