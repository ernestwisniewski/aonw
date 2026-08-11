import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/transport/transport_segment.dart';

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
}
