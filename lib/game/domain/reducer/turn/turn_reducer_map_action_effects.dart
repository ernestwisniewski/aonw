part of 'turn_reducer.dart';

typedef _ClientState = GameClientState;

List<RendererEffect> _mapActionTargetEffects(
  int col,
  int row, {
  String? unitId,
}) => [
  JumpCameraEffect(col: col, row: row),
  ShowActionTargetFocusEffect(unitId: unitId, col: col, row: row),
];
