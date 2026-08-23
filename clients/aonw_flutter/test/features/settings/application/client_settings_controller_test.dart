import 'dart:async';

import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, updates and resets client-only preferences', () async {
    final stored = ClientSettings.defaults.copyWith(
      cameraSensitivity: 1.5,
      reducedMotion: true,
    );
    final store = _MemorySettingsStore(stored);
    final controller = ClientSettingsController(store: store);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.settings, stored);

    final changed = stored.copyWith(masterVolume: 0.25, highContrast: true);
    await controller.update(changed);
    expect(controller.settings, changed);
    expect(store.settings, changed);

    await controller.reset();
    expect(controller.settings, ClientSettings.defaults);
    expect(store.settings, ClientSettings.defaults);
  });

  test('a late load never overwrites a newer user edit', () async {
    final load = Completer<ClientSettings>();
    final store = _DelayedSettingsStore(load.future);
    final controller = ClientSettingsController(store: store);
    addTearDown(controller.dispose);

    final pendingLoad = controller.load();
    final changed = ClientSettings.defaults.copyWith(masterVolume: 0.4);
    await controller.update(changed);
    load.complete(ClientSettings.defaults.copyWith(masterVolume: 0.9));
    await pendingLoad;

    expect(controller.settings, changed);
  });
}

final class _MemorySettingsStore implements ClientSettingsStore {
  _MemorySettingsStore(this.settings);

  ClientSettings settings;

  @override
  Future<ClientSettings> load() async => settings;

  @override
  Future<void> save(ClientSettings settings) async {
    this.settings = settings;
  }
}

final class _DelayedSettingsStore implements ClientSettingsStore {
  _DelayedSettingsStore(this.loaded);

  final Future<ClientSettings> loaded;

  @override
  Future<ClientSettings> load() => loaded;

  @override
  Future<void> save(ClientSettings settings) async {}
}
