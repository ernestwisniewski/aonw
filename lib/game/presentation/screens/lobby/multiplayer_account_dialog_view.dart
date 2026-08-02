part of 'multiplayer_account_dialog.dart';

class _AccountDialogView extends StatelessWidget {
  const _AccountDialogView({
    required this.l10n,
    required this.busy,
    required this.externalAuthBusy,
    required this.socialAuthClient,
    required this.socialAuthReady,
    required this.showNativeGoogle,
    required this.showNativeApple,
    required this.showExternalGoogle,
    required this.showExternalApple,
    required this.showSteam,
    required this.emailFormExpanded,
    required this.mode,
    required this.error,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.onClose,
    required this.onEmailPressed,
    required this.onAuthenticated,
    required this.onSocialError,
    required this.onGooglePressed,
    required this.onApplePressed,
    required this.onSteamPressed,
    required this.onModeChanged,
    required this.onSubmitted,
  });

  final AppLocalizations l10n;
  final bool busy;
  final bool externalAuthBusy;
  final sp.Client? socialAuthClient;
  final bool socialAuthReady;
  final bool showNativeGoogle;
  final bool showNativeApple;
  final bool showExternalGoogle;
  final bool showExternalApple;
  final bool showSteam;
  final bool emailFormExpanded;
  final _AccountMode mode;
  final String? error;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onClose;
  final VoidCallback onEmailPressed;
  final VoidCallback onAuthenticated;
  final void Function(Object error) onSocialError;
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final VoidCallback onSteamPressed;
  final ValueChanged<_AccountMode> onModeChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return GameModalScaffold(
      size: GameModalSize.regular,
      surfaceKey: const Key('multiplayer.account.surface'),
      header: _header(),
      content: _content(),
      actions: _actions(),
    );
  }

  GameModalHeader _header() {
    return GameModalHeader(
      title: l10n.multiplayerAccountTitle,
      subtitle: l10n.multiplayerAccountSubtitle,
      icon: Icons.lock_outline,
      onClose: busy && !externalAuthBusy ? null : onClose,
    );
  }

  Widget _content() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _authMethods(),
        _emailForm(),
        if (error != null) _errorMessage(error!),
      ],
    );
  }

  Widget _authMethods() {
    return IgnorePointer(
      ignoring: busy,
      child: Opacity(
        opacity: busy ? 0.62 : 1,
        child: _AuthMethodButtons(
          client: socialAuthClient,
          socialAuthReady: socialAuthReady,
          showNativeGoogle: showNativeGoogle,
          showNativeApple: showNativeApple,
          emailSelected: emailFormExpanded,
          onEmailPressed: onEmailPressed,
          onAuthenticated: onAuthenticated,
          onError: onSocialError,
          onGooglePressed: showExternalGoogle ? onGooglePressed : null,
          onApplePressed: showExternalApple ? onApplePressed : null,
          onSteamPressed: showSteam ? onSteamPressed : null,
        ),
      ),
    );
  }

  Widget _emailForm() {
    return AnimatedSize(
      duration: GameMotion.slide,
      curve: GameMotion.stateChange,
      alignment: Alignment.topCenter,
      child: emailFormExpanded
          ? Padding(
              padding: const EdgeInsets.only(top: 18),
              child: _EmailAccountForm(
                l10n: l10n,
                mode: mode,
                busy: busy,
                nicknameController: nicknameController,
                emailController: emailController,
                passwordController: passwordController,
                onModeChanged: onModeChanged,
                onSubmitted: onSubmitted,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _errorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        key: const Key('multiplayer.account.error'),
        message,
        style: GameUiTheme.bodyStrong.copyWith(color: GameUiTheme.danger),
      ),
    );
  }

  List<GameModalAction> _actions() {
    return [
      GameModalAction(
        label: l10n.selectionActionCancel,
        variant: EpicButtonVariant.text,
        onPressed: busy && !externalAuthBusy ? null : onClose,
      ),
      if (emailFormExpanded)
        GameModalAction(
          key: const Key('multiplayer.account.submit'),
          label: mode == _AccountMode.signIn
              ? l10n.multiplayerAccountSignInAction
              : l10n.multiplayerAccountCreateAction,
          variant: EpicButtonVariant.primary,
          icon: mode == _AccountMode.signIn
              ? Icons.login_rounded
              : Icons.person_add_alt_1_rounded,
          onPressed: busy ? null : onSubmitted,
        ),
    ];
  }
}
