import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/hud_feedback_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';

class ArtifactGuidanceResolver {
  final AppLocalizations l10n;

  const ArtifactGuidanceResolver({required this.l10n});

  HudFeedbackContent? resolve({
    required GameState previousState,
    required GameState state,
    required Iterable<GameEvent> events,
  }) {
    final change = _ArtifactGuidanceChangeDetector(
      previousState: previousState,
      state: state,
      events: events,
      playerId: previousState.activePlayerId,
    ).detect();

    return switch (change) {
      _StoredArtifactGuidance(:final artifact, :final city) => _storedContent(
        artifact,
        city,
      ),
      _CarriedArtifactGuidance(:final artifact) => _carriedContent(artifact),
      _ReachedArtifactGuidance(:final artifact) => _reachedContent(artifact),
      null => null,
    };
  }

  HudFeedbackContent _storedContent(WorldArtifact artifact, GameCity city) {
    final artifactName = GameDisplayNames.worldArtifact(l10n, artifact.type);
    return HudFeedbackContent(
      kind: HudFeedbackKind.artifactGuidance,
      title: l10n.artifactGuidanceStoredTitle,
      body: l10n.artifactGuidanceStoredBody(
        artifactName,
        _cityDisplayName(city),
      ),
    );
  }

  HudFeedbackContent _carriedContent(WorldArtifact artifact) {
    final artifactName = GameDisplayNames.worldArtifact(l10n, artifact.type);
    return HudFeedbackContent(
      kind: HudFeedbackKind.artifactGuidance,
      title: l10n.artifactGuidanceCarriedTitle,
      body: l10n.artifactGuidanceCarriedBody(artifactName),
    );
  }

  HudFeedbackContent _reachedContent(WorldArtifact artifact) {
    final artifactName = GameDisplayNames.worldArtifact(l10n, artifact.type);
    return HudFeedbackContent(
      kind: HudFeedbackKind.artifactGuidance,
      title: l10n.artifactGuidanceReachedTitle,
      body: l10n.artifactGuidanceReachedBody(artifactName),
    );
  }

  String _cityDisplayName(GameCity city) {
    return city.name.trim().isEmpty
        ? l10n.artifactGuidanceUnknownCityName
        : GameDisplayNames.city(l10n, city);
  }
}

class _ArtifactGuidanceChangeDetector {
  final GameState previousState;
  final GameState state;
  final Iterable<GameEvent> events;
  final String playerId;

  const _ArtifactGuidanceChangeDetector({
    required this.previousState,
    required this.state,
    required this.events,
    required this.playerId,
  });

  _ArtifactGuidanceChange? detect() {
    if (playerId.isEmpty) return null;
    return _newlyStoredArtifact() ??
        _newlyCarriedArtifact() ??
        _artifactReachedByMovedUnit();
  }

  _StoredArtifactGuidance? _newlyStoredArtifact() {
    for (final artifact in state.artifacts) {
      final location = artifact.location;
      if (!location.isStored || location.cityId == null) continue;
      final city = _cityById(state, location.cityId!);
      if (city?.ownerPlayerId != playerId) continue;
      final previous = _artifactById(previousState, artifact.id);
      if (previous?.location == artifact.location) continue;
      return _StoredArtifactGuidance(artifact: artifact, city: city!);
    }
    return null;
  }

  _CarriedArtifactGuidance? _newlyCarriedArtifact() {
    for (final unit in state.units) {
      if (unit.ownerPlayerId != playerId) continue;
      final artifactId = unit.carriedArtifactId;
      if (artifactId == null) continue;
      final previousUnit = _unitById(previousState, unit.id);
      if (previousUnit?.carriedArtifactId == artifactId) continue;
      final artifact = _artifactById(state, artifactId);
      return artifact == null
          ? null
          : _CarriedArtifactGuidance(artifact: artifact);
    }
    return null;
  }

  _ReachedArtifactGuidance? _artifactReachedByMovedUnit() {
    for (final event in events.whereType<UnitMovedEvent>()) {
      final unit = _unitById(state, event.unitId);
      if (!_canDiscoverArtifact(unit)) continue;
      final artifact = _mapArtifactAt(state, event.toCol, event.toRow);
      if (artifact != null) {
        return _ReachedArtifactGuidance(artifact: artifact);
      }
    }
    return null;
  }

  bool _canDiscoverArtifact(GameUnit? unit) {
    return unit != null &&
        unit.ownerPlayerId == playerId &&
        unit.carriedArtifactId == null &&
        unit.excavatingArtifactId == null;
  }

  WorldArtifact? _artifactById(GameState state, String artifactId) {
    for (final artifact in state.artifacts) {
      if (artifact.id == artifactId) return artifact;
    }
    return null;
  }

  WorldArtifact? _mapArtifactAt(GameState state, int col, int row) {
    for (final artifact in state.artifacts) {
      final location = artifact.location;
      if (location.isOnMap && location.col == col && location.row == row) {
        return artifact;
      }
    }
    return null;
  }

  GameCity? _cityById(GameState state, String cityId) {
    for (final city in state.cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  GameUnit? _unitById(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }
}

sealed class _ArtifactGuidanceChange {
  const _ArtifactGuidanceChange();
}

final class _StoredArtifactGuidance extends _ArtifactGuidanceChange {
  final WorldArtifact artifact;
  final GameCity city;

  const _StoredArtifactGuidance({required this.artifact, required this.city});
}

final class _CarriedArtifactGuidance extends _ArtifactGuidanceChange {
  final WorldArtifact artifact;

  const _CarriedArtifactGuidance({required this.artifact});
}

final class _ReachedArtifactGuidance extends _ArtifactGuidanceChange {
  final WorldArtifact artifact;

  const _ReachedArtifactGuidance({required this.artifact});
}
