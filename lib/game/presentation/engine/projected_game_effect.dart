import 'dart:collection';

import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';

const presentationFrameBudget = Duration(microseconds: 16667);

/// Stable identity and authoritative clock of one presentation batch.
final class PresentationBatchIdentity {
  const PresentationBatchIdentity({
    required this.sourceId,
    required this.eventOffset,
    this.authoritativeTick,
    this.authoritativeStartMicrosUtc,
    this.interactionId,
  });

  final String sourceId;
  final int eventOffset;
  final int? authoritativeTick;
  final int? authoritativeStartMicrosUtc;
  final String? interactionId;

  int get resolvedAuthoritativeTick => authoritativeTick ?? eventOffset;

  int get resolvedAuthoritativeStartMicrosUtc =>
      authoritativeStartMicrosUtc ??
      resolvedAuthoritativeTick * Duration.microsecondsPerSecond;

  String eventId(int eventSequence) => '$sourceId:$eventOffset:$eventSequence';
}

/// The complete, deterministic animation decision owned by one domain event.
final class AnimationPlan {
  AnimationPlan({
    required this.eventId,
    required this.eventType,
    required this.policy,
    required this.batchSequence,
    required this.eventSequence,
    required this.authoritativeTick,
    required this.authoritativeStartMicrosUtc,
    required this.startOffset,
    required Iterable<ProjectedGameEffect> animations,
  }) : animations = List.unmodifiable(animations);

  final String eventId;
  final String eventType;
  final String policy;
  final int batchSequence;
  final int eventSequence;
  final int authoritativeTick;
  final int authoritativeStartMicrosUtc;
  final Duration startOffset;
  final List<ProjectedGameEffect> animations;

  Duration get duration => animations.isEmpty
      ? Duration.zero
      : animations
                .map((animation) => animation.endOffset)
                .reduce((left, right) => left > right ? left : right) -
            startOffset;

  Duration get endOffset => startOffset + duration;
}

/// One renderer effect scheduled on the authoritative logical timeline.
final class ProjectedGameEffect {
  const ProjectedGameEffect({
    required this.effect,
    required this.sourceId,
    required this.eventId,
    required this.animationId,
    required this.eventOffset,
    required this.eventSequence,
    required this.authoritativeTick,
    required this.authoritativeStartMicrosUtc,
    required this.ordinal,
    required this.startOffset,
    required this.duration,
    this.isInteraction = false,
  });

  final RendererEffect effect;
  final String sourceId;
  final String eventId;
  final String animationId;
  final int eventOffset;
  final int eventSequence;
  final int authoritativeTick;
  final int authoritativeStartMicrosUtc;
  final int ordinal;
  final Duration startOffset;
  final Duration duration;
  final bool isInteraction;

  Duration get endOffset => startOffset + duration;

  int get logicalStartMicrosUtc =>
      authoritativeStartMicrosUtc + startOffset.inMicroseconds;

  int get logicalEndMicrosUtc =>
      authoritativeStartMicrosUtc + endOffset.inMicroseconds;
}

/// Bounded exactly-once cursor and sequence buffer for one event stream.
///
/// When [activateSource] receives [nextEventOffset], future offsets are held
/// until every preceding batch arrives. Duplicate, replayed, and stale event
/// identities are discarded without changing the canonical order.
final class ProjectedGameEffectCursor {
  String? _activeSourceId;
  int? _nextEventOffset;
  final SplayTreeMap<int, ProjectedGameEffectBatch> _pending = SplayTreeMap();
  final Set<String> _interactionIds = {};
  final Set<String> _idsAtLastOffset = {};

  int get retainedIdentityCount =>
      _idsAtLastOffset.length +
      _interactionIds.length +
      _pending.values.fold(
        0,
        (count, batch) => count + batch.domainEffects.length,
      );

  int get pendingSequenceCount => _pending.length;

  List<RendererEffect> consume(Iterable<ProjectedGameEffect> projected) {
    return _consumeProjected(projected).map((item) => item.effect).toList();
  }

  List<RendererEffect> consumeBatch(ProjectedGameEffectBatch batch) {
    return consumeProjectedBatch(batch).map((item) => item.effect).toList();
  }

  List<ProjectedGameEffect> consumeProjectedBatch(
    ProjectedGameEffectBatch batch,
  ) {
    final identity = batch.identity ?? _identityFrom(batch.projectedEffects);
    if (identity == null) return const [];
    _activeSourceId ??= identity.sourceId;
    if (identity.sourceId != _activeSourceId) return const [];

    final acceptedInteractions = _consumeInteractions(
      batch.projectedInteractionEffects,
    );
    if (!batch.hasAuthoritativeSequence) return acceptedInteractions;

    _nextEventOffset ??= identity.eventOffset;
    if (identity.eventOffset < _nextEventOffset!) {
      return acceptedInteractions;
    }
    _pending.putIfAbsent(identity.eventOffset, () => batch);
    return [...acceptedInteractions, ..._drainAuthoritative()];
  }

  void activateSource(String sourceId, {int? nextEventOffset}) {
    if (_activeSourceId == sourceId &&
        (nextEventOffset == null || nextEventOffset == _nextEventOffset)) {
      return;
    }
    _activeSourceId = sourceId;
    _resetOffset(nextEventOffset: nextEventOffset);
  }

  void resetForReplaySeek({int? nextEventOffset}) {
    _resetOffset(nextEventOffset: nextEventOffset);
  }

