final class GameRendererCameraSettings {
  GameRendererCameraSettings({
    required this.moveCameraForUnitMovement,
    required this.followUnitMovementCamera,
    required this.followEnemyUnitCamera,
    required this.cinematicCameraEnabled,
  });

  bool moveCameraForUnitMovement;
  bool followUnitMovementCamera;
  bool followEnemyUnitCamera;
  bool cinematicCameraEnabled;
}
