part of 'hud_gamepad_focus_controller.dart';

class HudGamepadFocusTargetRegistry
    extends Notifier<Map<String, List<HudGamepadFocusTarget>>> {
  @override
  Map<String, List<HudGamepadFocusTarget>> build() => const {};

  static List<HudGamepadFocusTarget> flatten(
    Map<String, List<HudGamepadFocusTarget>> sources,
  ) {
    return [
      for (final targets in sources.values)
        for (final target in targets) target,
    ];
  }

  void setSource(String sourceId, List<HudGamepadFocusTarget> targets) {
    final existing = state[sourceId] ?? const <HudGamepadFocusTarget>[];
    if (_sameTargets(existing, targets)) return;
    final next = {...state};
    if (targets.isEmpty) {
      next.remove(sourceId);
    } else {
      next[sourceId] = List.unmodifiable(targets);
    }
    state = Map.unmodifiable(next);
  }

  void clearSource(String sourceId) {
    if (!state.containsKey(sourceId)) return;
    state = Map.unmodifiable({...state}..remove(sourceId));
  }

  bool _sameTargets(
    List<HudGamepadFocusTarget> left,
    List<HudGamepadFocusTarget> right,
  ) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i += 1) {
      final leftTarget = left[i];
      final rightTarget = right[i];
      if (leftTarget.section != rightTarget.section ||
          leftTarget.id != rightTarget.id ||
          leftTarget.label != rightTarget.label ||
          leftTarget.enabled != rightTarget.enabled ||
          leftTarget.activationKey != rightTarget.activationKey) {
        return false;
      }
    }
    return true;
  }
}
