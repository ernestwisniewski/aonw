part of 'map_editor_screen.dart';

extension _MapEditorScreenPersistenceSupport on _MapEditorScreenState {
  Future<String> _saveMapImage({
    required String sourcePath,
    required String mapName,
    required MapDraft draft,
    required bool sliceImage,
  }) {
    if (sliceImage) {
      return MapSaver.saveImageSlices(
        sourcePath: sourcePath,
        mapName: mapName,
        cols: draft.cols,
        rows: draft.rows,
        config: MapConfig.defaultConfig,
      );
    }
    return MapSaver.saveImageCopy(sourcePath: sourcePath, mapName: mapName);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isSlicedImagePath(String? path) {
    if (path == null) return false;
    return RegExp(r'(^|[\\/])1x1\.png$').hasMatch(path);
  }
}
