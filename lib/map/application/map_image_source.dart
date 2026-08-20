/// Explicit description of a map's optional visual layer.
///
/// Runtime code switches on the source type. It never infers storage or
/// rendering behaviour from a filename.
sealed class MapImageSource {
  const MapImageSource();
}

/// A generated, paged texture set shipped in the Flutter asset bundle.
final class BundledMapTextureSource extends MapImageSource {
  const BundledMapTextureSource(this.manifestAssetPath)
    : assert(manifestAssetPath != '');

  final String manifestAssetPath;

  @override
  bool operator ==(Object other) =>
      other is BundledMapTextureSource &&
      other.manifestAssetPath == manifestAssetPath;

  @override
  int get hashCode => manifestAssetPath.hashCode;
}

/// A raster image stored outside the application bundle.
sealed class SavedMapImageSource extends MapImageSource {
  const SavedMapImageSource();
}

/// One raster image stretched across the map's world bounds.
final class SavedMapSingleImageSource extends SavedMapImageSource {
  const SavedMapSingleImageSource(this.filePath) : assert(filePath != '');

  final String filePath;

  @override
  bool operator ==(Object other) =>
      other is SavedMapSingleImageSource && other.filePath == filePath;

  @override
  int get hashCode => filePath.hashCode;
}

/// A directory containing `{column}x{row}.jpg` saved-map tiles.
final class SavedMapSliceSetSource extends SavedMapImageSource {
  const SavedMapSliceSetSource(this.directoryPath)
    : assert(directoryPath != '');

  final String directoryPath;

  String slicePath(int col, int row) =>
      '$directoryPath/${col + 1}x${row + 1}.jpg';

  @override
  bool operator ==(Object other) =>
      other is SavedMapSliceSetSource && other.directoryPath == directoryPath;

  @override
  int get hashCode => directoryPath.hashCode;
}
