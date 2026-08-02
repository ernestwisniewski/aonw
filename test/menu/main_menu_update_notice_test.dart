import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unsupported multiplayer status activates the translated notice', () {
    expect(mainMenuUpdateNoticeForStatus('soon'), isA<MainMenuUpdateNotice>());
    expect(mainMenuUpdateNoticeForStatus('current'), isNull);
    expect(mainMenuUpdateNoticeForStatus('unknown'), isNull);
  });

  test(
    'provider resolves status through injected release boundaries',
    () async {
      String? requestedPlatform;
      int? requestedBuildNumber;
      int? requestedMultiplayerVersion;
      final container = ProviderContainer(
        overrides: [
          mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
          appReleaseInfoProvider.overrideWith(
            (_) async =>
                const AppReleaseInfo(version: '1.2.3', buildNumber: '42'),
          ),
          mainMenuVersionStatusLoaderProvider.overrideWithValue(({
            required platform,
            required buildNumber,
            required multiplayerVersion,
          }) async {
            requestedPlatform = platform;
            requestedBuildNumber = buildNumber;
            requestedMultiplayerVersion = multiplayerVersion;
            return 'soon';
          }),
        ],
      );
      addTearDown(container.dispose);

      final notice = await container.read(mainMenuUpdateNoticeProvider.future);

      expect(notice, isA<MainMenuUpdateNotice>());
      expect(requestedPlatform, isNotEmpty);
      expect(requestedBuildNumber, 42);
      expect(requestedMultiplayerVersion, kCurrentMultiplayerVersion);
    },
  );

  test('default version loader is composed from the network client', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(mainMenuVersionStatusLoaderProvider),
      isA<MainMenuVersionStatusLoader>(),
    );
  });

  test('update checks use the platform default when not overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mainMenuUpdateCheckEnabledProvider), isFalse);
  });
}
