import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';

/// Immutable snapshot of an active game session.
///
/// [viewMode] is the current rendering mode.
/// [imageSource] is the optional typed reference image (null = no image).
/// [saveId] is the persistent save slot identifier.
/// [gameMode] is fixed when the save is created.
class GameSession {
  final WorldMap mapData;
  final MapViewMode viewMode;
  final CameraState? initialCamera;
  final GameMode gameMode;

  /// Optional reference image. Immutable for the lifetime of the session.
  final MapImageSource? imageSource;

  /// Persistent save slot identifier.
  final String saveId;

  const GameSession({
    required this.mapData,
    required this.viewMode,
    required this.saveId,
    this.gameMode = GameMode.hotSeat,
    this.imageSource,
    this.initialCamera,
  });

  /// Returns a copy with [viewMode] updated.
  GameSession copyWith({MapViewMode? viewMode}) => GameSession(
    mapData: mapData,
    viewMode: viewMode ?? this.viewMode,
    gameMode: gameMode,
    imageSource: imageSource,
    saveId: saveId,
    initialCamera: initialCamera,
  );
}
