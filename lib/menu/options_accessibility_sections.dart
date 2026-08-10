import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_click_sound.dart';
import 'package:aonw/menu/menu_gamepad_input.dart';
import 'package:aonw/menu/widgets/settings_controls.dart';
import 'package:aonw/shared/providers/accessibility_settings_provider.dart';
import 'package:aonw/shared/providers/language_settings_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OptionsTextScaleSection extends ConsumerWidget {
  const OptionsTextScaleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(accessibilitySettingsProvider);
    final controller = ref.read(accessibilitySettingsProvider.notifier);

    return SettingsSection(
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
    return MenuGamepadAction(
      onActivate: onTap,
      borderRadius: GameUiTheme.borderRadius,
      builder: (context, focused) {
        final highlighted = selected || focused;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: highlighted
                      ? GameUiTheme.gold.withAlpha(34)
                      : GameUiTheme.surface.withAlpha(190),
                  borderRadius: GameUiTheme.borderRadius,
                  border: Border.all(
                    color: highlighted
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
                        color: highlighted
                            ? GameUiTheme.goldLight
                            : GameUiTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(scale.factor * 100).round()}%',
                      style: GameUiTheme.toolbarLabel.copyWith(
                        color: highlighted
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
      },
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

class OptionsLanguageSection extends ConsumerWidget {
  const OptionsLanguageSection({super.key});

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
    return SettingsSection(
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
    GameLanguage.french => l10n.languageFrench,
    GameLanguage.german => l10n.languageGerman,
    GameLanguage.spanish => l10n.languageSpanish,
    GameLanguage.dutch => l10n.languageDutch,
  };
}

String _languageCode(GameLanguage language) {
  return switch (language) {
    GameLanguage.polish => 'PL',
    GameLanguage.english => 'EN',
    GameLanguage.french => 'FR',
    GameLanguage.german => 'DE',
    GameLanguage.spanish => 'ES',
    GameLanguage.dutch => 'NL',
  };
}
