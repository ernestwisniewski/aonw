part of 'multiplayer_account_dialog.dart';

class _EmailAccountForm extends StatelessWidget {
  const _EmailAccountForm({
    required this.l10n,
    required this.mode,
    required this.busy,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.onModeChanged,
    required this.onSubmitted,
  });

  final AppLocalizations l10n;
  final _AccountMode mode;
  final bool busy;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<_AccountMode> onModeChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_AccountMode>(
          segments: [
            ButtonSegment<_AccountMode>(
              value: _AccountMode.signIn,
              label: Text(l10n.multiplayerAccountSignInTab),
            ),
            ButtonSegment<_AccountMode>(
              value: _AccountMode.create,
              label: Text(l10n.multiplayerAccountCreateTab),
            ),
          ],
          selected: {mode},
          onSelectionChanged: busy
              ? null
              : (selected) => onModeChanged(selected.single),
        ),
        const SizedBox(height: 18),
        if (mode == _AccountMode.create) ...[
          TextField(
            key: const Key('multiplayer.account.nickname'),
            controller: nicknameController,
            enabled: !busy,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.nickname],
            style: GameUiTheme.inputText,
            decoration: GameUiTheme.textFieldDecoration(
              hintText: l10n.multiplayerNicknameLabel,
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          key: const Key('multiplayer.account.email'),
          controller: emailController,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          style: GameUiTheme.inputText,
          decoration: GameUiTheme.textFieldDecoration(
            hintText: l10n.multiplayerAccountEmailLabel,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('multiplayer.account.password'),
          controller: passwordController,
          enabled: !busy,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: [
            mode == _AccountMode.signIn
                ? AutofillHints.password
                : AutofillHints.newPassword,
          ],
          style: GameUiTheme.inputText,
          decoration: GameUiTheme.textFieldDecoration(
            hintText: l10n.multiplayerAccountPasswordLabel,
          ),
          onSubmitted: (_) {
            if (!busy) onSubmitted();
          },
        ),
      ],
    );
  }
}

class _AuthMethodButtons extends StatelessWidget {
  const _AuthMethodButtons({
    required this.emailSelected,
    required this.onEmailPressed,
    this.client,
    this.socialAuthReady = false,
    this.showNativeGoogle = false,
    this.showNativeApple = false,
    this.onAuthenticated,
    this.onError,
    this.onGooglePressed,
    this.onApplePressed,
    this.onSteamPressed,
  });

  static const _minimumButtonWidth = 240.0;
  static const _preferredButtonWidth = 300.0;

  final sp.Client? client;
  final bool socialAuthReady;
  final bool showNativeGoogle;
  final bool showNativeApple;
  final bool emailSelected;
  final VoidCallback onEmailPressed;
  final VoidCallback? onAuthenticated;
  final void Function(Object error)? onError;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final VoidCallback? onSteamPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _layout(context, constraints),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final width = _buttonWidthFor(constraints);
    final google = _googleButton(width);
    final apple = _appleButton(width);
    return Align(
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          if (onSteamPressed != null) _steamButton(width),
          ?google,
          ?apple,
          _emailButton(context, width),
        ],
      ),
    );
  }

  Widget _steamButton(double width) {
    return _methodSlot(
      width: width,
      child: EpicButton.outlined(
        key: const Key('multiplayer.account.steam'),
        onPressed: onSteamPressed,
        label: 'Steam',
        icon: Icons.sports_esports_rounded,
        minWidth: width,
      ),
    );
  }

  Widget? _googleButton(double width) {
    final external = onGooglePressed;
    if (external != null) {
      return _methodSlot(
        width: width,
        child: _ExternalProviderButton(
          key: const Key('multiplayer.account.google'),
          onPressed: external,
          label: 'Google',
          icon: Icons.account_circle_outlined,
          width: width,
        ),
      );
    }
    final authClient = client;
    if (!showNativeGoogle || authClient == null) return null;
    final readyAuthClient = socialAuthReady ? authClient : null;
    return _methodSlot(
      width: width,
      child: readyAuthClient == null
          ? _DisabledGoogleButton(width: width)
          : GoogleSignInWidget(
              key: const Key('multiplayer.account.google'),
              client: readyAuthClient,
              onAuthenticated: onAuthenticated,
              onError: onError,
              shape: GSIButtonShape.rectangular,
              logoAlignment: GSIButtonLogoAlignment.left,
              minimumWidth: width,
            ),
    );
  }

  Widget? _appleButton(double width) {
    final external = onApplePressed;
    if (external != null) {
      return _methodSlot(
        width: width,
        child: _ExternalProviderButton(
          key: const Key('multiplayer.account.apple'),
          onPressed: external,
          label: 'Apple',
          icon: Icons.apple,
          width: width,
        ),
      );
    }
    final authClient = socialAuthReady ? client : null;
    if (!showNativeApple || authClient == null) return null;
    return _methodSlot(
      width: width,
      child: AppleSignInWidget(
        key: const Key('multiplayer.account.apple'),
        client: authClient,
        onAuthenticated: onAuthenticated,
        onError: onError,
        shape: AppleButtonShape.rectangular,
        logoAlignment: AppleButtonLogoAlignment.left,
        minimumWidth: width,
      ),
    );
  }

  Widget _emailButton(BuildContext context, double width) {
    final label = AppLocalizations.of(context).multiplayerAccountEmailLabel;
    final button = emailSelected
        ? EpicButton.primary(
            key: const Key('multiplayer.account.emailMethod'),
            onPressed: onEmailPressed,
            label: label,
            icon: Icons.mail_outline_rounded,
            minWidth: width,
          )
        : EpicButton.outlined(
            key: const Key('multiplayer.account.emailMethod'),
            onPressed: onEmailPressed,
            label: label,
            icon: Icons.mail_outline_rounded,
            minWidth: width,
          );
    return _methodSlot(width: width, child: button);
  }

  double _buttonWidthFor(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return _preferredButtonWidth;
    return constraints.maxWidth
        .clamp(_minimumButtonWidth, _preferredButtonWidth)
        .toDouble();
  }

  Widget _methodSlot({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }
}

