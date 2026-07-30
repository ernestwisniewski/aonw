import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';

/// Stable identity of one authoritative presentation batch.
///
/// [sourceId] is the canonical match/save identity and [eventOffset] is the
/// persisted command/event-log offset. Neither value depends on wall clock.
final class PresentationBatchIdentity {
  const PresentationBatchIdentity({
    required this.sourceId,
    required this.eventOffset,
    this.interactionId,
  });

  final String sourceId;
  final int eventOffset;
  final String? interactionId;
}

/// One renderer effect scheduled on a deterministic logical timeline.
final class ProjectedGameEffect {
  const ProjectedGameEffect({
    required this.effect,
    required this.sourceId,
    required this.animationId,
    required this.eventOffset,
    required this.ordinal,
    required this.startOffset,
  });

  final RendererEffect effect;
  final String sourceId;
  final String animationId;
  final int eventOffset;
  final int ordinal;
  final Duration startOffset;
}

/// Bounded exactly-once cursor for one renderer's authoritative event stream.
final class ProjectedGameEffectCursor {
  String? _activeSourceId;
  int _highestEventOffset = -1;
  final Set<String> _idsAtHighestOffset = {};

  int get retainedIdentityCount => _idsAtHighestOffset.length;

  List<RendererEffect> consume(Iterable<ProjectedGameEffect> projected) {
    final accepted = <RendererEffect>[];
    for (final item in projected) {
      _activeSourceId ??= item.sourceId;
      if (item.sourceId != _activeSourceId) continue;
      if (item.eventOffset < _highestEventOffset) continue;
      if (item.eventOffset > _highestEventOffset) {
        _highestEventOffset = item.eventOffset;
        _idsAtHighestOffset.clear();
      }
      if (_idsAtHighestOffset.add(item.animationId)) {
        accepted.add(item.effect);
      }
    }
    return accepted;
  }

  void activateSource(String sourceId) {
    if (_activeSourceId == sourceId) return;
    _activeSourceId = sourceId;
    _resetOffset();
  }

  void resetForReplaySeek() {
    _resetOffset();
  }

  void _resetOffset() {
    _highestEventOffset = -1;
    _idsAtHighestOffset.clear();
  }
}

/// Keeps interaction-only focus separate from authoritative domain animation.
final class ProjectedGameEffectBatch {
  ProjectedGameEffectBatch({
    Iterable<ProjectedGameEffect> projectedInteractionEffects = const [],
    Iterable<ProjectedGameEffect> domainEffects = const [],
  }) : projectedInteractionEffects = List.unmodifiable(
         projectedInteractionEffects,
       ),
       domainEffects = List.unmodifiable(domainEffects);

  final List<ProjectedGameEffect> projectedInteractionEffects;
  final List<ProjectedGameEffect> domainEffects;

  List<ProjectedGameEffect> get projectedEffects =>
      List.unmodifiable([...projectedInteractionEffects, ...domainEffects]);

  List<RendererEffect> get effects => List.unmodifiable([
    ...projectedInteractionEffects.map((projected) => projected.effect),
    ...domainEffects.map((projected) => projected.effect),
  ]);
}
