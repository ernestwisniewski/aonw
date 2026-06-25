import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps height badges hidden by default and toggles them explicitly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(hexDisplayProvider.notifier);
    expect(container.read(hexDisplayProvider).showHeightBadge, isFalse);

    notifier.toggleHeightBadge();
    expect(container.read(hexDisplayProvider).showHeightBadge, isTrue);
  });

  test('toggles city planning overlays independently', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(hexDisplayProvider.notifier);
    expect(container.read(hexDisplayProvider).showCitySites, isFalse);
    expect(container.read(hexDisplayProvider).showCityGrowth, isFalse);

    notifier.toggleCitySites();
    expect(container.read(hexDisplayProvider).showCitySites, isTrue);
    expect(container.read(hexDisplayProvider).showCityGrowth, isFalse);

    notifier.toggleCityGrowth();
    expect(container.read(hexDisplayProvider).showCitySites, isTrue);
    expect(container.read(hexDisplayProvider).showCityGrowth, isTrue);
  });

  test('loads standard map colors from preferences', () async {
    SharedPreferences.setMockInitialValues({
      HexDisplayPreferenceKeys.defaultHexBorderColor: 0xFF102030,
      HexDisplayPreferenceKeys.defaultWallTintColor: 0xFF405060,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(hexDisplayDefaultsBootstrapProvider.future);

    final settings = container.read(hexDisplayProvider);
    expect(settings.hexBorderColor, const Color(0xFF102030));
    expect(settings.wallTintColor, const Color(0xFF405060));
  });

  test('loads map colors over standard defaults', () async {
    const selection = MapSelection(name: 'duel_map', source: MapSource.asset);
    SharedPreferences.setMockInitialValues({
      HexDisplayPreferenceKeys.defaultHexBorderColor: 0xFF102030,
      HexDisplayPreferenceKeys.defaultWallTintColor: 0xFF405060,
      HexDisplayPreferenceKeys.hexBorderColorForMap(selection): 0xFF708090,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(hexDisplayMapBootstrapProvider(selection).future);

    final settings = container.read(hexDisplayProvider);
    expect(settings.hexBorderColor, const Color(0xFF708090));
    expect(settings.wallTintColor, const Color(0xFF405060));
  });

  test('resetting a map color restores the standard color', () async {
    const selection = MapSelection(name: 'duel_map', source: MapSource.saved);
    final mapKey = HexDisplayPreferenceKeys.wallTintColorForMap(selection);
    SharedPreferences.setMockInitialValues({
      HexDisplayPreferenceKeys.defaultWallTintColor: 0xFF405060,
      mapKey: 0xFF708090,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(hexDisplayMapBootstrapProvider(selection).future);
    expect(
      container.read(hexDisplayProvider).wallTintColor,
      const Color(0xFF708090),
    );

    await container
        .read(hexDisplayProvider.notifier)
        .resetWallTintColorForMap(selection);

    final prefs = await SharedPreferences.getInstance();
    expect(
      container.read(hexDisplayProvider).wallTintColor,
      const Color(0xFF405060),
    );
    expect(prefs.containsKey(mapKey), isFalse);
  });

  test(
    'map hex toggle sets border opacity without changing wall tint',
    () async {
      const selection = MapSelection(name: 'duel_map', source: MapSource.asset);
      final borderKey = HexDisplayPreferenceKeys.hexBorderColorForMap(
        selection,
      );
      final wallKey = HexDisplayPreferenceKeys.wallTintColorForMap(selection);
      SharedPreferences.setMockInitialValues({wallKey: 0x80405060});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(hexDisplayMapBootstrapProvider(selection).future);
      await container
          .read(hexDisplayProvider.notifier)
          .setHexBordersVisibleForMap(selection, true);

      final settings = container.read(hexDisplayProvider);
      final prefs = await SharedPreferences.getInstance();
      expect(settings.hexBordersVisible, isTrue);
      expect(settings.hexBorderColor, const Color(0xFF000000));
      expect(settings.wallTintColor, const Color(0x80405060));
      expect(prefs.getInt(borderKey), settings.hexBorderColor.toARGB32());
      expect(prefs.getInt(wallKey), 0x80405060);

      await container
          .read(hexDisplayProvider.notifier)
          .setHexBordersVisibleForMap(selection, false);

      expect(container.read(hexDisplayProvider).hexBordersVisible, isFalse);
      expect(prefs.getInt(borderKey), 0x00000000);
    },
  );

  test(
    'height wall toggle sets wall opacity without changing borders',
    () async {
      const selection = MapSelection(name: 'duel_map', source: MapSource.asset);
      final borderKey = HexDisplayPreferenceKeys.hexBorderColorForMap(
        selection,
      );
      final wallKey = HexDisplayPreferenceKeys.wallTintColorForMap(selection);
      SharedPreferences.setMockInitialValues({borderKey: 0x80102030});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(hexDisplayMapBootstrapProvider(selection).future);
      await container
          .read(hexDisplayProvider.notifier)
          .setHeightWallsVisibleForMap(selection, true);

      final settings = container.read(hexDisplayProvider);
      final prefs = await SharedPreferences.getInstance();
      expect(settings.heightWallsVisible, isTrue);
      expect((settings.wallTintColor.toARGB32() >> 24) & 0xFF, 0xFF);
      expect(settings.hexBorderColor, const Color(0x80102030));
      expect(prefs.getInt(wallKey), settings.wallTintColor.toARGB32());
      expect(prefs.getInt(borderKey), 0x80102030);

      await container
          .read(hexDisplayProvider.notifier)
          .setHeightWallsVisibleForMap(selection, false);

      expect(container.read(hexDisplayProvider).heightWallsVisible, isFalse);
      expect(prefs.getInt(wallKey), 0x00000000);
    },
  );
}
