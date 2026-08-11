part of 'game_event_renderer_effect_mapper.dart';

List<RendererEffect> fortificationThreatRendererEffects(
  GameClientState state,
  FortifiedUnitThreatenedEvent event, {
  GameClientState? previousState,
  String? viewerPlayerId,
}) {
  final viewerId = viewerPlayerId ?? state.activePlayerId;
  if (viewerId != event.ownerPlayerId) return const [];
  final detectionState = previousState ?? state;
  final fortifier = state.unitById(event.unitId);
  if (fortifier == null ||
      !_isCurrentFortifier(fortifier, event.ownerPlayerId)) {
    return const [];
  }
  final alerts = [
    for (final target in event.targets)
      ?_fortificationTargetAlert(
        state: state,
        detectionState: detectionState,
        event: event,
        target: target,
        viewerPlayerId: viewerPlayerId,
      ),
  ];
  if (alerts.isEmpty) return const [];
  return [...alerts];
}

bool _isCurrentFortifier(GameUnit unit, String ownerPlayerId) =>
    unit.ownerPlayerId == ownerPlayerId && unit.isFortified;

ShowCombatHexAlertEffect? _fortificationTargetAlert({
  required GameClientState state,
  required GameClientState detectionState,
  required FortifiedUnitThreatenedEvent event,
  required FortifiedUnitThreatTarget target,
  required String? viewerPlayerId,
}) {
  final detectedEnemy = detectionState.unitById(target.unitId);
  final currentEnemy = state.unitById(target.unitId);
  if (detectedEnemy == null ||
      currentEnemy == null ||
      detectedEnemy.ownerPlayerId == event.ownerPlayerId ||
      detectedEnemy.col != target.col ||
      detectedEnemy.row != target.row) {
    return null;
  }
  if (!_canRenderTransientAt(
    detectionState,
    target.col,
    target.row,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  return ShowCombatHexAlertEffect(
    id: 'fortification:${event.unitId}:${target.unitId}',
    ownerPlayerId: event.ownerPlayerId,
    col: target.col,
    row: target.row,
    kind: CombatHexAlertKind.fortificationThreat,
    unitId: currentEnemy.id,
    expiresAfter: GameCameraEffectNormalizer.turnStartCameraTransitionDuration,
  );
}
