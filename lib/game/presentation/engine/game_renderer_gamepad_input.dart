part of 'game_renderer.dart';

extension GameRendererGamepadInput on GameRenderer {
  void applyGamepadAnalogFrame(GamepadControlFrame frame, double dt) =>
      _gamepadController.applyAnalogFrame(frame, dt);

  void moveGamepadCursor(GamepadMapDirection direction) =>
      _gamepadController.moveCursor(direction);

  void confirmGamepadCursor() => _gamepadController.confirmCursor();

  void cancelGamepadAction() => _gamepadController.cancelAction();

  void inspectGamepadCursor() => _gamepadController.inspectCursor();

  void toggleGamepadMoveMode() => _gamepadController.toggleMoveMode();

  void focusPreviousGamepadAction() => _gamepadController.focusPreviousAction();

  void focusNextGamepadAction() => _gamepadController.focusNextAction();
}
