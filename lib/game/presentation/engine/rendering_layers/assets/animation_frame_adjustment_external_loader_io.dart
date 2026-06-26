import 'dart:io';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment_paths.dart';
import 'package:aonw/shared/persistence/app_data_directory.dart';

Future<String?> loadExternalAnimationFrameAdjustmentsJson() async {
  if (_runningUnderFlutterTest) return null;
  final file = await _localAdjustmentsFile();
  if (!await file.exists()) return null;
  return file.readAsString();
}

bool get _runningUnderFlutterTest {
  return Platform.environment['FLUTTER_TEST'] == 'true' ||
      Platform.resolvedExecutable.contains('flutter_tester');
}

Future<File> _localAdjustmentsFile() async {
  final root = await AppDataDirectory.documentsDirectory();
  return File(
    [
      root.path,
      AnimationFrameAdjustmentPaths.localFileName,
    ].join(Platform.pathSeparator),
  );
}
