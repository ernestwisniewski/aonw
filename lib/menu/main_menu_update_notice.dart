import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_compatibility_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

typedef MainMenuUpdateNotice = MultiplayerUpdateNotice;
typedef MainMenuVersionStatusLoader = MultiplayerVersionStatusLoader;

final mainMenuUpdateCheckEnabledProvider =
    multiplayerUpdateCheckEnabledProvider;
final mainMenuVersionStatusLoaderProvider =
    multiplayerVersionStatusLoaderProvider;
final mainMenuUpdateNoticeProvider = multiplayerUpdateNoticeProvider;
final mainMenuMultiplayerAccessAllowedProvider =
    multiplayerAccessAllowedProvider;

extension MainMenuUpdateNoticeText on MainMenuUpdateNotice {
  String title(AppLocalizations l10n) {
    return l10n.mainMenuUpdateSoonTitle;
  }

  String body(AppLocalizations l10n) {
    return l10n.mainMenuUpdateSoonBody;
  }
}

MainMenuUpdateNotice? mainMenuUpdateNoticeForStatus(String status) {
  return multiplayerUpdateNoticeForStatus(status);
}
