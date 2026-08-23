import 'package:flutter/services.dart';

import '../../features/map/application/map_controller.dart';
import '../../features/map/application/map_repository.dart';
import '../../features/map/infrastructure/gamepad_map_input_source.dart';
import '../../features/map/infrastructure/rust_map_repository.dart';
import '../../features/map/presentation/input/map_input.dart';
import '../navigation/aonw_app.dart';

final class AppComposition {
  AppComposition({
    required MapRepository mapRepository,
    MapInputSource? mapInputSource,
  }) : root = AonwApp(
         mapController: MapController(repository: mapRepository),
         mapInputSource: mapInputSource,
       );

  factory AppComposition.production() => AppComposition(
    mapRepository: RustMapRepository(assets: rootBundle),
    mapInputSource: GamepadMapInputSource(),
  );

  final AonwApp root;
}
