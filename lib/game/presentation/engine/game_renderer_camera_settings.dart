typedef GameRendererMovementCameraSettings = ({
  bool focusOwnUnitMovementCamera,
  bool followOwnUnitMovementCamera,
  bool focusEnemyUnitMovementCamera,
  bool followEnemyUnitMovementCamera,
  bool cinematicCameraEnabled,
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

  bool applyMovement(GameRendererMovementCameraSettings value) {
    final projectionChanged =
        cinematicCameraEnabled != value.cinematicCameraEnabled;
    focusOwnUnitMovementCamera = value.focusOwnUnitMovementCamera;
    followOwnUnitMovementCamera = value.followOwnUnitMovementCamera;
    focusEnemyUnitMovementCamera = value.focusEnemyUnitMovementCamera;
    followEnemyUnitMovementCamera = value.followEnemyUnitMovementCamera;
    cinematicCameraEnabled = value.cinematicCameraEnabled;
    return projectionChanged;
  }
}