class _ExternalProviderButton extends StatelessWidget {
  const _ExternalProviderButton({
    required super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.width,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return EpicButton.outlined(
      onPressed: onPressed,
      label: label,
      icon: icon,
      minWidth: width,
    );
  }
}

class _DisabledGoogleButton extends StatelessWidget {
  const _DisabledGoogleButton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('multiplayer.account.google.initializing'),
      onPressed: null,
      icon: const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      label: const Text('Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(width, 40),
        textStyle: GameUiTheme.menuButton,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        ),
      ),
    );
  }
}

class _EphemeralAuthSuccessStorage implements ClientAuthSuccessStorage {
  sp_auth.AuthSuccess? _auth;

  @override
  Future<sp_auth.AuthSuccess?> get() async => _auth;

  @override
  Future<void> set(sp_auth.AuthSuccess? data) async {
    _auth = data;
  }
}

String? _googleClientId() {
  const configured = String.fromEnvironment('GOOGLE_CLIENT_ID');
  if (configured.isNotEmpty) return configured;
  if (kIsWeb) return _defaultGoogleWebClientId;
  return null;
}

String _googleServerClientId() {
  const configured = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  if (configured.isNotEmpty) return configured;
  return _defaultGoogleWebClientId;
}

String _appleServiceIdentifier() {
  const configured = String.fromEnvironment('APPLE_SERVICE_IDENTIFIER');
  if (configured.isNotEmpty) return configured;
  return _defaultAppleServiceIdentifier;
}

String _appleRedirectUri() {
  const configured = String.fromEnvironment('APPLE_REDIRECT_URI');
  if (configured.isNotEmpty) return configured;
  return _defaultAppleRedirectUri;
}

bool get _supportsNativeGoogleSignIn {
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool get _supportsNativeAppleSignIn {
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

bool get _supportsNativeSocialSignIn =>
    _supportsNativeGoogleSignIn || _supportsNativeAppleSignIn;

bool get _usesExternalAppleSignIn {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);
}

bool get _usesExternalGoogleSignIn {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);
}

bool get _supportsSteamSignIn {
  return kIsWeb ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

String? _accountLocalError({
  required AppLocalizations l10n,
  required _AccountMode mode,
  required String email,
  required String password,
  required String displayName,
}) {
  if (mode == _AccountMode.create && !_validDisplayName(displayName)) {
    return l10n.multiplayerAccountInvalidNickname;
  }
  if (email.isEmpty || !email.contains('@')) {
    return l10n.multiplayerAccountInvalidEmail;
  }
  if (mode == _AccountMode.create && password.length < 8) {
    return l10n.multiplayerAccountWeakPassword;
  }
  if (password.isEmpty) return l10n.multiplayerAccountInvalidCredentials;
  return null;
}

String _accountErrorText(AppLocalizations l10n, Object error) {
  if (error is sp.AccountAuthException) {
    return switch (error.code) {
      'invalid_email' => l10n.multiplayerAccountInvalidEmail,
      'invalid_credentials' => l10n.multiplayerAccountInvalidCredentials,
      'account_exists' => l10n.multiplayerAccountExists,
      'weak_password' => l10n.multiplayerAccountWeakPassword,
      'invalid_display_name' => l10n.multiplayerAccountInvalidNickname,
      'display_name_taken' => l10n.multiplayerAccountNicknameTaken,
      _ => l10n.multiplayerAccountGenericError,
    };
  }
  return l10n.multiplayerAccountGenericError;
}

bool _validDisplayName(String displayName) {
  if (displayName.length < 3 || displayName.length > 24) return false;
  return RegExp(r'^[\p{L}\p{N} _-]+$', unicode: true).hasMatch(displayName);
}
