import 'dart:async';

import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_compatibility_provider.dart';
import 'package:aonw/menu/main_menu_update_notice.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only explicit multiplayer statuses are accepted', () {
    expect(mainMenuUpdateNoticeForStatus('soon'), isA<MainMenuUpdateNotice>());
    expect(mainMenuUpdateNoticeForStatus('current'), isNull);
    expect(
      () => mainMenuUpdateNoticeForStatus('unknown'),
      throwsA(isA<StateError>()),
    );
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

  test('multiplayer access fails closed until compatibility is known', () {
    final pending = Completer<MainMenuUpdateNotice?>();
    final checking = ProviderContainer(
      overrides: [
        mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
        mainMenuUpdateNoticeProvider.overrideWith((_) => pending.future),
      ],
    );
    addTearDown(checking.dispose);

    expect(checking.read(mainMenuMultiplayerAccessAllowedProvider), isFalse);
  });

  test('update-required notice blocks multiplayer access', () async {
    final container = ProviderContainer(
      overrides: [
        mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
        mainMenuUpdateNoticeProvider.overrideWith(
          (_) async => const MainMenuUpdateNotice(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(mainMenuUpdateNoticeProvider.future);

    expect(container.read(mainMenuMultiplayerAccessAllowedProvider), isFalse);
  });

  test('compatible status allows multiplayer access', () async {
    final container = ProviderContainer(
      overrides: [
        mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
        mainMenuUpdateNoticeProvider.overrideWith((_) async => null),
      ],
    );
    addTearDown(container.dispose);

    await container.read(mainMenuUpdateNoticeProvider.future);

    expect(container.read(mainMenuMultiplayerAccessAllowedProvider), isTrue);
  });

  test('compatibility errors keep multiplayer access closed', () async {
    final container = ProviderContainer(
      overrides: [
        mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
        mainMenuUpdateNoticeProvider.overrideWith((_) async {
          throw StateError('status unavailable');
        }),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(mainMenuUpdateNoticeProvider.future),
      throwsA(isA<StateError>()),
    );

    expect(
      container.read(multiplayerAccessStateProvider),
      MultiplayerAccessState.unavailable,
    );
    expect(container.read(mainMenuMultiplayerAccessAllowedProvider), isFalse);
  });

  test('retry recovers a transient compatibility-check failure', () async {
    var attempts = 0;
    final container = ProviderContainer(
      overrides: [
        mainMenuUpdateCheckEnabledProvider.overrideWithValue(true),
        mainMenuUpdateNoticeProvider.overrideWith((_) async {
          attempts++;
          if (attempts == 1) throw StateError('temporary outage');
          return null;
        }),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(mainMenuUpdateNoticeProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(
      container.read(multiplayerAccessStateProvider),
      MultiplayerAccessState.unavailable,
    );

    container.read(multiplayerCompatibilityRetryProvider)();
    await container.read(mainMenuUpdateNoticeProvider.future);

    expect(attempts, 2);
    expect(container.read(mainMenuMultiplayerAccessAllowedProvider), isTrue);
  });

  test('update checks use the platform default when not overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mainMenuUpdateCheckEnabledProvider), isFalse);
  });
}
