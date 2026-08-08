import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hudFeedbackProvider =
    NotifierProvider<HudFeedbackNotifier, List<HudFeedbackMessage>>(
      HudFeedbackNotifier.new,
    );

enum HudFeedbackKind {
  autoExploreNoTarget,
  workerAutomationNoTarget,
  artifactGuidance,
  actionBlocked,
}

class HudFeedbackContent {
  final HudFeedbackKind kind;
  final HudFeedbackReason? reason;
  final String title;
  final String body;

  const HudFeedbackContent({
    required this.kind,
    this.reason,
    required this.title,
    required this.body,
  });

  factory HudFeedbackContent.fromEffect(ShowHudFeedbackEffect effect) {
    return switch (effect) {
      ShowWorkerAutomationNoTargetEffect() =>
        HudFeedbackMessages.workerAutomationNoTarget,
      _ => HudFeedbackContent(
        kind: HudFeedbackKind.actionBlocked,
        reason: effect.reason,
        title: effect.title,
        body: effect.body,
      ),
    };
  }
}

class HudFeedbackMessage {
  final int id;
  final HudFeedbackKind kind;
  final HudFeedbackReason? reason;
  final String title;
  final String body;

  const HudFeedbackMessage({
    required this.id,
    required this.kind,
    this.reason,
    required this.title,
    required this.body,
  });
}

abstract final class HudFeedbackMessages {
  static const autoExploreNoTarget = HudFeedbackContent(
    kind: HudFeedbackKind.autoExploreNoTarget,
    title: '',
    body: '',
  );

  static const workerAutomationNoTarget = HudFeedbackContent(
    kind: HudFeedbackKind.workerAutomationNoTarget,
    title: '',
    body: '',
  );
}

class HudFeedbackNotifier extends Notifier<List<HudFeedbackMessage>> {
  int _nextId = 0;

  @override
  List<HudFeedbackMessage> build() => const [];

  void show(HudFeedbackContent content) {
    state = [
      HudFeedbackMessage(
        id: _nextId++,
        kind: content.kind,
        reason: content.reason,
        title: content.title,
        body: content.body,
      ),
    ];
  }

  void dismiss(int id) {
    state = [
      for (final message in state)
        if (message.id != id) message,
    ];
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
  }
}
