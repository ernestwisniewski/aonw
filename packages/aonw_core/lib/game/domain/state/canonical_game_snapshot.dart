import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/state/game_snapshot_metadata.dart';
import 'package:aonw_core/game/domain/state/match_session_state.dart';

/// Persisted multi-step interaction state kept outside canonical game rules.
final class PersistedInteractionState {
  static const Object _unset = Object();
  static const empty = PersistedInteractionState._owned();

  factory PersistedInteractionState({
    CityFoundingDraft? cityFoundingDraft,
    PendingPlayerAction? pendingAction,
  }) {
    return PersistedInteractionState._owned(
      cityFoundingDraft: _ownedCityFoundingDraft(cityFoundingDraft),
      pendingAction: pendingAction,
    );
  }

  const PersistedInteractionState._owned({
    this.cityFoundingDraft,
    this.pendingAction,
  });

  final CityFoundingDraft? cityFoundingDraft;
  final PendingPlayerAction? pendingAction;

  PersistedInteractionState copyWith({
    Object? cityFoundingDraft = _unset,
    Object? pendingAction = _unset,
  }) {
    return PersistedInteractionState._owned(
      cityFoundingDraft: identical(cityFoundingDraft, _unset)
          ? this.cityFoundingDraft
          : _ownedCityFoundingDraft(cityFoundingDraft as CityFoundingDraft?),
      pendingAction: identical(pendingAction, _unset)
          ? this.pendingAction
          : pendingAction as PendingPlayerAction?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistedInteractionState &&
          other.cityFoundingDraft == cityFoundingDraft &&
          other.pendingAction == pendingAction;

  @override
  int get hashCode => Object.hash(cityFoundingDraft, pendingAction);
}

/// Neutral snapshot envelope composed of independent state boundaries.
final class CanonicalGameSnapshot {
  factory CanonicalGameSnapshot.snapshot({
    required DomainState domain,
    required MatchSessionState session,
    required GameSnapshotMetadata metadata,
    PersistedInteractionState interaction = PersistedInteractionState.empty,
    int eventLogOffset = 0,
  }) {
    if (eventLogOffset < 0) {
      throw ArgumentError.value(
        eventLogOffset,
        'eventLogOffset',
        'Must not be negative',
      );
    }
    return CanonicalGameSnapshot._owned(
      domain: domain,
      session: session,
      metadata: metadata,
      interaction: interaction,
      eventLogOffset: eventLogOffset,
    );
  }

  const CanonicalGameSnapshot._owned({
    required this.domain,
    required this.session,
    required this.metadata,
    required this.interaction,
    required this.eventLogOffset,
  });

  final DomainState domain;
  final MatchSessionState session;
  final GameSnapshotMetadata metadata;
  final PersistedInteractionState interaction;
  final int eventLogOffset;

  CanonicalGameSnapshot copyWith({
    DomainState? domain,
    MatchSessionState? session,
    GameSnapshotMetadata? metadata,
    PersistedInteractionState? interaction,
    int? eventLogOffset,
  }) {
    return CanonicalGameSnapshot.snapshot(
      domain: domain ?? this.domain,
      session: session ?? this.session,
      metadata: metadata ?? this.metadata,
      interaction: interaction ?? this.interaction,
      eventLogOffset: eventLogOffset ?? this.eventLogOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanonicalGameSnapshot &&
          other.domain == domain &&
          other.session == session &&
          other.metadata == metadata &&
          other.interaction == interaction &&
          other.eventLogOffset == eventLogOffset;

  @override
  int get hashCode =>
      Object.hash(domain, session, metadata, interaction, eventLogOffset);
}

CityFoundingDraft? _ownedCityFoundingDraft(CityFoundingDraft? source) {
  if (source == null) return null;
  return CityFoundingDraft(
    unitId: source.unitId,
    ownerPlayerId: source.ownerPlayerId,
    center: source.center,
    controlledHexes: source.controlledHexes,
  );
}
