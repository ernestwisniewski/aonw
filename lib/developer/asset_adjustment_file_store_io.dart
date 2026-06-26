import 'dart:io';

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustment_paths.dart';
import 'package:aonw/shared/persistence/app_data_directory.dart';

class AssetAdjustmentSaveResult {
  final bool saved;
  final String message;

  const AssetAdjustmentSaveResult({required this.saved, required this.message});
}

Future<AssetAdjustmentSaveResult> saveAssetAdjustmentsJson(String json) async {
  final file = await _localAdjustmentsFile();
  await file.parent.create(recursive: true);
  await file.writeAsString('$json\n');
  return AssetAdjustmentSaveResult(
    saved: true,
    message: 'Saved with maps and saves: ${file.path}',
  );
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
