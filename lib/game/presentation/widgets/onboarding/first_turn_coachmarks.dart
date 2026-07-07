import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/providers/hud/hud_minimized_popups_provider.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_step.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_widgets.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirstTurnCoachmarksOverlay extends ConsumerStatefulWidget {
  const FirstTurnCoachmarksOverlay({
    required this.saveId,
    required this.active,
    required this.enabled,
    required this.hasSelectionActions,
    required this.readyToEndTurn,
    required this.coachmarkContext,
    this.gamepadInputListenable =
        const AlwaysStoppedAnimation<GamepadInputSnapshot>(
          GamepadInputSnapshot.empty,
        ),
    super.key,
  });

  final String saveId;
  final bool active;
  final bool enabled;
  final bool hasSelectionActions;
  final bool readyToEndTurn;
  final FirstTurnCoachmarkContext coachmarkContext;
  final ValueListenable<GamepadInputSnapshot> gamepadInputListenable;

  @override
  ConsumerState<FirstTurnCoachmarksOverlay> createState() =>
      _FirstTurnCoachmarksOverlayState();
}

class _FirstTurnCoachmarksOverlayState
    extends ConsumerState<FirstTurnCoachmarksOverlay> {
  static const _stepIndexPayloadKey = 'stepIndex';
  static const _disabledPayloadKey = 'disabled';
  static const _enabledPayloadValue = 'true';

  var _index = 0;
  var _dismissed = false;
  var _restored = false;
  var _explicitStepNavigation = false;

  String _popupId() {
    return HudMinimizedPopupIds.firstTurnTutorial(widget.saveId);
  }

  void _dismiss() => setState(() {
    _dismissed = true;
    _restored = false;
    _explicitStepNavigation = false;
  });

  void _archiveStep(int stepIndex, {bool disabled = false}) {
    final l10n = context.l10n;
    final payload = <String, String>{_stepIndexPayloadKey: '$stepIndex'};
    if (disabled) payload[_disabledPayloadKey] = _enabledPayloadValue;
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(
          HudMinimizedPopupEntry(
            id: _popupId(),
            kind: HudMinimizedPopupKind.firstTurnCoachmarks,
            title: l10n.firstTurnTutorialPopupTitle,
            subtitle: l10n.firstTurnTutorialPopupSubtitle,
            payload: payload,
          ),
        );
  }

  void _minimize(int stepIndex) {
    _archiveStep(stepIndex);
    _dismiss();
  }

  void _skip(List<CoachmarkStep> steps) {
    _archiveStep(steps.length - 1);
    _dismiss();
  }

  void _disable(List<CoachmarkStep> steps) {
    _archiveStep(steps.length - 1, disabled: true);
    _dismiss();
  }

  void _previous(int stepIndex) {
    if (stepIndex <= 0) return;
    setState(() {
      _index = stepIndex - 1;
      _explicitStepNavigation = true;
    });
  }

  void _next(int stepIndex, List<CoachmarkStep> steps) {
    _archiveStep(stepIndex);
    if (stepIndex >= steps.length - 1) {
      _dismiss();
      return;
    }
    setState(() {
      _index = stepIndex + 1;
      _explicitStepNavigation = true;
    });
  }

  void _handleGamepadNavigate(
    GamepadMapDirection direction,
    int stepIndex,
    List<CoachmarkStep> steps,
  ) {
    if (direction == GamepadMapDirection.up ||
        direction == GamepadMapDirection.left) {
      _previous(stepIndex);
      return;
    }
    _next(stepIndex, steps);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = _steps();
    final minimizedState = ref.watch(hudMinimizedPopupsProvider);
    _listenForRestoreRequests();
    if (steps.isEmpty || !minimizedState.loaded) {
      return const SizedBox.shrink();
    }
    if (!_restored && _tutorialDisabled(minimizedState)) {
      return const SizedBox.shrink();
    }
    if (!_restored && widget.active && widget.enabled && !_dismissed) {
      _restored = true;
    }
    if (!_restored) return const SizedBox.shrink();
    if (!minimizedState.loaded || _dismissed) {
      return const SizedBox.shrink();
    }
    final archived = _archivedStepIndexes(minimizedState);
    final startIndex = _index.clamp(0, steps.length - 1);
    final visibleIndex = _explicitStepNavigation
        ? startIndex
        : _visibleStepIndex(
            startIndex: startIndex,
            total: steps.length,
            archived: archived,
          );
    if (visibleIndex == null) return const SizedBox.shrink();

    final index = visibleIndex;
    final step = steps[index];

    return Positioned.fill(
      child: GamepadPanelInputListener(
        input: widget.gamepadInputListenable,
        priority: GamepadInputRoutePriority.modal,
        onNavigate: (direction) =>
            _handleGamepadNavigate(direction, index, steps),
        onConfirm: () => _next(index, steps),
        onCancel: () => _minimize(index),
        onHudFocusPrevious: () => _previous(index),
        onHudFocusNext: () => _next(index, steps),
        onFocusPrevious: () => _previous(index),
        onFocusNext: () => _next(index, steps),
        child: Semantics(
          label: l10n.firstTurnTutorialSemantics(step.title),
          liveRegion: true,
          child: Stack(
            key: const Key('firstTurnCoachmarks.overlay'),
            children: [
              CoachmarkTargetHalo(anchor: step.anchor),
              CoachmarkBubble(
                step: step,
                current: index + 1,
                total: steps.length,
                onDisable: () => _disable(steps),
                onSkip: () => _skip(steps),
                onNext: () => _next(index, steps),
                onMinimize: () => _minimize(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _listenForRestoreRequests() {
    ref.listen<HudMinimizedPopupsState>(hudMinimizedPopupsProvider, (
      previous,
      next,
    ) {
      final request = next.restoreRequest;
      if (request == null ||
          request.sequence == previous?.restoreRequest?.sequence) {
        return;
      }
      final entry = next.entryFor(request.popupId) ?? request.entry;
      if (entry == null ||
          entry.kind != HudMinimizedPopupKind.firstTurnCoachmarks ||
          !entry.belongsToSave(widget.saveId)) {
        return;
      }
      ref
          .read(hudMinimizedPopupsProvider.notifier)
          .removeWhere(
            (candidate) =>
                candidate.kind == HudMinimizedPopupKind.firstTurnCoachmarks &&
                candidate.belongsToSave(widget.saveId),
          );
      setState(() {
        _dismissed = false;
        _restored = true;
        _explicitStepNavigation = false;
        _index = 0;
      });
    });
  }

  Set<int> _archivedStepIndexes(HudMinimizedPopupsState state) {
    final indexes = <int>{};
    for (final entry in state.entriesForSave(widget.saveId)) {
      if (entry.kind != HudMinimizedPopupKind.firstTurnCoachmarks) continue;
      final stepIndex = int.tryParse(entry.payload[_stepIndexPayloadKey] ?? '');
      if (stepIndex == null) continue;
      for (var index = 0; index <= stepIndex; index++) {
        indexes.add(index);
      }
    }
    return indexes;
  }

  bool _tutorialDisabled(HudMinimizedPopupsState state) {
    for (final entry in state.entries) {
      if (!entry.belongsToSave(widget.saveId)) continue;
      if (entry.kind != HudMinimizedPopupKind.firstTurnCoachmarks) continue;
      if (entry.payload[_disabledPayloadKey] == _enabledPayloadValue) {
        return true;
      }
    }
    return false;
  }

  int? _visibleStepIndex({
    required int startIndex,
    required int total,
    required Set<int> archived,
  }) {
    for (var index = startIndex; index < total; index++) {
      if (!archived.contains(index)) return index;
    }
    return null;
  }

  List<CoachmarkStep> _steps() {
    return FirstTurnCoachmarkSteps.build(
      l10n: context.l10n,
      context: widget.coachmarkContext.copyWith(
        hasSelectionActions: widget.hasSelectionActions,
        readyToEndTurn: widget.readyToEndTurn,
      ),
    );
  }
}
