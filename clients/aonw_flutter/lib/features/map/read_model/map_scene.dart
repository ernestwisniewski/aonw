import 'map_reference_bundle.dart';
import 'map_view.dart';

final class MapScene {
  const MapScene({required this.map, required this.reference});

  final MapView map;
  final MapReferenceBundle reference;
}
