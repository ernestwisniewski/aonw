import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/util/wire_json.dart';

abstract final class ArtifactEventSerializer {
  static Map<String, dynamic> toJson(WorldEntityLifecycleEvent event) {
    return switch (event) {
      CityFoundedEvent(:final cityId, :final ownerPlayerId) => {
        'type': 'CityFounded',
        'cityId': cityId,
        'ownerPlayerId': ownerPlayerId,
      },
      ArtifactExcavationStartedEvent(
        :final artifactId,
        :final ownerPlayerId,
        :final unitId,
        :final col,
        :final row,
      ) =>
        {
          'type': 'ArtifactExcavationStarted',
          'artifactId': artifactId,
          'ownerPlayerId': ownerPlayerId,
          'unitId': unitId,
          'col': col,
          'row': row,
        },
      ArtifactCarriedEvent(
        :final artifactId,
        :final ownerPlayerId,
        :final unitId,
        :final col,
        :final row,
      ) =>
        {
          'type': 'ArtifactCarried',
          'artifactId': artifactId,
          'ownerPlayerId': ownerPlayerId,
          'unitId': unitId,
          'col': col,
          'row': row,
        },
      ArtifactStoredEvent(
        :final artifactId,
        :final ownerPlayerId,
        :final unitId,
        :final cityId,
        :final col,
        :final row,
      ) =>
        {
          'type': 'ArtifactStored',
          'artifactId': artifactId,
          'ownerPlayerId': ownerPlayerId,
          'unitId': ?unitId,
          'cityId': cityId,
          'col': col,
          'row': row,
        },
    };
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return switch (type) {
      'CityFounded' => CityFoundedEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
      ),
      'ArtifactExcavationStarted' => ArtifactExcavationStartedEvent(
        artifactId: requiredStringField(json, type, 'artifactId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        unitId: requiredStringField(json, type, 'unitId'),
        col: requiredIntField(json, type, 'col'),
        row: requiredIntField(json, type, 'row'),
      ),
      'ArtifactCarried' => ArtifactCarriedEvent(
        artifactId: requiredStringField(json, type, 'artifactId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        unitId: requiredStringField(json, type, 'unitId'),
        col: requiredIntField(json, type, 'col'),
        row: requiredIntField(json, type, 'row'),
      ),
      'ArtifactStored' => ArtifactStoredEvent(
        artifactId: requiredStringField(json, type, 'artifactId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        unitId: optionalStringField(json, type, 'unitId'),
        cityId: requiredStringField(json, type, 'cityId'),
        col: requiredIntField(json, type, 'col'),
        row: requiredIntField(json, type, 'row'),
      ),
      _ => null,
    };
  }
}
