import 'dart:convert';

import 'package:aonw/game/presentation/providers/hud_minimized_popups_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores minimized popup entries in memory', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const entry = HudMinimizedPopupEntry(
      id: 'popup.1',
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Movement mode',
      subtitle: 'Choose a target hex.',
    );

    container.read(hudMinimizedPopupsProvider.notifier).minimize(entry);

    final state = container.read(hudMinimizedPopupsProvider);
    expect(state.entries, hasLength(1));
    expect(state.hasEntry(entry.id), isTrue);
  });

  test('creates restore requests without removing the entry', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const entry = HudMinimizedPopupEntry(
      id: 'popup.1',
      kind: HudMinimizedPopupKind.firstTurnCoachmarks,
      title: 'Tutorial',
      subtitle: 'First-turn guide',
    );

    container.read(hudMinimizedPopupsProvider.notifier).minimize(entry);
    container
        .read(hudMinimizedPopupsProvider.notifier)
        .requestRestore(entry.id);

    final state = container.read(hudMinimizedPopupsProvider);
    expect(state.entries, hasLength(1));
    expect(state.restoreRequest?.popupId, entry.id);
    expect(state.restoreRequest?.sequence, 1);
  });

  test(
    'creates restore requests for help entries outside minimized storage',
    () {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final entry = HudMinimizedPopupEntry(
        id: HudMinimizedPopupIds.autoTurnHint('save'),
        kind: HudMinimizedPopupKind.autoTurnHint,
        title: 'Auto turn completion',
        subtitle: 'Quick toggle for automatic turn flow.',
      );

      container
          .read(hudMinimizedPopupsProvider.notifier)
          .requestRestoreEntry(entry);

      final state = container.read(hudMinimizedPopupsProvider);
      expect(state.entries, isEmpty);
      expect(state.restoreRequest?.popupId, entry.id);
      expect(state.restoreRequest?.entry, entry);
      expect(state.restoreRequest?.sequence, 1);
    },
  );

  test('filters minimized popup entries by save id', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final currentGameEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner('save_a', 'moveTargeting'),
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Movement mode',
      subtitle: 'Choose a target hex.',
    );
    final otherGameEntry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner('save_b', 'moveTargeting'),
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Movement mode',
      subtitle: 'Choose a target hex.',
    );

    container.read(hudMinimizedPopupsProvider.notifier)
      ..minimize(currentGameEntry)
      ..minimize(otherGameEntry);

    final entries = container
        .read(hudMinimizedPopupsProvider)
        .entriesForSave('save_a');
    expect(entries, [currentGameEntry]);
  });

  test('exposes transient help entries without storing them', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner('save_a', 'researchSelection'),
      kind: HudMinimizedPopupKind.modeBanner,
      title: 'Choose research',
      subtitle: 'Choose research in the bottom toolbar.',
    );

    container.read(hudMinimizedPopupsProvider.notifier).setTransientEntries(
      'activeMode.save_a',
      [entry],
    );

    final state = container.read(hudMinimizedPopupsProvider);
    expect(state.entries, isEmpty);
    expect(state.entriesForSave('save_a'), [entry]);
    expect(state.entriesForSave('save_b'), isEmpty);
  });

  test('persists minimized popup entries', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final entry = HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.firstTurnTutorial('save'),
      kind: HudMinimizedPopupKind.firstTurnCoachmarks,
      title: 'Tutorial',
      subtitle: 'First-turn guide',
      payload: {'stepIndex': '0'},
    );

    container.read(hudMinimizedPopupsProvider.notifier).minimize(entry);
    await _flushAsyncStorage();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(HudMinimizedPopupsController.preferenceKey);
    expect(raw, isNotNull);
    expect(jsonDecode(raw!) as List, hasLength(1));

    final restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);
    await _waitUntilLoaded(restoredContainer);

    final restored = restoredContainer.read(hudMinimizedPopupsProvider);
    expect(restored.entries, hasLength(1));
    expect(restored.entries.single.id, entry.id);
    expect(restored.entries.single.payload['stepIndex'], '0');
  });
}

Future<void> _flushAsyncStorage() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _waitUntilLoaded(ProviderContainer container) async {
  for (var i = 0; i < 5; i++) {
    if (container.read(hudMinimizedPopupsProvider).loaded) return;
    await Future<void>.delayed(Duration.zero);
  }
}
