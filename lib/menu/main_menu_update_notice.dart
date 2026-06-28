import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _appUpdateCheckTimeout = Duration(seconds: 3);

@immutable
class MainMenuUpdateNotice {
  const MainMenuUpdateNotice();
}

final mainMenuUpdateNoticeProvider = FutureProvider<MainMenuUpdateNotice?>((
  ref,
) async {
  if (!_appUpdateCheckEnabled) return null;

  try {
    final releaseInfo = await ref.watch(appReleaseInfoProvider.future);
    final status = await ref
        .watch(networkSessionClientProvider)
        .versionStatus(
          platform: resolveAppReleasePlatform(),
          buildNumber: releaseInfo.buildNumberValue,
        )
        .timeout(_appUpdateCheckTimeout);
    return _noticeFor(status);
  } catch (_) {
    return null;
  }
});

extension MainMenuUpdateNoticeText on MainMenuUpdateNotice {
  String title(AppLocalizations l10n) {
    return l10n.mainMenuUpdateSoonTitle;
  }

  String body(AppLocalizations l10n) {
    return l10n.mainMenuUpdateSoonBody;
  }
}

bool get _appUpdateCheckEnabled {
  const hasOverride = bool.hasEnvironment('AONW_ENABLE_UPDATE_CHECK');
  const override = bool.fromEnvironment('AONW_ENABLE_UPDATE_CHECK');
  return hasOverride ? override : kReleaseMode;
}

MainMenuUpdateNotice? _noticeFor(String status) {
  return switch (status) {
    'soon' => const MainMenuUpdateNotice(),
    _ => null,
  };
}
