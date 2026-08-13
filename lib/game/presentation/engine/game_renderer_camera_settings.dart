typedef GameRendererMovementCameraSettings = ({
  bool focusOwnUnitMovementCamera,
  bool followOwnUnitMovementCamera,
  bool focusEnemyUnitMovementCamera,
  bool followEnemyUnitMovementCamera,
  bool cinematicCameraEnabled,
  bool unitAnimationsEnabled,
  bool cameraTransitionsEnabled,
});

final class GameRendererCameraSettings {
  GameRendererCameraSettings({
    required this.moveCameraForUnitMovement,
    required this.focusOwnUnitMovementCamera,
    required this.followOwnUnitMovementCamera,
    required this.focusEnemyUnitMovementCamera,
    required this.followEnemyUnitMovementCamera,
    required this.cinematicCameraEnabled,
  });

  bool moveCameraForUnitMovement;
  bool focusOwnUnitMovementCamera;
  bool followOwnUnitMovementCamera;
  bool focusEnemyUnitMovementCamera;
  bool followEnemyUnitMovementCamera;
  bool cinematicCameraEnabled;
  bool unitAnimationsEnabled = true;
  bool cameraTransitionsEnabled = true;

  bool get enemyFocusEnabled => focusEnemyUnitMovementCamera;
  void setEnemyFocus(bool value) => focusEnemyUnitMovementCamera = value;

  bool applyMovement(GameRendererMovementCameraSettings value) {
    final projectionChanged =
        cinematicCameraEnabled != value.cinematicCameraEnabled;
    focusOwnUnitMovementCamera = value.focusOwnUnitMovementCamera;
    followOwnUnitMovementCamera = value.followOwnUnitMovementCamera;
    focusEnemyUnitMovementCamera = value.focusEnemyUnitMovementCamera;
    followEnemyUnitMovementCamera = value.followEnemyUnitMovementCamera;
    cinematicCameraEnabled = value.cinematicCameraEnabled;
    unitAnimationsEnabled = value.unitAnimationsEnabled;
    cameraTransitionsEnabled = value.cameraTransitionsEnabled;
    return projectionChanged;
  }
}
