import 'dart:async';

import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/providers/accessibility_settings_provider.dart';
import 'package:aonw/shared/providers/ai_settings_provider.dart';
import 'package:aonw/shared/providers/audio_settings_provider.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:aonw/shared/providers/performance_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_app_bar.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      appBar: GameUiAppBar(
        title: GameText.screenTitle(l10n.mainMenuSettings),
        onClose: ref.withMenuBack(() => context.go('/')),
      ),
      body: MenuRouteBackdrop(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GameUiScreenHeader(
              icon: Icons.settings_outlined,
              title: l10n.optionsTitle,
              subtitle: l10n.optionsSubtitle,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MultiplayerProfileSection(),
                  SizedBox(height: 12),
                  _TextScaleSection(),
                  SizedBox(height: 12),
                  _LanguageSection(),
                  SizedBox(height: 12),
                  _AudioSection(),
                  SizedBox(height: 12),
                  _AiSection(),
                  SizedBox(height: 12),
                  _GameplaySection(),
                  SizedBox(height: 12),
                  _PerformanceSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GameUiTheme.bg.withAlpha(232),
      shape: RoundedRectangleBorder(
        borderRadius: GameUiTheme.borderRadius,
        side: BorderSide(color: GameUiTheme.gold.withAlpha(86)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: GameUiTheme.gold),
                const SizedBox(width: 8),
                Text(
                  GameText.sectionLabel(title),
                  style: GameUiTheme.sectionHeader.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _MultiplayerProfileSection extends ConsumerStatefulWidget {
  const _MultiplayerProfileSection();

  @override
  ConsumerState<_MultiplayerProfileSection> createState() =>
      _MultiplayerProfileSectionState();
}

class _MultiplayerProfileSectionState
    extends ConsumerState<_MultiplayerProfileSection> {
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
    return _SettingsSection(
      icon: Icons.badge_outlined,
      title: l10n.multiplayerProfileTitle,
      child: Column(
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
          Wrap(
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
                onPressed: !_loaded || _saving
                    ? null
                    : ref.withMenuClickAsync(_save),
              ),
            ],
          ),
        ],
      ),
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
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(networkSessionStoreProvider).clear();
    ref.read(networkSessionStateProvider.notifier).set(null);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _signedIn = false;
    });
    GameToast.show(
      context,
      message: context.l10n.multiplayerAccountSignedOut,
      tone: GameToastTone.success,
    );
  }

  String _profileErrorText(AppLocalizations l10n, Object error) {
    if (error is sp.AccountAuthException) {
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

class _TextScaleSection extends ConsumerWidget {
  const _TextScaleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(accessibilitySettingsProvider);
    final controller = ref.read(accessibilitySettingsProvider.notifier);

    return _SettingsSection(
      icon: Icons.visibility_outlined,
      title: l10n.mainMenuTextSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final scale in GameTextScale.values)
                _TextScaleChoice(
                  scale: scale,
                  label: _textScaleLabel(l10n, scale),
                  selected: settings.textScale == scale,
                  onTap: ref.withMenuClick(
                    () => controller.setTextScale(scale),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.mainMenuTextSample,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.body.copyWith(
              color: GameUiTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextScaleChoice extends StatelessWidget {
  const _TextScaleChoice({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GameTextScale scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.textScaleSemanticLabel(label),
      child: Tooltip(
        message: l10n.textScaleTooltip(label),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            constraints: const BoxConstraints(minHeight: 38, minWidth: 76),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? GameUiTheme.gold.withAlpha(34)
                  : GameUiTheme.surface.withAlpha(190),
              borderRadius: GameUiTheme.borderRadius,
              border: Border.all(
                color: selected
                    ? GameUiTheme.gold
                    : GameUiTheme.gold.withAlpha(70),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.bodyStrong.copyWith(
                    color: selected
                        ? GameUiTheme.goldLight
                        : GameUiTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(scale.factor * 100).round()}%',
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: selected
                        ? GameUiTheme.gold
                        : GameUiTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _textScaleLabel(AppLocalizations l10n, GameTextScale scale) {
  return switch (scale) {
    GameTextScale.standard => l10n.textScaleStandard,
    GameTextScale.large => l10n.textScaleLarge,
    GameTextScale.extraLarge => l10n.textScaleExtraLarge,
  };
}

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(languageSettingsProvider);
    final controller = ref.read(languageSettingsProvider.notifier);
    final languages = _sortedLanguages(l10n);
    final selectedLanguage =
        settings.selectedLanguage ??
        GameLanguage.fromLocale(Localizations.localeOf(context)) ??
        GameLanguage.english;
    return _SettingsSection(
      icon: Icons.language_outlined,
      title: l10n.languageSectionTitle,
      child: Tooltip(
        message: l10n.languageTooltip(_languageLabel(l10n, selectedLanguage)),
        child: DropdownButtonFormField<GameLanguage>(
          key: ValueKey('options.language.${selectedLanguage.storageValue}'),
          initialValue: selectedLanguage,
          isExpanded: true,
          dropdownColor: GameUiTheme.surface,
          iconEnabledColor: GameUiTheme.goldLight,
          style: GameUiTheme.inputText,
          decoration: GameUiTheme.textFieldDecoration(
            hintText: l10n.languageSectionTitle,
          ),
          selectedItemBuilder: (context) => [
            for (final language in languages)
              Align(
                alignment: Alignment.centerLeft,
                child: _LanguageDropdownLabel(
                  language: language,
                  selected: language == selectedLanguage,
                ),
              ),
          ],
          items: [
            for (final language in languages)
              DropdownMenuItem(
                value: language,
                child: _LanguageDropdownLabel(
                  language: language,
                  selected: language == selectedLanguage,
                ),
              ),
          ],
          onChanged: (language) {
            if (language == null || language == selectedLanguage) return;
            ref.playMenuClick();
            controller.setLanguage(language);
          },
        ),
      ),
    );
  }
}

class _LanguageDropdownLabel extends StatelessWidget {
  const _LanguageDropdownLabel({
    required this.language,
    required this.selected,
  });

  final GameLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            _languageCode(language),
            style: GameUiTheme.toolbarLabel.copyWith(
              color: selected ? GameUiTheme.gold : GameUiTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _languageLabel(l10n, language),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.inputText.copyWith(
              color: selected ? GameUiTheme.goldLight : GameUiTheme.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          selected ? Icons.check_rounded : Icons.check_box_outline_blank,
          size: 17,
          color: selected ? GameUiTheme.success : GameUiTheme.textTertiary,
        ),
      ],
    );
  }
}

List<GameLanguage> _sortedLanguages(AppLocalizations l10n) {
  return GameLanguage.values.toList()..sort((left, right) {
    final byName = _languageLabel(
      l10n,
      left,
    ).toLowerCase().compareTo(_languageLabel(l10n, right).toLowerCase());
    if (byName != 0) return byName;
    return left.storageValue.compareTo(right.storageValue);
  });
}

String _languageLabel(AppLocalizations l10n, GameLanguage language) {
  return switch (language) {
    GameLanguage.polish => l10n.languagePolish,
    GameLanguage.english => l10n.languageEnglish,
    GameLanguage.german => l10n.languageGerman,
    GameLanguage.spanish => l10n.languageSpanish,
    GameLanguage.dutch => l10n.languageDutch,
  };
}

String _languageCode(GameLanguage language) {
  return switch (language) {
    GameLanguage.polish => 'PL',
    GameLanguage.english => 'EN',
    GameLanguage.german => 'DE',
    GameLanguage.spanish => 'ES',
    GameLanguage.dutch => 'NL',
  };
}

class _AudioSection extends ConsumerWidget {
  const _AudioSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(gameAudioSettingsProvider);
    final controller = ref.read(gameAudioSettingsProvider.notifier);
    return _SettingsSection(
      icon: Icons.volume_up_outlined,
      title: l10n.audioSectionTitle,
      child: Column(
        children: [
          _SettingsToggleRow(
            icon: Icons.graphic_eq_rounded,
            label: l10n.gameSoundsLabel,
            value: settings.soundsEnabled,
            onChanged: ref.withMenuClickValue(controller.setSoundsEnabled),
          ),
          if (settings.soundsEnabled)
            _VolumeSlider(
              key: const Key('options.soundVolume'),
              label: l10n.soundVolumeLabel,
              value: settings.soundVolume,
              onChanged: controller.setSoundVolume,
            ),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            icon: Icons.music_note_outlined,
            label: l10n.gameMusicLabel,
            value: settings.musicEnabled,
            onChanged: ref.withMenuClickValue(controller.setMusicEnabled),
          ),
          if (settings.musicEnabled)
            _VolumeSlider(
              key: const Key('options.musicVolume'),
              label: l10n.musicVolumeLabel,
              value: settings.musicVolume,
              onChanged: controller.setMusicVolume,
            ),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            icon: Icons.forest_outlined,
            label: l10n.natureSoundsLabel,
            value: settings.natureEnabled,
            onChanged: ref.withMenuClickValue(controller.setNatureEnabled),
          ),
          if (settings.natureEnabled)
            _VolumeSlider(
              key: const Key('options.natureVolume'),
              label: l10n.natureVolumeLabel,
              value: settings.natureVolume,
              onChanged: controller.setNatureVolume,
            ),
        ],
      ),
    );
  }
}

class _AiSection extends ConsumerWidget {
  const _AiSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(aiSettingsProvider);
    final controller = ref.read(aiSettingsProvider.notifier);
    return _SettingsSection(
      icon: Icons.memory_outlined,
      title: l10n.aiSectionTitle,
      child: _SettingsToggleRow(
        key: const Key('options.aiBatterySaver'),
        icon: Icons.battery_saver_outlined,
        label: l10n.aiBatterySaverLabel,
        value: settings.batterySaver,
        onChanged: ref.withMenuClickValue(controller.setBatterySaver),
      ),
    );
  }
}

class _GameplaySection extends ConsumerWidget {
  const _GameplaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(gameplaySettingsProvider);
    final controller = ref.read(gameplaySettingsProvider.notifier);
    return _SettingsSection(
      icon: Icons.videocam_outlined,
      title: l10n.gameplaySectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsToggleRow(
            key: const Key('options.followUnitMovementCamera'),
            icon: Icons.center_focus_strong_outlined,
            label: l10n.followUnitMovementCameraLabel,
            value: settings.followUnitMovementCamera,
            onChanged: ref.withMenuClickValue(
              controller.setFollowUnitMovementCamera,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            key: const Key('options.followEnemyUnitCamera'),
            icon: Icons.crisis_alert_outlined,
            label: l10n.followEnemyUnitCameraLabel,
            value: settings.followEnemyUnitCamera,
            onChanged: ref.withMenuClickValue(
              controller.setFollowEnemyUnitCamera,
            ),
          ),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            key: const Key('options.cinematicCamera'),
            icon: Icons.movie_filter_outlined,
            label: l10n.cinematicCameraLabel,
            value: settings.cinematicCameraEnabled,
            onChanged: ref.withMenuClickValue(
              controller.setCinematicCameraEnabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSection extends ConsumerWidget {
  const _PerformanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(performanceSettingsProvider);
    final controller = ref.read(performanceSettingsProvider.notifier);
    return _SettingsSection(
      icon: Icons.speed_outlined,
      title: l10n.performanceSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsToggleRow(
            key: const Key('options.showFps'),
            icon: Icons.monitor_heart_outlined,
            label: l10n.showFpsLabel,
            value: settings.showFps,
            onChanged: ref.withMenuClickValue(controller.setShowFps),
          ),
          const SizedBox(height: 8),
          _SettingsToggleRow(
            key: const Key('options.showMapZoom'),
            icon: Icons.zoom_in_map_outlined,
            label: l10n.showMapZoomLabel,
            value: settings.showMapZoom,
            onChanged: ref.withMenuClickValue(controller.setShowMapZoom),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      secondary: Icon(icon, color: GameUiTheme.gold, size: 20),
      activeThumbColor: GameUiTheme.goldLight,
      activeTrackColor: GameUiTheme.gold.withAlpha(90),
      inactiveThumbColor: GameUiTheme.textSecondary,
      inactiveTrackColor: GameUiTheme.surface.withAlpha(210),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.bodyStrong.copyWith(
          color: value ? GameUiTheme.goldLight : GameUiTheme.textPrimary,
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(46, 0, 2, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.gold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: GameUiTheme.gold,
              inactiveTrackColor: GameUiTheme.gold.withAlpha(48),
              thumbColor: GameUiTheme.goldLight,
              overlayColor: GameUiTheme.gold.withAlpha(38),
              valueIndicatorColor: GameUiTheme.surface,
              valueIndicatorTextStyle: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.goldLight,
              ),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 20,
              label: '${(value * 100).round()}%',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
