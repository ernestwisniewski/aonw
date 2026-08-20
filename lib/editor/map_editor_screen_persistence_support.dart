part of 'map_editor_screen.dart';

extension _MapEditorScreenPersistenceSupport on _MapEditorScreenState {
  Future<MapImageSource> _saveMapImage({
    required String sourcePath,
    required String mapName,
    required MapDraft draft,
    required bool sliceImage,
  }) async {
    if (sliceImage) {
      final firstSlicePath = await MapSaver.saveImageSlices(
        sourcePath: sourcePath,
        mapName: mapName,
        cols: draft.cols,
        rows: draft.rows,
        config: MapConfig.defaultConfig,
      );
      final directoryPath = firstSlicePath.replaceFirst(
        RegExp(r'[/\\][^/\\]+$'),
        '',
      );
      return SavedMapSliceSetSource(directoryPath);
    }
    final path = await MapSaver.saveImageCopy(
      sourcePath: sourcePath,
      mapName: mapName,
    );
    return SavedMapSingleImageSource(path);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
