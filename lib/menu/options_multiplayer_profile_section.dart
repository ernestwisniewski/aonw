import 'dart:async';

import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionsMultiplayerProfileSection extends ConsumerStatefulWidget {
  const OptionsMultiplayerProfileSection({super.key});

  @override
  ConsumerState<OptionsMultiplayerProfileSection> createState() =>
      _OptionsMultiplayerProfileSectionState();
}

class _OptionsMultiplayerProfileSectionState
    extends ConsumerState<OptionsMultiplayerProfileSection> {
  late final TextEditingController _nicknameController;
  bool _loaded = false;
  bool _saving = false;
  bool _signedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    unawaited(_load());
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final activeSession = ref.read(networkSessionProvider);
    final store = ref.read(networkSessionStoreProvider);
    final stored = await store.load();
    final displayName = stored?.displayName ?? await store.loadDisplayName();
    if (!mounted) return;
    setState(() {
      _nicknameController.text = displayName;
      _loaded = true;
      _signedIn = activeSession != null || stored != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = _signedIn || ref.watch(networkSessionProvider) != null;
    return SettingsSection(
      icon: Icons.badge_outlined,
      title: l10n.multiplayerProfileTitle,
      child: _profileForm(l10n, signedIn),
    );
  }

  Widget _profileForm(AppLocalizations l10n, bool signedIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.multiplayerProfileOptionsSubtitle,
          style: GameUiTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('options.multiplayer.nickname'),
          controller: _nicknameController,
          enabled: _loaded && !_saving,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.nickname],
          style: GameUiTheme.inputText,
          decoration: GameUiTheme.textFieldDecoration(
            hintText: l10n.multiplayerNicknameLabel,
          ),
          onSubmitted: (_) {
            if (_loaded && !_saving) unawaited(_save());
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            key: const Key('options.multiplayer.nicknameError'),
            _error!,
            style: GameUiTheme.bodyStrong.copyWith(color: GameUiTheme.danger),
          ),
        ],
        const SizedBox(height: 10),
        _profileActions(l10n, signedIn),
      ],
    );
  }

  Widget _profileActions(AppLocalizations l10n, bool signedIn) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 8,
      children: [
        EpicButton.text(
          key: const Key('options.multiplayer.signOut'),
          label: l10n.multiplayerAccountSignOutAction,
          icon: Icons.logout_rounded,
          onPressed: !_loaded || _saving || !signedIn
              ? null
              : ref.withMenuClickAsync(_signOut),
        ),
        EpicButton.primary(
          key: const Key('options.multiplayer.saveNickname'),
          label: l10n.multiplayerProfileSaveAction,
          icon: Icons.save_outlined,
          onPressed: !_loaded || _saving ? null : ref.withMenuClickAsync(_save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final displayName = _nicknameController.text.trim();
    if (!_validDisplayName(displayName)) {
      setState(() => _error = l10n.multiplayerAccountInvalidNickname);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final session = ref.read(networkSessionProvider);
      final saved = session == null
          ? displayName
          : await ref
                .read(networkSessionClientProvider)
                .updateDisplayName(
                  token: session.token,
                  displayName: displayName,
                );
      await ref.read(networkSessionStoreProvider).saveDisplayName(saved);
      final stored = await ref.read(networkSessionStoreProvider).load();
      if (!mounted) return;
      _nicknameController.text = saved;
      setState(() => _signedIn = session != null || stored != null);
      GameToast.show(
        context,
        message: l10n.multiplayerProfileSaved,
        tone: GameToastTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _profileErrorText(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    if (_saving) return;
    final l10n = context.l10n;
    final client = ref.read(networkSessionClientProvider);
    final coordinator = ref.read(networkSessionRefreshCoordinatorProvider);
    setState(() {
      _saving = true;
      _error = null;
    });
    Object? signOutError;
    try {
      await coordinator.revokeAndTerminate(client.signOutCurrentSession);
    } catch (error) {
      signOutError = error;
    } finally {
      ref.read(networkSessionStateProvider.notifier).set(null);
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _signedIn = false;
      _error = signOutError == null
          ? null
          : l10n.multiplayerAccountGenericError;
    });
    if (signOutError != null) return;
    GameToast.show(
      context,
      message: l10n.multiplayerAccountSignedOut,
      tone: GameToastTone.success,
    );
  }

  String _profileErrorText(AppLocalizations l10n, Object error) {
    if (error is MultiplayerFailure && error.isAuthentication) {
      return switch (error.code) {
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
}
