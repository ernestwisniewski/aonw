import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HudGamepadFocusSection {
  menu,
  globalActions,
  topResources,
  rightPlayers,
  selectionActions,
}

abstract final class HudGamepadFocusTargetIds {
  static const menuReturn = 'menu.return';
  static const playerStatusSheet = 'players.statusSheet';
  static const bottomCommand = 'bottom.command';
  static const resourceGold = 'resource.gold';
  static const resourceScience = 'resource.science';
  static const resourceStability = 'resource.stability';
  static const resourceResources = 'resource.resources';
  static const resourceTurn = 'resource.turn';
  static const resourceVictory = 'resource.victory';

  static String globalAction(String actionId) => 'global.$actionId';

  static String playerAvatar(String playerId) => 'players.$playerId';

  static String selectionAction(String actionId) => 'selection.$actionId';
}

final class HudGamepadFocusTarget {
  const HudGamepadFocusTarget({
    required this.section,
    required this.id,
    required this.label,
    required this.onActivate,
    this.enabled = true,
  });

  final HudGamepadFocusSection section;
  final String id;
  final String label;
  final VoidCallback onActivate;
  final bool enabled;
}

final class HudGamepadFocusState {
  const HudGamepadFocusState({
    required this.active,
    required this.section,
    required this.targetId,
  });

  static const inactive = HudGamepadFocusState(
    active: false,
    section: HudGamepadFocusSection.topResources,
    targetId: null,
  );

  final bool active;
  final HudGamepadFocusSection section;
  final String? targetId;
}

class HudGamepadFocusController extends Notifier<HudGamepadFocusState> {
  static const _sectionOrder = [
    HudGamepadFocusSection.menu,
    HudGamepadFocusSection.globalActions,
    HudGamepadFocusSection.topResources,
    HudGamepadFocusSection.rightPlayers,
    HudGamepadFocusSection.selectionActions,
  ];

  @override
  HudGamepadFocusState build() => HudGamepadFocusState.inactive;

  HudGamepadFocusTarget? focusedTarget(List<HudGamepadFocusTarget> targets) {
    if (!state.active) return null;
    return _targetForState(_availableTargets(targets));
  }

  void syncTargets(
    List<HudGamepadFocusTarget> targets, {
    required bool enabled,
  }) {
    final available = _availableTargets(targets);
    if (!enabled || available.isEmpty) {
      if (state.active) state = HudGamepadFocusState.inactive;
      return;
    }
    if (!state.active || _targetForState(available) != null) return;
    _activateFirst(available, preferredSection: state.section);
  }

  void toggle(List<HudGamepadFocusTarget> targets) {
    if (state.active) {
      deactivate();
      return;
    }
    _activateFirst(_availableTargets(targets));
  }

  void deactivate() {
    if (!state.active) return;
    state = HudGamepadFocusState.inactive;
  }

  void move(
    GamepadMapDirection direction,
    List<HudGamepadFocusTarget> targets,
  ) {
    if (!state.active) return;
    final available = _availableTargets(targets);
    if (available.isEmpty) {
      state = HudGamepadFocusState.inactive;
      return;
    }
    final focused = _targetForState(available);
    if (focused == null) {
      _activateFirst(available, preferredSection: state.section);
      return;
    }
    if (_directionMovesWithinSection(direction, focused.section)) {
      _moveWithinSection(
        available,
        focused.section,
        _directionDelta(direction),
      );
      return;
    }
    _moveSection(available, _directionDelta(direction));
  }

  void previousSection(List<HudGamepadFocusTarget> targets) {
    if (!state.active) return;
    _moveSection(_availableTargets(targets), -1);
  }

  void nextSection(List<HudGamepadFocusTarget> targets) {
    if (!state.active) return;
    _moveSection(_availableTargets(targets), 1);
  }

  void activateFocused(List<HudGamepadFocusTarget> targets) {
    if (!state.active) return;
    _targetForState(_availableTargets(targets))?.onActivate();
  }

