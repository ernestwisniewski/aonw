import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';

/// Immutable snapshot of an active game session.
///
/// [viewMode] is the current rendering mode.
/// [imagePath] is the optional reference image path (null = no image).
/// [saveId] is the persistent save slot identifier.
/// [gameMode] is fixed when the save is created.
class GameSession {
  final MapData mapData;
  final MapViewMode viewMode;
  final CameraState? initialCamera;
  final GameMode gameMode;

  /// Optional reference image path. Immutable for the lifetime of the session.
  final String? imagePath;

  /// Persistent save slot identifier.
  final String saveId;

  const GameSession({
    required this.mapData,
    required this.viewMode,
    required this.saveId,
    this.gameMode = GameMode.hotSeat,
    this.imagePath,
    this.initialCamera,
  });

  /// Returns a copy with [viewMode] updated. [imagePath] and [saveId] are immutable.
  GameSession copyWith({MapViewMode? viewMode}) => GameSession(
    mapData: mapData,
    viewMode: viewMode ?? this.viewMode,
    gameMode: gameMode,
    imagePath: imagePath,
    saveId: saveId,
    initialCamera: initialCamera,
  );
}
