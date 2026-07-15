import 'package:aonw_core/map/domain/terrain_type.dart';

/// Read-only metadata and terrain stream used by aggregate map rules.
///
/// Read-only is a consumer contract, not a promise of defensive copies.
/// Implementations may expose borrowed iterables to keep this view zero-copy;
/// callers must not mutate values reached through the survey.
abstract interface class MapSurvey {
  String? get mapName;
  int get tileCount;
  Iterable<Iterable<TerrainType>> get tileTerrains;
}