  List<HudGamepadFocusTarget> _availableTargets(
    List<HudGamepadFocusTarget> targets,
  ) {
    return [
      for (final target in targets)
        if (target.enabled) target,
    ];
  }

  HudGamepadFocusTarget? _targetForState(List<HudGamepadFocusTarget> targets) {
    final targetId = state.targetId;
    if (targetId != null) {
      for (final target in targets) {
        if (target.id == targetId) return target;
      }
    }
    for (final target in targets) {
      if (target.section == state.section) return target;
    }
    return null;
  }

  void _activateFirst(
    List<HudGamepadFocusTarget> targets, {
    HudGamepadFocusSection? preferredSection,
  }) {
    if (targets.isEmpty) {
      state = HudGamepadFocusState.inactive;
      return;
    }
    final target =
        _firstTargetInSection(targets, preferredSection) ??
        _firstTargetInOrderedSection(targets) ??
        targets.first;
    state = HudGamepadFocusState(
      active: true,
      section: target.section,
      targetId: target.id,
    );
  }

  HudGamepadFocusTarget? _firstTargetInOrderedSection(
    List<HudGamepadFocusTarget> targets,
  ) {
    for (final section in _sectionOrder) {
      final target = _firstTargetInSection(targets, section);
      if (target != null) return target;
    }
    return null;
  }

  HudGamepadFocusTarget? _firstTargetInSection(
    List<HudGamepadFocusTarget> targets,
    HudGamepadFocusSection? section,
  ) {
    if (section == null) return null;
    for (final target in targets) {
      if (target.section == section) return target;
    }
    return null;
  }

  void _moveWithinSection(
    List<HudGamepadFocusTarget> targets,
    HudGamepadFocusSection section,
    int delta,
  ) {
    final sectionTargets = [
      for (final target in targets)
        if (target.section == section) target,
    ];
    if (sectionTargets.isEmpty) {
      _moveSection(targets, delta);
      return;
    }
    final currentIndex = sectionTargets.indexWhere(
      (target) => target.id == state.targetId,
    );
    final startIndex = currentIndex == -1 ? 0 : currentIndex;
    final nextIndex = (startIndex + delta) % sectionTargets.length;
    final target =
        sectionTargets[nextIndex < 0
            ? nextIndex + sectionTargets.length
            : nextIndex];
    state = HudGamepadFocusState(
      active: true,
      section: target.section,
      targetId: target.id,
    );
  }

  void _moveSection(List<HudGamepadFocusTarget> targets, int delta) {
    if (targets.isEmpty) {
      state = HudGamepadFocusState.inactive;
      return;
    }
    final sections = [
      for (final section in _sectionOrder)
        if (targets.any((target) => target.section == section)) section,
    ];
    if (sections.isEmpty) {
      state = HudGamepadFocusState.inactive;
      return;
    }
    final currentIndex = sections.indexOf(state.section);
    final startIndex = currentIndex == -1 ? 0 : currentIndex;
    final nextIndex = (startIndex + delta) % sections.length;
    final section =
        sections[nextIndex < 0 ? nextIndex + sections.length : nextIndex];
    _activateFirst(targets, preferredSection: section);
  }

  bool _directionMovesWithinSection(
    GamepadMapDirection direction,
    HudGamepadFocusSection section,
  ) {
    final vertical =
        section == HudGamepadFocusSection.globalActions ||
        section == HudGamepadFocusSection.rightPlayers;
    return switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.down => vertical,
      GamepadMapDirection.left || GamepadMapDirection.right => !vertical,
    };
  }

  int _directionDelta(GamepadMapDirection direction) {
    return switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.left => -1,
      GamepadMapDirection.down || GamepadMapDirection.right => 1,
    };
  }
}

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
          leftTarget.enabled != rightTarget.enabled) {
        return false;
      }
    }
    return true;
  }
}
