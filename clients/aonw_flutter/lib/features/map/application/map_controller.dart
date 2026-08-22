import 'package:flutter/foundation.dart';

import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import 'map_interaction_state.dart';
import 'map_repository.dart';

sealed class MapScreenState {
  const MapScreenState();
}

final class MapLoadingState extends MapScreenState {
  const MapLoadingState();
}

final class MapReadyState extends MapScreenState {
  const MapReadyState({required this.scene, required this.interaction});

  final MapScene scene;
  final MapInteractionState interaction;

  MapReadyState withInteraction(MapInteractionState value) =>
      MapReadyState(scene: scene, interaction: value);
}

final class MapFailureState extends MapScreenState {
  const MapFailureState({required this.code, required this.message});

  final String code;
  final String message;
}

final class MapController extends ChangeNotifier {
  MapController({
    required MapRepository repository,
    this.assets = MapAssetPaths.starter,
  }) : _repository = repository;

  final MapRepository _repository;
  final MapAssetPaths assets;
  MapScreenState _state = const MapLoadingState();
  var _disposed = false;

  MapScreenState get state => _state;

  Future<void> load() async {
    _setState(const MapLoadingState());
    try {
      final scene = await _repository.load(assets);
      _setState(
        MapReadyState(scene: scene, interaction: const MapInteractionState()),
      );
    } on MapLoadException catch (error) {
      _setState(MapFailureState(code: error.code, message: error.message));
    } on Object {
      _setState(
        const MapFailureState(
          code: 'unexpected_map_failure',
          message: 'The map could not be loaded.',
        ),
      );
    }
  }

  void hover(MapHexCoordinate? coordinate) {
    final current = _state;
    if (current is! MapReadyState) return;
    final next = coordinate != null && current.scene.map.contains(coordinate)
        ? coordinate
        : null;
    if (next == current.interaction.hovered) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(hovered: next, clearHovered: next == null),
      ),
    );
  }

  void select(MapHexCoordinate? coordinate) {
    final current = _state;
    if (current is! MapReadyState) return;
    final next = coordinate != null && current.scene.map.contains(coordinate)
        ? coordinate
        : null;
    if (next == current.interaction.selected) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: next,
          clearSelected: next == null,
        ),
      ),
    );
  }

  void toggleReference() {
    final current = _state;
    if (current is! MapReadyState) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          referenceVisible: !current.interaction.referenceVisible,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setState(MapScreenState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }
}
