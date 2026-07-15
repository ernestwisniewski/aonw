import 'package:aonw_core/domain/map_objective_definition.dart';
import 'package:aonw_core/map/domain/map_survey.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Read-only lookup for a tile at a single coordinate.
///
/// Returned values can borrow storage from their backing map. Consumers must
/// treat their collections as read-only.
abstract interface class MapTileLookup {
  MapTileView? tileAt(int col, int row);
}

/// Read-only dimensions and bounded tile reads for spatial algorithms.
abstract interface class MapTraversalView implements MapTileLookup {
  int get cols;
  int get rows;
}

/// Composite read-only view for bounded gameplay reads and map metadata.
abstract interface class MapReadView
    implements MapSurvey, MapTraversalView, MapTileCatalog {
  MapTileLookup get mapTiles;

  Iterable<MapObjectiveDefinition> get objectives;
}
