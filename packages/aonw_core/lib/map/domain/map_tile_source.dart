import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Optional traversal capability for eagerly indexing all available tiles.
///
/// Algorithms must continue to support a plain [MapTraversalView]. This
/// capability only avoids repeated lookups when a source can expose its
/// complete borrowed tile collection without projection.
abstract interface class MapTileSource<T extends MapTileView>
    implements MapTraversalView {
  Iterable<T> get tiles;

  @override
  T? tileAt(int col, int row);
}
