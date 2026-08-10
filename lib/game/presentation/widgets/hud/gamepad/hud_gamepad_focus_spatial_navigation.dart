part of 'hud_gamepad_focus_controller.dart';

extension _HudGamepadFocusSpatialNavigation on HudGamepadFocusController {
  void _moveSpatially(
    List<HudGamepadFocusTarget> targets,
    HudGamepadFocusTarget focused,
    GamepadMapDirection direction,
  ) {
    switch (focused.section) {
      case HudGamepadFocusSection.globalActions:
        _moveFromGlobalActions(targets, direction);
      case HudGamepadFocusSection.menu:
        _moveFromMenu(targets, direction);
      case HudGamepadFocusSection.topResources:
        _moveFromTopResources(targets, direction);
      case HudGamepadFocusSection.rightPlayers:
        _moveFromRightPlayers(targets, direction);
      case HudGamepadFocusSection.selectionActions:
        _moveFromSelectionActions(targets, focused, direction);
    }
  }

  void _moveFromGlobalActions(
    List<HudGamepadFocusTarget> targets,
    GamepadMapDirection direction,
  ) {
    switch (direction) {
      case GamepadMapDirection.up:
        if (_moveWithinSectionBounded(
          targets,
          HudGamepadFocusSection.globalActions,
          -1,
        )) {
          return;
        }
        _activateFirstAvailable(targets, const [HudGamepadFocusSection.menu]);
        return;
      case GamepadMapDirection.down:
        if (_moveWithinSectionBounded(
          targets,
          HudGamepadFocusSection.globalActions,
          1,
        )) {
          return;
        }
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.selectionActions,
          HudGamepadFocusSection.topResources,
        ]);
        return;
      case GamepadMapDirection.right:
        _activateFirstAvailable(targets, const [HudGamepadFocusSection.menu]);
        return;
      case GamepadMapDirection.left:
        return;
    }
  }

  void _moveFromMenu(
    List<HudGamepadFocusTarget> targets,
    GamepadMapDirection direction,
  ) {
    switch (direction) {
      case GamepadMapDirection.right:
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.topResources,
          HudGamepadFocusSection.rightPlayers,
          HudGamepadFocusSection.selectionActions,
        ]);
        return;
      case GamepadMapDirection.down:
      case GamepadMapDirection.left:
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.globalActions,
          HudGamepadFocusSection.selectionActions,
        ]);
        return;
      case GamepadMapDirection.up:
        return;
    }
  }

  void _moveFromTopResources(
    List<HudGamepadFocusTarget> targets,
    GamepadMapDirection direction,
  ) {
    switch (direction) {
      case GamepadMapDirection.left:
        if (_moveWithinSectionBounded(
          targets,
          HudGamepadFocusSection.topResources,
          -1,
        )) {
          return;
        }
        _activateFirstAvailable(targets, const [HudGamepadFocusSection.menu]);
        return;
      case GamepadMapDirection.right:
        if (_moveWithinSectionBounded(
          targets,
          HudGamepadFocusSection.topResources,
          1,
        )) {
          return;
        }
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.rightPlayers,
          HudGamepadFocusSection.selectionActions,
        ]);
        return;
      case GamepadMapDirection.down:
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.rightPlayers,
          HudGamepadFocusSection.selectionActions,
        ]);
        return;
      case GamepadMapDirection.up:
        _activateFirstAvailable(targets, const [HudGamepadFocusSection.menu]);
        return;
    }
  }

  void _moveFromRightPlayers(
    List<HudGamepadFocusTarget> targets,
    GamepadMapDirection direction,
  ) {
    switch (direction) {
      case GamepadMapDirection.up:
        if (_moveWithinSectionBounded(
          targets,
          HudGamepadFocusSection.rightPlayers,
          -1,
        )) {
          return;
        }
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.topResources,
          HudGamepadFocusSection.menu,
        ]);
        return;
      case GamepadMapDirection.down:
        if (_moveWithinSectionBounded(
          targets,
          HudGamepadFocusSection.rightPlayers,
          1,
        )) {
          return;
        }
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.selectionActions,
          HudGamepadFocusSection.globalActions,
        ]);
        return;
      case GamepadMapDirection.left:
        _activateFirstAvailable(targets, const [
          HudGamepadFocusSection.topResources,
          HudGamepadFocusSection.menu,
        ]);
        return;
      case GamepadMapDirection.right:
        return;
    }
  }
}
