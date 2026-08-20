import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/transport/transport_segment.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';

/// Request-scoped O(1) spatial lookup used by pathfinding and rendering.
final class TransportNetworkIndex {
  TransportNetworkIndex(TransportNetworkState network)
    : segmentsByHex = network.byHex;

  final Map<HexCoord, TransportSegment> segmentsByHex;

  TransportSegment? at(int col, int row) =>
      segmentsByHex[HexCoord(col: col, row: row)];

  bool hasOperationalRoadAt(int col, int row) {
    final segment = at(col, row);
    return segment?.kind == TransportSegmentKind.road &&
        segment?.isOperational == true;
  }

  bool hasOperationalRoadEdge({
    required int fromCol,
    required int fromRow,
    required int toCol,
    required int toRow,
    required Set<HexCoordinate> cityCenters,
  }) {
    if (!HexGridTopology.areNeighbors(
      col: fromCol,
      row: fromRow,
      targetCol: toCol,
      targetRow: toRow,
    )) {
      return false;
    }
    final fromRoad = hasOperationalRoadAt(fromCol, fromRow);
    final toRoad = hasOperationalRoadAt(toCol, toRow);
    if (fromRoad && toRoad) return true;
    final fromCity = cityCenters.contains(
      HexCoordinate(col: fromCol, row: fromRow),
    );
    final toCity = cityCenters.contains(HexCoordinate(col: toCol, row: toRow));
    return (fromCity && toRoad) || (fromRoad && toCity);
  }
}
