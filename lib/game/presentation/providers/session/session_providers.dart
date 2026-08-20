import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/services/game_session_factory.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_providers.g.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;

@Riverpod(retry: _doNotRetry)
class GameSessionNotifier extends _$GameSessionNotifier {
  @override
  Future<GameSession> build(MapSelection selection, String saveId) async {
    final sessionFactory = ref.watch(gameSessionFactoryProvider);
    final baseMap = await ref.watch(activeMapProvider(selection).future);
    final snapshot = await ref.read(gameSaveSnapshotProvider(saveId).future);
    final mapData =
        snapshot?.domain.initialResourceDistribution.applyTo(baseMap) ??
        baseMap;
    final imageSource = await ref.watch(
      mapImageSourceProvider(selection).future,
    );
    // One-shot reads: save/camera invalidation should refresh HUD metadata
    // without recreating the active Flame session.
    final initialCamera = snapshot?.save.camera;
    final save = snapshot?.save;
    await ref.read(gameplaySettingsProvider.notifier).ensureLoaded();
    final preferredViewMode = ref
        .read(gameplaySettingsProvider)
        .preferredMapViewMode;
    return sessionFactory.create(
      mapData: mapData,
      imageSource: imageSource,
      saveId: saveId,
      initialCamera: initialCamera,
      gameMode: save?.gameMode ?? GameMode.hotSeat,
      preferredViewMode: preferredViewMode,
    );
  }

  /// Updates [viewMode] in the session snapshot.
  /// The game screen is responsible for applying the mode to [GameRenderer].
  /// No-op if state is not AsyncData.
  void setViewMode(MapViewMode mode) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(viewMode: mode));
  }
}

@riverpod
GameSessionFactory gameSessionFactory(Ref ref) {
  return const GameSessionFactory();
}

@Riverpod(retry: _doNotRetry)
Future<List<GameSaveIndex>> gameSavesIndex(Ref ref) {
  return ref.watch(gameRepositoryProvider).list();
}

/// Holds the currently active [GameSession] inside a game screen scope.
///
/// Defaults to null outside a running game.
///
/// `dependencies: const []` marks this as a *scoped* provider: overrides via
/// `ProviderScope(overrides: [...])` only propagate to descendants when both
/// the scoped provider and every consumer that reads it declare `dependencies`.
/// See https://riverpod.dev/docs/concepts/scopes
@Riverpod(dependencies: [])
GameSession? activeGameSession(Ref ref) => null;

/// Loads the saved camera state for a save slot.
///
/// Empty save ids do not have persisted camera metadata. Repository errors are
/// surfaced by [gameSaveSnapshotProvider] as AsyncError.
@riverpod
Future<CameraState?> savedCamera(Ref ref, String saveId) async {
  final snapshot = await ref.watch(gameSaveSnapshotProvider(saveId).future);
  return snapshot?.save.camera;
}

@Riverpod(retry: _doNotRetry)
Future<CanonicalGameSnapshot?> gameSaveSnapshot(Ref ref, String saveId) async {
  if (saveId.isEmpty) return null;
  return gameRepositoryForSave(ref, saveId).load(saveId);
}

/// Loads the full game save for a save slot.
///
/// Empty save ids return null. Repository errors stay visible as AsyncError.
@riverpod
Future<GameSave?> gameSave(Ref ref, String saveId) async {
  final snapshot = await ref.watch(gameSaveSnapshotProvider(saveId).future);
  return snapshot?.save;
}
