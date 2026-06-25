import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw/map/persistence/map_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const int _jpegQuality = 90;

abstract final class MapSaver {
  /// Normalizes a user-facing name to a filesystem-safe ASCII stem.
  static String sanitizeMapName(String rawName) =>
      MapStorage.sanitizeMapName(rawName);

  /// Saves [mapData] to `<documents>/maps/<mapData.mapName>/map.json`.
  /// Creates the directory if needed.
  /// Throws [ArgumentError] if `mapData.mapName` is null or empty.
  static Future<void> save(MapData mapData) async {
    final rawName = mapData.mapName;
    if (rawName == null || rawName.trim().isEmpty) {
      throw ArgumentError('mapData.mapName must be set before saving');
    }
    final safeName = MapStorage.sanitizeMapName(rawName);
    mapData.mapName = safeName;
    final file = await MapStorage.jsonFile(safeName);
    await file.parent.create(recursive: true);
    await file.writeAsString(MapLoader.toJson(mapData));
  }

  /// Opens the gallery picker and returns the picked image path.
  /// Returns null if the user cancelled.
  static Future<String?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked?.path;
  }

  /// Re-encodes [sourcePath] as JPEG q=$_jpegQuality and writes it to
  /// `<documents>/maps/<mapName>/image.jpg`. Accepts PNG or JPEG input.
  static Future<String> saveImageCopy({
    required String sourcePath,
    required String mapName,
  }) async {
    final safeName = MapStorage.sanitizeMapName(mapName);
    final file = await MapStorage.imageFile(safeName);
    await file.parent.create(recursive: true);
    await _deleteExistingSliceFiles(safeName);
    if (sourcePath == file.path) return file.path;
    if (await file.exists()) await file.delete();
    final sourceBytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw StateError('Could not decode image at $sourcePath');
    }
    final jpegBytes = img.encodeJpg(decoded, quality: _jpegQuality);
    await file.writeAsBytes(jpegBytes, flush: true);
    return file.path;
  }

  /// Slices [sourcePath] into per-tile images and saves them as
  /// `<documents>/maps/<mapName>/{col+1}x{row+1}.jpg` (JPEG q=$_jpegQuality).
  ///
  /// The source image is assumed to cover the full hex grid bounding box.
  /// Each tile gets a rectangular crop proportional to its grid position.
  ///
  /// Returns the path of the first slice (1x1.jpg) so the caller can confirm.
  static Future<String> saveImageSlices({
    required String sourcePath,
    required String mapName,
    required int cols,
    required int rows,
    required MapConfig config,
  }) async {
    final safeName = MapStorage.sanitizeMapName(mapName);
    final dir = await MapStorage.mapDirectory(safeName);
    await dir.create(recursive: true);

    // Keep replacements safe when sourcePath already points inside the map dir.
    final bytes = await File(sourcePath).readAsBytes();

    final singleImg = await MapStorage.imageFile(safeName);
    if (await singleImg.exists()) await singleImg.delete();
    await _deleteExistingSliceFiles(safeName);

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;
    try {
      final imgW = srcImage.width.toDouble();
      final imgH = srcImage.height.toDouble();

      final r = config.hexRadius;
      final gridW = r + (cols - 1) * 1.5 * r + r;
      final lastColIsOdd = (cols - 1).isOdd;
      final gridH =
          (math.sqrt(3) / 2 * r) +
          (rows - 1) * math.sqrt(3) * r +
          (lastColIsOdd ? math.sqrt(3) / 2 * r : 0) +
          (math.sqrt(3) / 2 * r);

      String? firstSlicePath;

      for (int col = 0; col < cols; col++) {
        for (int row = 0; row < rows; row++) {
          final cx = r + col * 1.5 * r;
          final cy =
              (math.sqrt(3) / 2 * r) +
              row * math.sqrt(3) * r +
              (col.isOdd ? math.sqrt(3) / 2 * r : 0);
          final tileH = math.sqrt(3) * r;
          final scaleX = imgW / gridW;
          final scaleY = imgH / gridH;

          final srcLeft = ((cx - r) * scaleX).clamp(0.0, imgW);
          final srcTop = ((cy - tileH / 2) * scaleY).clamp(0.0, imgH);
          final srcRight = ((cx + r) * scaleX).clamp(0.0, imgW);
          final srcBottom = ((cy + tileH / 2) * scaleY).clamp(0.0, imgH);
          final srcWidth = srcRight - srcLeft;
          final srcHeight = srcBottom - srcTop;

          final cropW = srcWidth.round();
          final cropH = srcHeight.round();
          if (cropW <= 0 || cropH <= 0) continue;

          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder).drawImageRect(
            srcImage,
            ui.Rect.fromLTWH(srcLeft, srcTop, srcWidth, srcHeight),
            ui.Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
            ui.Paint(),
          );
          final picture = recorder.endRecording();
          final cropped = await picture.toImage(cropW, cropH);
          final rawRgba = await cropped.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          cropped.dispose();
          picture.dispose();
          if (rawRgba == null) continue;

          final rgbaImage = img.Image.fromBytes(
            width: cropW,
            height: cropH,
            bytes: rawRgba.buffer,
            numChannels: 4,
            order: img.ChannelOrder.rgba,
          );
          final jpegBytes = img.encodeJpg(rgbaImage, quality: _jpegQuality);

          final sliceFile = await MapStorage.sliceFile(safeName, col, row);
          await sliceFile.writeAsBytes(jpegBytes, flush: true);
          firstSlicePath ??= sliceFile.path;
        }
      }

      return firstSlicePath ??
          (await MapStorage.sliceFile(safeName, 0, 0)).path;
    } finally {
      srcImage.dispose();
      codec.dispose();
    }
  }

  /// Resolves the image path for [mapName]:
  /// 1. `<documents>/maps/<mapName>/1x1.jpg` — sliced tile marker
  /// 2. `<documents>/maps/<mapName>/image.jpg` — single image
  /// 3. `assets/maps/<mapName>/...` — bundled asset
  /// 4. Returns null if neither exists
  static Future<String?> resolveImagePath(String mapName) =>
      MapStorage.resolveImagePath(mapName);

  static Future<void> _deleteExistingSliceFiles(String mapName) async {
    final dir = await MapStorage.mapDirectory(mapName);
    if (!await dir.exists()) return;
    final slicePattern = RegExp(r'^\d+x\d+\.jpg$');
    await for (final entity in dir.list()) {
      if (entity is File &&
          slicePattern.hasMatch(entity.uri.pathSegments.last)) {
        await entity.delete();
      }
    }
  }
}
