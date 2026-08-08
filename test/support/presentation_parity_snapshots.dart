import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';

Map<String, Object?> interactionPresentationSnapshot(
  InteractionState interaction,
) {
  final selection = interaction.selection;
  final tile = selection?.tile;
  return {
    'selection': selection == null
        ? null
        : {
            'type': selection.type.name,
            'tile': tile == null
                ? null
                : {
                    'col': tile.col,
                    'row': tile.row,
                    'height': tile.height,
                    'terrains': tile.terrains
                        .map((value) => value.name)
                        .toList(),
                    'resources': tile.resources
                        .map((value) => value.name)
                        .toList(),
                  },
            'unitId': selection.unit?.id,
            'cityId': selection.city?.id,
            'fieldImprovement': selection.fieldImprovement?.toJson(),
            'cityYield': selection.cityYield == null
                ? null
                : {
                    'food': selection.cityYield!.food,
                    'production': selection.cityYield!.production,
                    'gold': selection.cityYield!.gold,
                    'defense': selection.cityYield!.defense,
                  },
            'cityPlayerColor': selection.cityPlayerColor,
          },
    'movePreview': interaction.movePreview == null
        ? null
        : {
            'unitId': interaction.movePreview!.unitId,
            'targetCol': interaction.movePreview!.targetCol,
            'targetRow': interaction.movePreview!.targetRow,
            'totalCost': interaction.movePreview!.totalCost,
            'availableMovementPoints':
                interaction.movePreview!.availableMovementPoints,
            'steps': [
              for (final step in interaction.movePreview!.steps)
                [step.col, step.row, step.enterCost, step.cumulativeCost],
            ],
          },
    'cityFoundingDraft': interaction.cityFoundingDraft,
    'pendingAction': interaction.pendingAction,
    'moveCommandActive': interaction.moveCommandActive,
  };
}

Map<String, Object?> presentationBatchSnapshot(ProjectedGameEffectBatch batch) {
  return {
    'sequenceDirective': batch.sequenceDirective.name,
    'plans': batch.animationPlans
        .map(
          (plan) => {
            'eventId': plan.eventId,
            'eventType': plan.eventType,
            'policy': plan.policy,
            'batchSequence': plan.batchSequence,
            'eventSequence': plan.eventSequence,
            'authoritativeTick': plan.authoritativeTick,
            'authoritativeStartMicrosUtc': plan.authoritativeStartMicrosUtc,
            'startOffsetMicros': plan.startOffset.inMicroseconds,
            'durationMicros': plan.duration.inMicroseconds,
            'endOffsetMicros': plan.endOffset.inMicroseconds,
          },
        )
        .toList(growable: false),
    'interaction': batch.projectedInteractionEffects
        .map(projectedAnimationTraceSnapshot)
        .toList(growable: false),
    'domain': batch.domainEffects
        .map(projectedAnimationTraceSnapshot)
        .toList(growable: false),
  };
}

Map<String, Object?> uiEffectSnapshot(UiEffect effect) {
  return switch (effect) {
    ShowWorkerAutomationNoTargetEffect() => {
      'type': 'workerAutomationNoTarget',
    },
    ShowHudFeedbackEffect() => {
      'type': 'hudFeedback',
      'reason': effect.reason?.name,
      'title': effect.title,
      'body': effect.body,
    },
    RendererEffect() => rendererEffectSnapshot(effect),
  };
}

Map<String, Object?> projectedAnimationTraceSnapshot(
  ProjectedGameEffect projected,
) {
  return {
    'sourceId': projected.sourceId,
    'eventId': projected.eventId,
    'animationId': projected.animationId,
    'eventOffset': projected.eventOffset,
    'eventSequence': projected.eventSequence,
    'authoritativeTick': projected.authoritativeTick,
    'authoritativeStartMicrosUtc': projected.authoritativeStartMicrosUtc,
    'ordinal': projected.ordinal,
    'startOffsetMicros': projected.startOffset.inMicroseconds,
    'durationMicros': projected.duration.inMicroseconds,
    'endOffsetMicros': projected.endOffset.inMicroseconds,
    'logicalStartMicrosUtc': projected.logicalStartMicrosUtc,
    'logicalEndMicrosUtc': projected.logicalEndMicrosUtc,
    'effect': rendererEffectSnapshot(projected.effect),
  };
}

Map<String, Object?> rendererEffectSnapshot(RendererEffect effect) {
  return switch (effect) {
    AnimateUnitMoveEffect() => {
      'type': 'unitMove',
      'unitId': effect.unitId,
      'from': [effect.fromCol, effect.fromRow],
      'steps': [
        for (final step in effect.steps)
          {
            'col': step.col,
            'row': step.row,
            'enterCost': step.enterCost,
            'cumulativeCost': step.cumulativeCost,
          },
      ],
    },
    PlayCombatAnimationEffect() => {
      'type': 'combat',
      'attackerUnitId': effect.attackerUnitId,
      'defenderUnitId': effect.defenderUnitId,
      'attackerFrom': [effect.attackerFromCol, effect.attackerFromRow],
      'attackerTo': [effect.attackerToCol, effect.attackerToRow],
      'attackerKilled': effect.attackerKilled,
      'defenderKilled': effect.defenderKilled,
      'defenderRetaliated': effect.defenderRetaliated,
    },
    ShakeCameraEffect() => {
      'type': 'cameraShake',
      'intensity': effect.intensity,
      'duration': effect.duration,
    },
    SpawnParticleBurstEffect() => {
      'type': 'particleBurst',
      'kind': effect.kind.name,
      'col': effect.col,
      'row': effect.row,
      'colorValue': effect.colorValue,
    },
    ShowFloatingTextEffect() => {
      'type': 'floatingText',
      'text': effect.text,
      'col': effect.col,
      'row': effect.row,
      'colorValue': effect.colorValue,
      'delayMicros': effect.delay.inMicroseconds,
      'presentation': effect.presentation.name,
      'anchor': _floatingTextAnchorSnapshot(effect.anchor),
    },
    ShowCityProductionBubbleEffect() => {
      'type': 'cityProductionBubble',
      'cityId': effect.cityId,
      'target': effect.target.toJson(),
      'col': effect.col,
      'row': effect.row,
      'turnsRemaining': effect.turnsRemaining,
      'delayMicros': effect.delay.inMicroseconds,
    },
    ShowCombatHexAlertEffect() => {
      'type': 'combatHexAlert',
      'id': effect.id,
      'ownerPlayerId': effect.ownerPlayerId,
      'col': effect.col,
      'row': effect.row,
      'kind': effect.kind.name,
      'turn': effect.turn,
      'expiresAfter': effect.expiresAfter,
      'ownerSubmittedAtAttack': effect.ownerSubmittedAtAttack,
      'unitId': effect.unitId,
      'cityId': effect.cityId,
    },
    JumpCameraEffect() => {
      'type': 'jumpCamera',
      'col': effect.col,
      'row': effect.row,
    },
    SmoothCameraEffect() => {
      'type': 'smoothCamera',
      'col': effect.col,
      'row': effect.row,
      'duration': effect.duration,
    },
  };
}

Map<String, Object?> _floatingTextAnchorSnapshot(FloatingTextAnchor anchor) {
  return switch (anchor) {
    TileFloatingTextAnchor() => {'type': 'tile'},
    UnitFloatingTextAnchor() => {'type': 'unit', 'unitId': anchor.unitId},
    CityFloatingTextAnchor() => {'type': 'city', 'cityId': anchor.cityId},
  };
}
