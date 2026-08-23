import 'package:flutter/services.dart';

import '../../features/map/application/map_controller.dart';
import '../../features/map/application/map_repository.dart';
import '../../features/map/infrastructure/rust_map_repository.dart';
import '../navigation/aonw_app.dart';

final class AppComposition {
  AppComposition({required MapRepository mapRepository})
    : root = AonwApp(mapController: MapController(repository: mapRepository));

  factory AppComposition.production() =>
      AppComposition(mapRepository: RustMapRepository(assets: rootBundle));

  final AonwApp root;
}
