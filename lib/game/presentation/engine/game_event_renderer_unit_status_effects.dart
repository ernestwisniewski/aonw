part of 'game_event_renderer_effect_mapper.dart';

RendererEffect? _workerCompletedJobEffect(
  GameClientState state,
  GameClientState? previousState,
  String unitId, {
  AppLocalizations? l10n,
  String? viewerPlayerId,
}) {
  if (previousState == null) return null;
  final job = previousState.unitById(unitId)?.workerJob;
  if (job == null) return null;
  final yieldLabel = _yieldLabelFor(job.improvementType, l10n: l10n);
  if (yieldLabel == null && l10n == null) return null;
  if (!_canRenderTransientAt(
    state,
    job.targetHex.col,
    job.targetHex.row,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  final label =
      yieldLabel ??
      '+${GameDisplayNames.fieldImprovement(l10n!, job.improvementType)}';
  return ShowFloatingTextEffect(
    text: label,
    col: job.targetHex.col,
    row: job.targetHex.row,
    colorValue: 0xFF86EFAC,
  );
}

List<RendererEffect> _unitKilledEffects(
  GameClientState state,
  GameClientState? previousState,
  String unitId,
  String ownerPlayerId, {
  String? viewerPlayerId,
}) {
  final unit =
      (previousState ?? state).unitById(unitId) ?? state.unitById(unitId);
  if (unit == null) return const [];
  if (!_canRenderTransientAt(
    state,
    unit.col,
    unit.row,
    viewerPlayerId: viewerPlayerId,
  )) {
    return const [];
  }
  return [
    SpawnParticleBurstEffect(
      kind: ParticleBurstKind.unitKilled,
      col: unit.col,
      row: unit.row,
      colorValue: _colorForPlayer(state, ownerPlayerId),
    ),
    ShowFloatingTextEffect(
      text: 'KO',
      col: unit.col,
      row: unit.row,
      colorValue: _damageTextColor,
      delay: _combatResultCueDelay,
    ),
  ];
}

String? _yieldLabelFor(
  FieldImprovementType improvementType, {
  AppLocalizations? l10n,
}) {
  final yield = FieldImprovementCatalog.standard[improvementType]?.tileYield;
  if (yield == null) return null;
  final foodLabel = _localizedYieldLabel(l10n, (value) => value.yieldFoodShort);
  final productionLabel = _localizedYieldLabel(
    l10n,
    (value) => value.yieldProductionShort,
  );
  final goldLabel = _localizedYieldLabel(l10n, (value) => value.yieldGoldShort);
  final defenseLabel = _localizedYieldLabel(
    l10n,
    (value) => value.yieldDefenseShort,
  );
  final parts = [
    if (yield.food > 0) _yieldPart(yield.food, foodLabel),
    if (yield.production > 0) _yieldPart(yield.production, productionLabel),
    if (yield.gold > 0) _yieldPart(yield.gold, goldLabel),
    if (yield.defense > 0) _yieldPart(yield.defense, defenseLabel),
  ];
  if (parts.isEmpty) return null;
  return parts.join(' ');
}

String _yieldPart(int value, String? label) {
  if (label == null || label.isEmpty) return '+$value';
  return '+$value $label';
}

String? _localizedYieldLabel(
  AppLocalizations? l10n,
  String Function(AppLocalizations value) labelFor,
) {
  return switch (l10n) {
    final AppLocalizations value => labelFor(value),
    null => null,
  };
}
