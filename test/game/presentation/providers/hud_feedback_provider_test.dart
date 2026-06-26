import 'package:aonw/game/presentation/providers/hud/hud_feedback_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('show stores the latest HUD feedback message', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(hudFeedbackProvider.notifier)
        .show(HudFeedbackMessages.autoExploreNoTarget);
    final first = container.read(hudFeedbackProvider).single;

    expect(first.kind, HudFeedbackKind.autoExploreNoTarget);
    expect(first.title, isEmpty);

    container
        .read(hudFeedbackProvider.notifier)
        .show(HudFeedbackMessages.autoExploreNoTarget);
    final second = container.read(hudFeedbackProvider).single;

    expect(second.kind, HudFeedbackKind.autoExploreNoTarget);
    expect(second.id, isNot(first.id));
  });

  test('dismiss and clear remove HUD feedback messages', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(hudFeedbackProvider.notifier)
        .show(HudFeedbackMessages.autoExploreNoTarget);
    final message = container.read(hudFeedbackProvider).single;

    container.read(hudFeedbackProvider.notifier).dismiss(message.id);

    expect(container.read(hudFeedbackProvider), isEmpty);

    container
        .read(hudFeedbackProvider.notifier)
        .show(HudFeedbackMessages.autoExploreNoTarget);
    container.read(hudFeedbackProvider.notifier).clear();

    expect(container.read(hudFeedbackProvider), isEmpty);
  });
}
