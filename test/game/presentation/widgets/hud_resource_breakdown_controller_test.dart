import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdown_controller.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggles a resource breakdown type', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    void toggle(TopResourcePopupType type) {
      container
          .read(hudResourceBreakdownControllerProvider.notifier)
          .toggle(type);
    }

    expect(container.read(hudResourceBreakdownControllerProvider), isNull);

    toggle(TopResourcePopupType.gold);
    expect(
      container.read(hudResourceBreakdownControllerProvider),
      TopResourcePopupType.gold,
    );

    toggle(TopResourcePopupType.gold);
    expect(container.read(hudResourceBreakdownControllerProvider), isNull);
  });

  test('switches and closes the active breakdown', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    void toggle(TopResourcePopupType type) {
      container
          .read(hudResourceBreakdownControllerProvider.notifier)
          .toggle(type);
    }

    void close() {
      container.read(hudResourceBreakdownControllerProvider.notifier).close();
    }

    toggle(TopResourcePopupType.gold);
    toggle(TopResourcePopupType.science);
    expect(
      container.read(hudResourceBreakdownControllerProvider),
      TopResourcePopupType.science,
    );

    close();
    expect(container.read(hudResourceBreakdownControllerProvider), isNull);
  });

  test('opens victory as a top resource popup', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(hudResourceBreakdownControllerProvider.notifier)
        .toggle(TopResourcePopupType.victory);

    expect(
      container.read(hudResourceBreakdownControllerProvider),
      TopResourcePopupType.victory,
    );
  });
}
