import 'package:flutter/services.dart';

import '../../features/map/application/map_controller.dart';
import '../../features/map/infrastructure/rust_map_repository.dart';
import '../navigation/aonw_app.dart';

final class AppComposition {
  const AppComposition();

  AonwApp build() => AonwApp(
    mapController: MapController(
      repository: RustMapRepository(assets: rootBundle),
    ),
  );
}
