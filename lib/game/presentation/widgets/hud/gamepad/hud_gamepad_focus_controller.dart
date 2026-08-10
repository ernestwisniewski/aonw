import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_list_cursor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'hud_gamepad_focus_models.dart';
part 'hud_gamepad_focus_spatial_navigation.dart';
part 'hud_gamepad_focus_target_registry.dart';

class HudGamepadFocusController extends Notifier<HudGamepadFocusState> {
  static const _sectionOrder = [
    HudGamepadFocusSection.globalActions,
    HudGamepadFocusSection.menu,
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
    if (state.active && state.targetId == null) {
      final target = _firstTargetInSection(available, state.section);
      if (target != null) {
        state = HudGamepadFocusState(
          active: true,
          section: target.section,
          targetId: target.id,
        );
      }
      return;
    }
    if (!state.active || _targetForState(available) != null) return;
    _activateFirst(available, preferredSection: state.section);
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
    _moveSpatially(available, focused, direction);
  }

  void previousSection(List<HudGamepadFocusTarget> targets) {
    _moveSectionOrActivate(_availableTargets(targets), -1);
  }

  void nextSection(List<HudGamepadFocusTarget> targets) {
    _moveSectionOrActivate(_availableTargets(targets), 1);
  }

  void focusSection(
    List<HudGamepadFocusTarget> targets,
    HudGamepadFocusSection section, {
    HudGamepadFocusSection? fallbackSection,
    bool optimistic = false,
  }) {
    final available = _availableTargets(targets);
    final target = _firstTargetInSection(available, section);
    if (target != null) {
      state = HudGamepadFocusState(
        active: true,
        section: target.section,
        targetId: target.id,
      );
      return;
    }
    if (optimistic) {
      state = HudGamepadFocusState(
        active: true,
        section: section,
        targetId: null,
      );
      return;
    }
    _activateFirst(
      available,
      preferredSection: section,
      fallbackSection: fallbackSection,
    );
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
    HudGamepadFocusSection? fallbackSection,
  }) {
    if (targets.isEmpty) {
      state = HudGamepadFocusState.inactive;
      return;
    }
    final target =
        _firstTargetInSection(targets, preferredSection) ??
        _firstTargetInSection(targets, fallbackSection) ??
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

  void _moveFromSelectionActions(
    List<HudGamepadFocusTarget> targets,
    HudGamepadFocusTarget focused,
    GamepadMapDirection direction,
  ) {
    final actionTargets = _selectionActionTargets(targets);
    final commandTarget = _bottomCommandTarget(targets);
    if (focused.id == HudGamepadFocusTargetIds.bottomCommand) {
      switch (direction) {
        case GamepadMapDirection.up:
          _activateTarget(
            actionTargets.isNotEmpty
                ? actionTargets.first
                : _firstTargetInAvailableSections(targets, const [
                    HudGamepadFocusSection.rightPlayers,
                    HudGamepadFocusSection.topResources,
                    HudGamepadFocusSection.menu,
                  ]),
          );
          return;
        case GamepadMapDirection.left:
        case GamepadMapDirection.right:
        case GamepadMapDirection.down:
          return;
      }
    }

    switch (direction) {
      case GamepadMapDirection.left:
        if (_moveWithinTargetsBounded(actionTargets, -1)) return;
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.globalActions,
          HudGamepadFocusSection.menu,
        ]);
        return;
      case GamepadMapDirection.right:
        if (_moveWithinTargetsBounded(actionTargets, 1)) return;
        return;
      case GamepadMapDirection.down:
        _activateTarget(commandTarget);
        return;
      case GamepadMapDirection.up:
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.rightPlayers,
          HudGamepadFocusSection.topResources,
          HudGamepadFocusSection.menu,
        ]);
        return;
    }
  }

  bool _moveWithinSectionBounded(
    List<HudGamepadFocusTarget> targets,
    HudGamepadFocusSection section,
    int delta,
  ) {
    return _moveWithinTargetsBounded([
      for (final target in targets)
        if (target.section == section) target,
    ], delta);
  }

  bool _moveWithinTargetsBounded(
    List<HudGamepadFocusTarget> targets,
    int delta,
  ) {
    if (targets.isEmpty) return false;
    final currentIndex = targets.indexWhere(
      (target) => target.id == state.targetId,
    );
    if (currentIndex == -1) return false;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= targets.length) return false;
    _activateTarget(targets[nextIndex]);
    return true;
  }

  List<HudGamepadFocusTarget> _selectionActionTargets(
    List<HudGamepadFocusTarget> targets,
  ) {
    return [
      for (final target in targets)
        if (target.section == HudGamepadFocusSection.selectionActions &&
            target.id != HudGamepadFocusTargetIds.bottomCommand)
          target,
    ];
  }

  HudGamepadFocusTarget? _bottomCommandTarget(
    List<HudGamepadFocusTarget> targets,
  ) {
    for (final target in targets) {
      if (target.id == HudGamepadFocusTargetIds.bottomCommand) return target;
    }
    return null;
  }

  void _activateFirstAvailable(
    List<HudGamepadFocusTarget> targets,
    List<HudGamepadFocusSection> sections,
  ) {
    _activateTarget(_firstTargetInAvailableSections(targets, sections));
  }

  HudGamepadFocusTarget? _firstTargetInAvailableSections(
    List<HudGamepadFocusTarget> targets,
    List<HudGamepadFocusSection> sections,
  ) {
    for (final section in sections) {
      final target = _firstTargetInSection(targets, section);
      if (target != null) return target;
    }
    return null;
  }

  void _activateTarget(HudGamepadFocusTarget? target) {
    if (target == null) return;
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
    final section = GamepadListCursor.nextValue(
      items: sections,
      selected: state.section,
      delta: delta,
    )!;
    _activateFirst(targets, preferredSection: section);
  }

  void _moveSectionOrActivate(List<HudGamepadFocusTarget> targets, int delta) {
    if (state.active) {
      _moveSection(targets, delta);
      return;
    }
    _activateFirst(targets, preferredSection: state.section);
  }
}