  List<ProjectedGameEffect> _consumeProjected(
    Iterable<ProjectedGameEffect> projected,
  ) {
    final items = projected.toList(growable: false);
    if (items.isEmpty) return const [];
    final identity = _identityFrom(items)!;
    return consumeProjectedBatch(
      ProjectedGameEffectBatch(
        identity: identity,
        projectedInteractionEffects: items.where((item) => item.isInteraction),
        domainEffects: items.where((item) => !item.isInteraction),
      ),
    );
  }

  List<ProjectedGameEffect> _consumeInteractions(
    Iterable<ProjectedGameEffect> interactions,
  ) {
    final accepted = <ProjectedGameEffect>[];
    for (final item in interactions) {
      if (item.sourceId != _activeSourceId) continue;
      if (_interactionIds.add(item.animationId)) accepted.add(item);
    }
    return accepted;
  }

  List<ProjectedGameEffect> _drainAuthoritative() {
    final accepted = <ProjectedGameEffect>[];
    while (_nextEventOffset != null) {
      final batch = _pending.remove(_nextEventOffset);
      if (batch == null) break;
      _idsAtLastOffset.clear();
      for (final item in batch.domainEffects) {
        if (_idsAtLastOffset.add(item.animationId)) accepted.add(item);
      }
      _interactionIds.clear();
      _nextEventOffset = _nextEventOffset! + 1;
    }
    return accepted;
  }

  PresentationBatchIdentity? _identityFrom(
    Iterable<ProjectedGameEffect> projected,
  ) {
    final items = projected.toList(growable: false);
    if (items.isEmpty) return null;
    final first = items.first;
    return PresentationBatchIdentity(
      sourceId: first.sourceId,
      eventOffset: first.eventOffset,
      authoritativeTick: first.authoritativeTick,
      authoritativeStartMicrosUtc: first.authoritativeStartMicrosUtc,
    );
  }

  void _resetOffset({int? nextEventOffset}) {
    _nextEventOffset = nextEventOffset;
    _pending.clear();
    _interactionIds.clear();
    _idsAtLastOffset.clear();
  }
}

/// One state transition that must stay attached to its projected animations.
final class ProjectedGameTransition<T> {
  const ProjectedGameTransition({
    required this.state,
    required this.batch,
    this.currentTurn,
  });

  final T state;
  final ProjectedGameEffectBatch batch;
  final int? currentTurn;
}

/// Orders complete renderer transitions before either state or effects apply.
///
/// Buffering only [ProjectedGameEffect] would let an out-of-order state reach
/// the renderer without its animations. Keeping the state and batch together
/// prevents visual jumps and later state regression when the missing sequence
/// arrives.
final class ProjectedGameTransitionQueue<T> {
  String? _activeSourceId;
  int? _nextEventOffset;
  final SplayTreeMap<int, ProjectedGameTransition<T>> _pending = SplayTreeMap();

  int get pendingSequenceCount => _pending.length;

  List<ProjectedGameTransition<T>> enqueue(
    ProjectedGameTransition<T> transition,
  ) {
    final identity = transition.batch.identity;
    if (identity == null) return [transition];
    _activeSourceId ??= identity.sourceId;
    if (identity.sourceId != _activeSourceId) return const [];
    if (!transition.batch.hasAuthoritativeSequence) return [transition];

    _nextEventOffset ??= identity.eventOffset;
    if (identity.eventOffset < _nextEventOffset!) return const [];
    _pending.putIfAbsent(identity.eventOffset, () => transition);
    return _drainAuthoritative();
  }

  void activateSource(String sourceId, {int? nextEventOffset}) {
    if (_activeSourceId == sourceId &&
        (nextEventOffset == null || nextEventOffset == _nextEventOffset)) {
      return;
    }
    _activeSourceId = sourceId;
    _resetOffset(nextEventOffset: nextEventOffset);
  }

  void resetForReplaySeek({int? nextEventOffset}) {
    _resetOffset(nextEventOffset: nextEventOffset);
  }

  List<ProjectedGameTransition<T>> _drainAuthoritative() {
    final accepted = <ProjectedGameTransition<T>>[];
    while (_nextEventOffset != null) {
      final transition = _pending.remove(_nextEventOffset);
      if (transition == null) break;
      accepted.add(transition);
      _nextEventOffset = _nextEventOffset! + 1;
    }
    return accepted;
  }

  void _resetOffset({int? nextEventOffset}) {
    _nextEventOffset = nextEventOffset;
    _pending.clear();
  }
}

/// Keeps interaction-only focus separate from authoritative domain animation.
final class ProjectedGameEffectBatch {
  ProjectedGameEffectBatch({
    this.identity,
    Iterable<ProjectedGameEffect> projectedInteractionEffects = const [],
    Iterable<AnimationPlan> animationPlans = const [],
    Iterable<ProjectedGameEffect> domainEffects = const [],
  }) : projectedInteractionEffects = List.unmodifiable(
         projectedInteractionEffects,
       ),
       animationPlans = List.unmodifiable(animationPlans),
       domainEffects = List.unmodifiable(domainEffects);

  final PresentationBatchIdentity? identity;
  final List<ProjectedGameEffect> projectedInteractionEffects;
  final List<AnimationPlan> animationPlans;
  final List<ProjectedGameEffect> domainEffects;

  bool get hasAuthoritativeSequence =>
      animationPlans.isNotEmpty || domainEffects.isNotEmpty;

  List<ProjectedGameEffect> get projectedEffects =>
      List.unmodifiable([...projectedInteractionEffects, ...domainEffects]);

  List<RendererEffect> get effects => List.unmodifiable([
    ...projectedInteractionEffects.map((projected) => projected.effect),
    ...domainEffects.map((projected) => projected.effect),
  ]);
}
