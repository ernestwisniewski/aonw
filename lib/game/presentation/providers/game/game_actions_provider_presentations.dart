part of 'game_actions_provider.dart';

HudFeedbackContent? _artifactGuidanceContent(
  _CommandDispatchRecord record, {
  required LanguageSettings languageSettings,
}) {
  final previousState = record.previousState;
  if (previousState == null) return null;
  final locale =
      languageSettings.locale ??
      resolveGameLocale(
        ui.PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
  return ArtifactGuidanceResolver(l10n: lookupAppLocalizations(locale)).resolve(
    previousState: previousState,
    state: record.result.state,
    events: record.result.events,
  );
}

class _CommandDispatchRecord {
  final GameCommand command;
  final GameState? previousState;
  final DispatchCommandResult result;

  const _CommandDispatchRecord({
    required this.command,
    required this.previousState,
    required this.result,
  });
}
